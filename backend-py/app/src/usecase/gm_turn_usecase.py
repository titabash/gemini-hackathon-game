"""GM turn processing pipeline.

Orchestrates the full turn lifecycle: validate session, build context,
get GM decision via Gemini, apply state mutations, persist the turn
record, and stream the result as SSE events.
"""

from __future__ import annotations

import asyncio
import json
import uuid
from datetime import UTC, datetime
from typing import TYPE_CHECKING

from domain.entity.models import SceneBackgrounds, Turns
from domain.service.context_service import ContextService
from domain.service.genui_bridge_service import GenuiBridgeService
from domain.service.gm_decision_service import GmDecisionService
from domain.service.state_mutation_service import StateMutationService
from gateway.context_summary_gateway import ContextSummaryGateway
from gateway.npc_gateway import NpcGateway
from gateway.scene_background_gateway import SceneBackgroundGateway
from gateway.session_gateway import SessionGateway
from gateway.turn_gateway import TurnGateway
from infra.gemini_client import GeminiClient
from infra.storage_service import StorageService
from util.logging import get_logger

if TYPE_CHECKING:
    from collections.abc import AsyncIterator

    from sqlmodel import Session

    from domain.entity.gm_types import GmDecisionResponse, GmTurnRequest

logger = get_logger(__name__)

_SCENARIO_ASSETS_BUCKET = "scenario-assets"


class GmTurnUseCase:
    """Processes a single player turn through the GM pipeline."""

    def __init__(self) -> None:
        self.gemini = GeminiClient()
        self.session_gw = SessionGateway()
        self.turn_gw = TurnGateway()
        self.context_gw = ContextSummaryGateway()
        self.context_svc = ContextService()
        self.decision_svc = GmDecisionService(self.gemini)
        self.mutation_svc = StateMutationService()
        self.bridge_svc = GenuiBridgeService()
        self.storage_svc = StorageService()
        self.bg_gw = SceneBackgroundGateway()
        self.npc_gw = NpcGateway()

    async def execute(
        self,
        request: GmTurnRequest,
        db: Session,
    ) -> AsyncIterator[str]:
        """Run the full turn pipeline and yield SSE events."""
        session_id = uuid.UUID(request.session_id)
        game_session = self.session_gw.get_by_id(db, session_id)

        if not game_session or game_session.status != "active":
            yield _error_event("Session not active")
            return

        # Build context and get GM decision
        context = self.context_svc.build_context(db, session_id)
        prompt = self.context_svc.build_prompt(
            context,
            request.input_type,
            request.input_text,
        )
        decision = await self.decision_svc.decide(prompt)

        # Apply state mutations
        if decision.state_changes:
            self.mutation_svc.apply(db, session_id, decision.state_changes)

        # Persist turn
        self._persist_turn(request, decision, db, game_session)

        # Context compression check
        ctx_rec = self.context_gw.get_by_session(db, session_id)
        last_updated = ctx_rec.last_updated_turn if ctx_rec else 0
        if self.context_svc.should_compress(
            context.current_turn_number,
            last_updated,
        ):
            try:
                await self.context_svc.compress(
                    db,
                    session_id,
                    self.gemini,
                    context.current_turn_number,
                )
            except Exception:
                logger.warning(
                    "Context compression failed, will retry next turn",
                    session_id=str(session_id),
                )

        # Build NPC name → image_path map from DB
        active_npcs = self.npc_gw.get_active_by_session(db, session_id)
        npc_images = {npc.name: npc.image_path for npc in active_npcs if npc.image_path}
        # Fallback to scenario-level NPCs for image paths
        if not npc_images:
            scenario_npcs = self.npc_gw.get_by_scenario(
                db,
                game_session.scenario_id,
            )
            npc_images = {
                npc.name: npc.image_path for npc in scenario_npcs if npc.image_path
            }

        # Stream SSE events via bridge (text, state, surface, done)
        async for event in self.bridge_svc.stream_decision(
            decision,
            npc_images=npc_images,
        ):
            yield event

        # Resolve background image: ID-based lookup first, then generate
        image_ref = self._resolve_background_image(db, decision)
        if image_ref:
            yield _image_event(image_ref)
        elif decision.scene_description:
            gen_ref = await self._generate_and_upload_image(
                db,
                session_id,
                decision.scene_description,
            )
            if gen_ref:
                yield _image_event(gen_ref)

    def _resolve_background_image(
        self,
        db: Session,
        decision: GmDecisionResponse,
    ) -> str | None:
        """Look up background by LLM-selected ID."""
        if not decision.selected_background_id:
            return None

        try:
            bg_id = uuid.UUID(decision.selected_background_id)
        except ValueError:
            logger.warning(
                "Invalid background ID from LLM",
                selected_id=decision.selected_background_id,
            )
            return None

        bg = self.bg_gw.find_by_id(db, bg_id)
        if not bg or not bg.image_path:
            logger.warning(
                "Background not found or missing image_path",
                selected_id=decision.selected_background_id,
            )
            return None

        bucket = _SCENARIO_ASSETS_BUCKET if bg.scenario_id else "generated-images"
        logger.info(
            "Using LLM-selected background",
            bg_id=str(bg_id),
            location=bg.location_name,
            path=bg.image_path,
        )
        return f"{bucket}/{bg.image_path}"

    def _persist_turn(
        self,
        request: GmTurnRequest,
        decision: GmDecisionResponse,
        db: Session,
        game_session: object,
    ) -> None:
        """Increment turn counter and save the turn record."""
        sid = game_session.id  # type: ignore[attr-defined]
        new_turn_number = self.session_gw.increment_turn(db, sid)
        turn = Turns(
            id=uuid.uuid4(),
            session_id=sid,
            turn_number=new_turn_number,
            input_type=request.input_type,
            input_text=request.input_text,
            gm_decision_type=decision.decision_type,
            output=decision.model_dump(),
            created_at=datetime.now(UTC),
        )
        self.turn_gw.create(db, turn)

    async def _generate_and_upload_image(
        self,
        db: Session,
        session_id: uuid.UUID,
        description: str,
    ) -> str | None:
        """Generate scene image, upload, and cache in scene_backgrounds."""
        try:
            image_bytes = await self.gemini.generate_image(
                f"Fantasy RPG scene: {description}",
            )
            if not image_bytes:
                return None

            storage_path = await asyncio.to_thread(
                self.storage_svc.upload_image,
                str(session_id),
                image_bytes,
            )

            # Cache the generated background for reuse
            location_name = description[:100]
            self.bg_gw.create(
                db,
                SceneBackgrounds(
                    id=uuid.uuid4(),
                    session_id=session_id,
                    location_name=location_name,
                    image_path=storage_path,
                    description=description,
                    created_at=datetime.now(UTC),
                ),
            )

            return f"generated-images/{storage_path}"
        except Exception:
            logger.warning(
                "Scene image generation/upload failed",
                description=description,
            )
            return None


def _error_event(message: str) -> str:
    """Build an SSE error event string."""
    payload = json.dumps(
        {"type": "error", "content": message},
        ensure_ascii=False,
    )
    return f"data: {payload}\n\n"


def _image_event(path: str) -> str:
    """Build an SSE imageUpdate event string.

    ``path`` is ``{bucket}/{object_path}`` so the frontend can call
    ``supabase.storage.from(bucket).getPublicUrl(objectPath)``.
    """
    payload = json.dumps(
        {"type": "imageUpdate", "path": path},
        ensure_ascii=False,
    )
    return f"data: {payload}\n\n"
