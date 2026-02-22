"""GM turn processing pipeline.

Orchestrates the full turn lifecycle: validate session, build context,
get GM decision via Gemini, apply state mutations, evaluate win/fail
conditions, persist the turn record, and stream the result as SSE events.
"""

from __future__ import annotations

import asyncio
import json
import uuid
from datetime import UTC, datetime
from typing import TYPE_CHECKING, Any

from domain.entity.gm_types import SessionEnd
from domain.entity.models import Npcs, SceneBackgrounds, Turns
from domain.service.action_resolution_service import ActionResolutionService
from domain.service.condition_evaluation_service import (
    ConditionEvaluationResult,
    ConditionEvaluationService,
)
from domain.service.context_service import ContextService
from domain.service.genui_bridge_service import GenuiBridgeService, NpcImageMap
from domain.service.gm_decision_service import GmDecisionService
from domain.service.state_mutation_service import StateMutationService
from domain.service.storage_constants import SCENARIO_ASSETS_BUCKET
from domain.service.turn_limit_service import TurnLimitService
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

    from domain.entity.gm_types import (
        GameContext,
        GmDecisionResponse,
        GmTurnRequest,
        StateChanges,
    )

logger = get_logger(__name__)


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
        self.turn_limit_svc = TurnLimitService()
        self.condition_svc = ConditionEvaluationService()
        self.resolution_svc = ActionResolutionService()

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

        # Build context and resolve decision (with turn-limit checks)
        context = self.context_svc.build_context(db, session_id)
        decision = await self._resolve_decision(context, request)

        # Apply state mutations
        if decision.state_changes:
            self.mutation_svc.apply(db, session_id, decision.state_changes)

        # Condition evaluation (after mutation, only if LLM didn't end)
        llm_ended = _has_session_end(decision.state_changes)
        if not llm_ended:
            self._evaluate_and_apply(db, session_id, context, decision)

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

        npc_images = self._resolve_npc_images(
            db,
            session_id,
            game_session.scenario_id,
            decision,
        )

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

    async def _resolve_decision(
        self,
        context: GameContext,
        request: GmTurnRequest,
    ) -> GmDecisionResponse:
        """Check turn limits and return the appropriate decision."""
        cur = context.current_turn_number
        mx = context.max_turns
        if self.turn_limit_svc.is_hard_limit_reached(cur, mx):
            return self.turn_limit_svc.build_hard_limit_response(mx)

        luck = self.resolution_svc.generate_luck_factor()
        resolution_ctx = self.resolution_svc.build_resolution_context(
            player_stats=dict(context.player.stats),
            luck_factor=luck,
        )
        prompt = self.context_svc.build_prompt(
            context,
            request.input_type,
            request.input_text,
            extra_sections=[
                self._build_soft_addition(context),
                self._build_condition_progress(context),
                resolution_ctx,
            ],
        )
        return await self.decision_svc.decide(prompt)

    def _build_soft_addition(self, context: GameContext) -> str:
        """Return soft-limit prompt addition or empty string."""
        cur = context.current_turn_number
        mx = context.max_turns
        if not self.turn_limit_svc.is_soft_limit_active(cur, mx):
            return ""
        remaining = self.turn_limit_svc.remaining_turns(cur, mx)
        return str(
            self.turn_limit_svc.build_soft_limit_prompt_addition(
                remaining,
            ),
        )

    def _build_condition_progress(self, context: GameContext) -> str:
        """Build condition progress prompt text."""
        flags = dict(context.current_state.get("flags", {}))
        result = self.condition_svc.evaluate(
            win_conditions=context.win_conditions,
            fail_conditions=context.fail_conditions,
            current_flags=flags,
            player_stats=dict(context.player.stats),
            current_turn=context.current_turn_number,
        )
        return str(self.condition_svc.build_progress_prompt(result))

    def _evaluate_and_apply(
        self,
        db: Session,
        session_id: uuid.UUID,
        context: GameContext,
        decision: GmDecisionResponse,
    ) -> None:
        """Evaluate conditions and apply session end if triggered."""
        flags = _compute_latest_flags(context, decision.state_changes)
        stats = _compute_latest_stats(context, decision.state_changes)
        result = self.condition_svc.evaluate(
            win_conditions=context.win_conditions,
            fail_conditions=context.fail_conditions,
            current_flags=flags,
            player_stats=stats,
            current_turn=context.current_turn_number,
        )
        self._apply_condition_end(db, session_id, result)

    def _apply_condition_end(
        self,
        db: Session,
        session_id: uuid.UUID,
        result: ConditionEvaluationResult,
    ) -> None:
        """Apply session end based on condition evaluation result."""
        if result.triggered_fail:
            desc = str(result.triggered_fail.get("description", ""))
            self.mutation_svc.apply_session_end(
                db,
                session_id,
                SessionEnd(
                    ending_type="bad_end",
                    ending_summary=desc,
                ),
            )
        elif result.triggered_win:
            desc = str(result.triggered_win.get("description", ""))
            self.mutation_svc.apply_session_end(
                db,
                session_id,
                SessionEnd(
                    ending_type="victory",
                    ending_summary=desc,
                ),
            )

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

        bucket = SCENARIO_ASSETS_BUCKET if bg.scenario_id else "generated-images"
        logger.info(
            "Using LLM-selected background",
            bg_id=str(bg_id),
            location=bg.location_name,
            path=bg.image_path,
        )
        return f"{bucket}/{bg.image_path}"

    def _resolve_npc_images(
        self,
        db: Session,
        session_id: uuid.UUID,
        scenario_id: object,
        decision: GmDecisionResponse,
    ) -> NpcImageMap:
        """Build NPC name -> (default_path, emotion_map) and log each NPC."""
        npc_images = _build_npc_image_entries(
            self.npc_gw.get_active_by_session(db, session_id),
        )
        if not npc_images:
            npc_images = _build_npc_image_entries(
                self.npc_gw.get_by_scenario(db, scenario_id),
            )

        seen: set[str] = set()
        for dialogue in decision.npc_dialogues or []:
            seen.add(dialogue.npc_name)
            entry = npc_images.get(dialogue.npc_name)
            path = entry[0] if entry else None
            logger.info(
                "Using LLM-selected NPC",
                npc_name=dialogue.npc_name,
                source="dialogue",
                image_path=path,
                resolved=path is not None,
            )
        for intent in decision.npc_intents or []:
            if intent.npc_name not in seen:
                entry = npc_images.get(intent.npc_name)
                path = entry[0] if entry else None
                logger.info(
                    "Using LLM-selected NPC",
                    npc_name=intent.npc_name,
                    source="intent",
                    image_path=path,
                    resolved=path is not None,
                )
        return npc_images

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


# ---------------------------------------------------------------------------
# Module-level helpers
# ---------------------------------------------------------------------------


def _has_session_end(changes: StateChanges | None) -> bool:
    """Check if state_changes includes a session_end."""
    return changes is not None and changes.session_end is not None


def _compute_latest_flags(
    context: GameContext,
    changes: StateChanges | None,
) -> dict[str, bool]:
    """Compute latest flags from context + decision without DB re-read."""
    flags: dict[str, bool] = dict(context.current_state.get("flags", {}))
    if changes and changes.flag_changes:
        for fc in changes.flag_changes:
            if fc.value:
                flags[fc.flag_id] = True
            else:
                flags.pop(fc.flag_id, None)
    return flags


def _compute_latest_stats(
    context: GameContext,
    changes: StateChanges | None,
) -> dict[str, Any]:
    """Compute latest stats from context + decision without DB re-read."""
    stats: dict[str, Any] = dict(context.player.stats)
    if changes and changes.hp_delta is not None:
        stats["hp"] = stats.get("hp", 100) + changes.hp_delta
    return stats


def _build_npc_image_entries(npcs: list[Npcs]) -> NpcImageMap:
    """Extract (default_path, emotion_map) for each NPC with an image."""
    result: NpcImageMap = {}
    for npc in npcs:
        if not npc.image_path:
            continue
        emotion_map: dict[str, str] = {}
        raw = getattr(npc, "emotion_images", None)
        if raw and isinstance(raw, dict):
            emotion_map = {k: v for k, v in raw.items() if isinstance(v, str) and v}
        result[npc.name] = (npc.image_path, emotion_map)
    return result


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
