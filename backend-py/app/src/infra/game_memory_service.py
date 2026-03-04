"""PostgreSQL-backed ADK MemoryService for GM narrative memory.

BaseMemoryService を継承し、context_summary テーブルを長期記憶のストアとして使用する。
user_id = ゲームセッション UUID (str) でメモリをスコープする。

設計:
- search_memory(): context_summary を MemoryEntry で返す。
  PreloadMemoryTool が毎ターン呼び出し、<PAST_CONVERSATIONS> として
  システム指示に自動注入するため、CONTEXT_TEMPLATE に plot_essentials /
  short_term_summary / confirmed_facts のセクションは含めない。
- add_session_to_memory(): セッション終了時に強制圧縮を実行。
  Runner は自動呼び出しをしないため AdkGmClient.cleanup_session() から呼ぶ。
- trigger_compression_if_due(): 毎ターン後に呼び出し、閾値到達時のみ圧縮。
  BaseMemoryService 標準メソッドにはない ADK 拡張メソッド。
- add_events_to_memory() は利用しない。イベントデルタではなく DB 集計で
  圧縮タイミングを判断するため、基底クラスの NotImplementedError をそのまま使う。

将来 VertexAiMemoryBankService への差し替えは Runner(memory_service=...) の
1行変更で対応可能。
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
    from domain.entity.models import ContextSummaries, Turns
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
    - Runner(memory_service=...) に渡せる → PreloadMemoryTool が自動注入
    - VertexAiMemoryBankService への差し替えが容易
    - ADK の設計パターンに準拠

    PreloadMemoryTool は毎 LLM 呼び出し前に search_memory() を実行し、
    結果を <PAST_CONVERSATIONS> としてシステム指示に注入する。
    よって CONTEXT_TEMPLATE 側に plot_essentials / short_term_summary /
    confirmed_facts を含めないことで二重注入を防ぐ。
    """

    def __init__(self, gemini: GeminiClient) -> None:
        self._gemini = gemini
        self._context_gw = ContextSummaryGateway()
        self._turn_gw = TurnGateway()

    async def add_session_to_memory(self, session: object) -> None:
        """Force compression when a session ends.

        Runner は自動呼び出しをしないため AdkGmClient.cleanup_session() から
        手動で呼び出す。session.user_id をゲームセッション ID として使用する。
        """
        user_id = getattr(session, "user_id", None)
        if not user_id:
            return
        try:
            session_uuid = uuid.UUID(str(user_id))
        except ValueError:
            logger.warning("Invalid user_id for memory", user_id=user_id)
            return
        await self._fetch_and_run_compression(session_uuid)

    async def search_memory(
        self,
        *,
        app_name: str,
        user_id: str,
        query: str,
    ) -> SearchMemoryResponse:
        """Return context_summary as MemoryEntry for PreloadMemoryTool injection.

        query は無視する。ゲームセッションの文脈は常に全体を返すため
        セマンティック検索は不要。
        """
        try:
            session_uuid = uuid.UUID(user_id)
        except ValueError:
            return SearchMemoryResponse()

        with SQLModelSession(engine) as db:
            ctx = self._context_gw.get_by_session(db, session_uuid)

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

    async def trigger_compression_if_due(self, game_session_id: str) -> None:
        """Compress context if the compression interval has been reached.

        毎ターン後に AdkGmClient.decide() から呼び出す。
        閾値未満の場合はノーオペレーション。
        """
        try:
            session_uuid = uuid.UUID(game_session_id)
        except ValueError:
            logger.warning("Invalid game_session_id", game_session_id=game_session_id)
            return
        await self._compress_if_due(session_uuid)

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
        """Fetch DB data once and run compression unconditionally.

        add_session_to_memory() からセッション終了時に呼び出す。
        """
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


def _format_context_summary(ctx: object) -> str:
    """Format context_summary fields for PreloadMemoryTool injection.

    セクションヘッダーを維持することで GM_SYSTEM_PROMPT との整合性を保つ。
    """
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
