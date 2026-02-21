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

from domain.entity.models import Turns
from domain.service.context_service import ContextService
from domain.service.genui_bridge_service import GenuiBridgeService
from domain.service.gm_decision_service import GmDecisionService
from domain.service.state_mutation_service import StateMutationService
from gateway.context_summary_gateway import ContextSummaryGateway
from gateway.session_gateway import SessionGateway
from gateway.turn_gateway import TurnGateway
from infra.gemini_client import GeminiClient
from util.logging import get_logger

if TYPE_CHECKING:
    from collections.abc import AsyncIterator

    from sqlmodel import Session

    from domain.entity.gm_types import GmDecisionResponse, GmTurnRequest

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

        # Stream SSE events via bridge
        async for event in self.bridge_svc.stream_decision(decision):
            yield event

        # Background image generation
        if decision.scene_description:
            self._bg_task = asyncio.create_task(
                self._generate_image(decision.scene_description),
            )

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

    async def _generate_image(self, description: str) -> None:
        """Non-blocking scene image generation."""
        try:
            await self.gemini.generate_image(
                f"Fantasy RPG scene: {description}",
            )
        except Exception:
            logger.warning(
                "Scene image generation failed",
                description=description,
            )


def _error_event(message: str) -> str:
    """Build an SSE error event string."""
    payload = json.dumps(
        {"type": "error", "content": message},
        ensure_ascii=False,
    )
    return f"data: {payload}\n\n"
