"""PostgreSQL-backed ADK MemoryService for GM narrative memory.

BaseMemoryService を継承し、context_summary テーブルを長期記憶のストアとして使用する。
user_id = ゲームセッション UUID (str) でメモリをスコープする。

compress() / should_compress() の責務を ContextService から移管し、
ADK の設計パターンに準拠させる。

VertexAiMemoryBankService への将来的な差し替えも
Runner(memory_service=...) の1行変更で対応可能。
"""

from __future__ import annotations

import json
import uuid
from typing import TYPE_CHECKING

from google.adk.memory import BaseMemoryService
from google.adk.memory.base_memory_service import SearchMemoryResponse
from google.adk.memory.memory_entry import MemoryEntry
from google.genai import types as genai_types
from pydantic import BaseModel
from sqlmodel import Session as SQLModelSession

from domain.entity.gm_prompts import (
    COMPRESSION_CONTEXT_TEMPLATE,
    COMPRESSION_SYSTEM_PROMPT,
)
from domain.service.context_service import extract_nodes_text
from gateway.context_summary_gateway import ContextSummaryData, ContextSummaryGateway
from gateway.turn_gateway import TurnGateway
from infra.db_client import engine
from util.logging import get_logger

if TYPE_CHECKING:
    from collections.abc import Mapping, Sequence

    from google.adk.events import Event

    from infra.gemini_client import GeminiClient

logger = get_logger(__name__)

COMPRESSION_INTERVAL = 5


class _CompressionResult(BaseModel):
    """Structured output for context compression."""

    plot_essentials: dict[str, object]
    short_term_summary: str
    confirmed_facts: dict[str, object]


class GameMemoryService(BaseMemoryService):
    """PostgreSQL-backed MemoryService using context_summary table.

    user_id = ゲームセッション UUID (str) でスコープ。
    ADK の BaseMemoryService を継承することで:
    - Runner(memory_service=...) に渡せる
    - VertexAiMemoryBankService への差し替えが容易
    - ADK の設計パターンに準拠
    """

    def __init__(self, gemini: GeminiClient) -> None:
        self._gemini = gemini
        self._context_gw = ContextSummaryGateway()
        self._turn_gw = TurnGateway()

    async def add_session_to_memory(self, session: object) -> None:
        """Run forced compression when a session ends."""
        user_id = getattr(session, "user_id", None)
        if not user_id:
            return
        try:
            game_session_id = uuid.UUID(str(user_id))
        except ValueError:
            logger.warning("Invalid user_id for memory", user_id=user_id)
            return
        await self._compress(game_session_id)

    async def add_events_to_memory(
        self,
        *,
        app_name: str,
        user_id: str,
        events: Sequence[Event],
        session_id: str | None = None,
        custom_metadata: Mapping[str, object] | None = None,
    ) -> None:
        """Compress context if the compression interval has been reached."""
        try:
            game_session_id = uuid.UUID(user_id)
        except ValueError:
            logger.warning("Invalid user_id for memory", user_id=user_id)
            return
        await self._compress_if_due(game_session_id)

    async def search_memory(
        self,
        *,
        app_name: str,
        user_id: str,
        query: str,
    ) -> SearchMemoryResponse:
        """Return context_summary as MemoryEntry for PreloadMemoryTool injection."""
        try:
            game_session_id = uuid.UUID(user_id)
        except ValueError:
            return SearchMemoryResponse()

        with SQLModelSession(engine) as db:
            ctx = self._context_gw.get_by_session(db, game_session_id)

        if ctx is None:
            return SearchMemoryResponse()

        memory_text = _format_context_summary(ctx)
        return SearchMemoryResponse(
            memories=[
                MemoryEntry(
                    content=genai_types.Content(
                        parts=[genai_types.Part(text=memory_text)],
                        role="user",
                    ),
                )
            ]
        )

    async def _compress_if_due(self, game_session_id: uuid.UUID) -> None:
        """Skip compression if the interval threshold has not been reached."""
        with SQLModelSession(engine) as db:
            ctx = self._context_gw.get_by_session(db, game_session_id)
            last_updated = int(ctx.last_updated_turn) if ctx else 0
            recent = self._turn_gw.get_recent(db, game_session_id, limit=1)
            current_turn = int(recent[0].turn_number) if recent else 0

        if (current_turn - last_updated) < COMPRESSION_INTERVAL:
            return

        await self._compress(game_session_id)

    async def _compress(self, game_session_id: uuid.UUID) -> None:
        """Run Gemini compression and persist results to context_summary."""
        with SQLModelSession(engine) as db:
            ctx_rec = self._context_gw.get_by_session(db, game_session_id)
            prev_plot = json.dumps(ctx_rec.plot_essentials if ctx_rec else {})
            prev_facts = json.dumps(ctx_rec.confirmed_facts if ctx_rec else {})
            prev_summary = ctx_rec.short_term_summary if ctx_rec else ""
            turns = self._turn_gw.get_recent(db, game_session_id, limit=10)
            recent_1 = turns[:1]
            current_turn = int(recent_1[0].turn_number) if recent_1 else 0

        parts: list[str] = []
        for t in reversed(turns):
            narr = t.output.get("narration_text", "")
            nodes = extract_nodes_text(t.output)
            detail = nodes if nodes else str(narr)
            parts.append(
                f"T{t.turn_number}: [{t.input_type}] {t.input_text}"
                f" -> {t.gm_decision_type}: {detail}"
            )
        turns_text = "\n".join(parts)

        prompt = COMPRESSION_CONTEXT_TEMPLATE.format(
            previous_plot_essentials=prev_plot,
            previous_confirmed_facts=prev_facts,
            previous_short_term_summary=prev_summary,
            turns_to_compress=turns_text,
        )

        try:
            result = await self._gemini.generate_structured(
                contents=prompt,
                system_instruction=COMPRESSION_SYSTEM_PROMPT,
                response_type=_CompressionResult,
                temperature=0.3,
            )
        except Exception:
            logger.exception(
                "Context compression failed",
                session_id=str(game_session_id),
                turn=current_turn,
            )
            return

        with SQLModelSession(engine) as db:
            self._context_gw.upsert(
                db,
                game_session_id,
                ContextSummaryData(
                    plot_essentials=result.plot_essentials,
                    short_term_summary=result.short_term_summary,
                    confirmed_facts=result.confirmed_facts,
                    last_updated_turn=current_turn,
                ),
            )

        logger.info(
            "Context compressed",
            session_id=str(game_session_id),
            turn=current_turn,
        )


def _format_context_summary(ctx: object) -> str:
    """Format context_summary fields as a plain-text string for search_memory."""
    lines: list[str] = []
    plot = getattr(ctx, "plot_essentials", {})
    if plot:
        lines.append(f"# Plot Essentials\n{json.dumps(plot, ensure_ascii=False)}")
    summary = getattr(ctx, "short_term_summary", "")
    if summary:
        lines.append(f"# Story So Far\n{summary}")
    facts = getattr(ctx, "confirmed_facts", {})
    if facts:
        lines.append(f"# Confirmed Facts\n{json.dumps(facts, ensure_ascii=False)}")
    return "\n\n".join(lines)
