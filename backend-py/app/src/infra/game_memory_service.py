"""Context compression service for GM narrative memory.

context_summary テーブルを長期記憶のストアとして使用し、
一定ターン数ごとに Gemini で会話履歴を圧縮・要約する。

BaseMemoryService 継承を廃止した理由:
- BaseMemoryService は search_memory / add_session_to_memory を持つ
  メモリ検索インターフェース (PreloadMemoryTool 経由でプロンプトに注入) であり、
  圧縮トリガーとして使用するのは設計上の誤用だった。
- Runner(memory_service=...) が PreloadMemoryTool を自動注入し、
  GmContextService が構築したプロンプトに <PAST_CONVERSATIONS> が二重注入される。
- add_events_to_memory(events=[]) という空リスト呼び出しも ADK 仕様に反する。

代わりに純粋なサービスクラスとして以下を提供する:
- trigger_compression_if_due: ターン数閾値に達した場合に圧縮を実行
- flush: セッション終了時に強制圧縮を実行 (best effort)
"""

from __future__ import annotations

import json
import uuid
from typing import TYPE_CHECKING

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
    from domain.entity.models import ContextSummaries, Turns
    from infra.gemini_client import GeminiClient

logger = get_logger(__name__)

COMPRESSION_INTERVAL = 5


class _CompressionResult(BaseModel):
    """Structured output for context compression."""

    plot_essentials: dict[str, object]
    short_term_summary: str
    confirmed_facts: dict[str, object]


class GameMemoryService:
    """Context compression service for GM narrative memory.

    context_summary テーブルを長期記憶ストアとして使用し、
    一定ターン数ごとに Gemini で会話履歴を圧縮・要約する。

    ADK BaseMemoryService を継承しないため:
    - Runner に memory_service として渡さない → PreloadMemoryTool 二重注入なし
    - trigger_compression_if_due / flush を AdkGmClient から直接呼び出す
    """

    def __init__(self, gemini: GeminiClient) -> None:
        self._gemini = gemini
        self._context_gw = ContextSummaryGateway()
        self._turn_gw = TurnGateway()

    async def trigger_compression_if_due(self, game_session_id: str) -> None:
        """Compress context if the compression interval has been reached."""
        try:
            session_uuid = uuid.UUID(game_session_id)
        except ValueError:
            logger.warning("Invalid game_session_id", game_session_id=game_session_id)
            return
        await self._compress_if_due(session_uuid)

    async def flush(self, game_session_id: str) -> None:
        """Force context compression at session end (best effort)."""
        try:
            session_uuid = uuid.UUID(game_session_id)
        except ValueError:
            logger.warning(
                "Invalid game_session_id for flush",
                game_session_id=game_session_id,
            )
            return
        await self._fetch_and_run_compression(session_uuid)

    async def _compress_if_due(self, game_session_id: uuid.UUID) -> None:
        """Skip compression if the interval threshold has not been reached.

        DB を1回だけフェッチしてインターバル判定と圧縮データの両方に使用する。
        """
        with SQLModelSession(engine) as db:
            ctx = self._context_gw.get_by_session(db, game_session_id)
            last_updated = int(ctx.last_updated_turn) if ctx else 0
            turns = self._turn_gw.get_recent(db, game_session_id, limit=10)
            current_turn = int(turns[0].turn_number) if turns else 0

        if (current_turn - last_updated) < COMPRESSION_INTERVAL:
            return

        await self._run_compression(
            game_session_id,
            ctx_rec=ctx,
            turns=turns,
            current_turn=current_turn,
        )

    async def _fetch_and_run_compression(self, game_session_id: uuid.UUID) -> None:
        """Fetch DB data once and run compression unconditionally (for flush)."""
        with SQLModelSession(engine) as db:
            ctx = self._context_gw.get_by_session(db, game_session_id)
            turns = self._turn_gw.get_recent(db, game_session_id, limit=10)
            current_turn = int(turns[0].turn_number) if turns else 0

        await self._run_compression(
            game_session_id,
            ctx_rec=ctx,
            turns=turns,
            current_turn=current_turn,
        )

    async def _run_compression(
        self,
        game_session_id: uuid.UUID,
        *,
        ctx_rec: ContextSummaries | None,
        turns: list[Turns],
        current_turn: int,
    ) -> None:
        """Run Gemini compression and persist results to context_summary.

        フェッチ済みデータを受け取るため DB への再アクセスは発生しない。
        """
        prev_plot = json.dumps(ctx_rec.plot_essentials if ctx_rec else {})
        prev_facts = json.dumps(ctx_rec.confirmed_facts if ctx_rec else {})
        prev_summary = ctx_rec.short_term_summary if ctx_rec else ""

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
