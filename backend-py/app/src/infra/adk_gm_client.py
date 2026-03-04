"""ADK-backed GM LLM client.

google-adk の Runner + DatabaseSessionService をラップする薄いアダプタ。
GmDecisionService から注入され、LLM 呼び出し層を担う。

LangChain 不採用理由: response_json_schema が langchain-google-genai 未対応。
ADK 採用理由: output_schema で Pydantic 直接指定、DatabaseSessionService で永続化。

注意: use_interactions_api=True は response_schema を API リクエストに含めないため
output_schema と組み合わせると構造化出力が保証されない。使用しない。
セッション履歴の継続性は DatabaseSessionService が担保する。

スキーマ分離:
ADK が自動生成するテーブル (sessions, events, app_states 等) を PostgreSQL の
adk スキーマに隔離することで public スキーマと衝突しない。
- Drizzle は schemaFilter: ['public'] のため adk スキーマを無視する。
- sqlacodegen は --schemas public のため adk スキーマをスキャンしない。
- create_async_engine は lazy のためテストでは実際の DB 接続は発生しない。

SSL:
asyncpg は URL クエリの sslmode パラメータを解釈しない。
sslmode=require が含まれる場合は URL から除去し connect_args["ssl"]=True で対応する。
参照: https://github.com/MagicStack/asyncpg/issues/737
"""

from __future__ import annotations

import os
from typing import TYPE_CHECKING
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

from google.adk.agents import LlmAgent
from google.adk.models.google_llm import Gemini
from google.adk.runners import Runner
from google.adk.sessions import DatabaseSessionService
from google.adk.tools.preload_memory_tool import preload_memory_tool
from google.genai import types as genai_types

from domain.entity.gm_prompts import GM_SYSTEM_PROMPT
from domain.entity.gm_types import GmDecisionResponse
from util.logging import get_logger

if TYPE_CHECKING:
    from infra.game_memory_service import GameMemoryService

logger = get_logger(__name__)


def _adk_session_service() -> DatabaseSessionService:
    """Build a DatabaseSessionService for ADK.

    DATABASE_URL を PostgreSQL+asyncpg に変換して使用する。
    adk スキーマへの search_path 指定により ADK テーブルが public スキーマに
    混入せず、Drizzle マイグレーション・sqlacodegen と衝突しない。

    asyncpg は URL クエリの sslmode を解釈しないため、sslmode=require が
    含まれる場合は URL から除去して connect_args["ssl"]=True に変換する。
    create_async_engine は lazy のため、テストで runner.run_async をモックして
    いる限り実際の DB 接続は発生しない。
    """
    raw_url = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:postgres@localhost:54322/postgres",
    )
    # dialect を asyncpg に統一: "postgresql+asyncpg://<host>/<db>"
    rest = raw_url.split("://", 1)[1]
    asyncpg_url = f"postgresql+asyncpg://{rest}"

    # asyncpg は URL の sslmode パラメータを解釈しない (asyncpg#737)。
    # sslmode=require が含まれる場合は URL から除去し connect_args で対応する。
    parsed = urlparse(asyncpg_url)
    query = parse_qs(parsed.query)
    sslmode = query.pop("sslmode", [None])[0]
    clean_url = urlunparse(
        parsed._replace(query=urlencode({k: v[0] for k, v in query.items()}))
    )

    connect_args: dict[str, object] = {
        "server_settings": {"search_path": "adk"},
    }
    if sslmode == "require":
        connect_args["ssl"] = True

    return DatabaseSessionService(clean_url, connect_args=connect_args)


class AdkGmClient:
    """ADK Runner + DatabaseSessionService をラップした GM LLM クライアント.

    GeminiClient.generate_structured_with_meta の代替として
    GmDecisionService に注入される。

    セッション管理は ADK の auto_create_session に委譲する。
    run_async() 呼び出し時に session_id が存在しなければ ADK が自動生成する。
    DatabaseSessionService により ADK セッション履歴は PostgreSQL の
    adk スキーマに永続化される (public スキーマとは完全に分離)。

    memory_service を Runner に渡すことで InvocationContext に保存される。
    PreloadMemoryTool は agent.tools に明示的に追加されており、毎 LLM 呼び出し前に
    search_memory() を実行して <PAST_CONVERSATIONS> としてコンテキストを注入する。
    二重注入を防ぐため CONTEXT_TEMPLATE 側には plot_essentials /
    short_term_summary / confirmed_facts を含めない。
    user_id には game_session_id (UUID 文字列) を使用し、メモリスコープを
    ゲームセッション単位に限定する。
    """

    _APP_NAME = "gm"
    MODEL = "gemini-3-flash-preview"

    def __init__(self, memory_service: GameMemoryService) -> None:
        api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
        if not api_key:
            msg = "GEMINI_API_KEY or GOOGLE_API_KEY environment variable is not set"
            raise ValueError(msg)

        # ADK は GOOGLE_API_KEY を読む; GEMINI_API_KEY がある場合はマップする
        os.environ.setdefault("GOOGLE_API_KEY", api_key)

        self._memory_service = memory_service
        agent = LlmAgent(
            name="gm_agent",
            model=Gemini(model=self.MODEL),
            instruction=GM_SYSTEM_PROMPT,
            output_schema=GmDecisionResponse,
            tools=[preload_memory_tool],
        )
        self._runner = Runner(
            agent=agent,
            app_name=self._APP_NAME,
            session_service=_adk_session_service(),
            memory_service=memory_service,
            auto_create_session=True,
        )

    async def decide(
        self, *, prompt: str, session_id: str, game_session_id: str
    ) -> GmDecisionResponse:
        """Run the ADK agent and return a structured GM decision.

        game_session_id を ADK の user_id として使用することで、メモリスコープを
        ゲームセッション単位に限定する。同一 session_id の呼び出しでは ADK セッションが
        再利用され、会話履歴が引き継がれる (auto-advance 時の複数ターン連鎖)。
        セッション作成は auto_create_session で ADK に委譲済み。
        """
        message = genai_types.Content(
            role="user",
            parts=[genai_types.Part(text=prompt)],
        )

        result: GmDecisionResponse | None = None
        async for event in self._runner.run_async(
            user_id=game_session_id,
            session_id=session_id,
            new_message=message,
        ):
            if event.is_final_response():
                if event.content and event.content.parts:
                    # ADK 内部と同じパターン: thought parts を除外して全 parts を結合
                    text = "".join(
                        part.text
                        for part in event.content.parts
                        if part.text and not part.thought
                    )
                    if text.strip():
                        result = GmDecisionResponse.model_validate_json(text)
                break

        if result is None:
            msg = "ADK GM agent returned no structured output"
            raise RuntimeError(msg)

        logger.info(
            "ADK GM decision received",
            session_id=session_id,
            decision_type=result.decision_type,
        )

        # ターン数閾値に達した場合のみ圧縮を実行する。
        await self._memory_service.trigger_compression_if_due(game_session_id)

        return result

    async def cleanup_session(self, session_id: str, game_session_id: str) -> None:
        """Force memory compression then delete the ADK session (best effort).

        セッション終了時に add_session_to_memory() で強制圧縮を実行してから
        ADK セッションを削除する。Runner は add_session_to_memory() を自動呼び出し
        しないため手動でトリガーする。
        """
        # 1. セッション取得 → add_session_to_memory() で強制圧縮 (best effort)
        try:
            session = await self._runner.session_service.get_session(
                app_name=self._APP_NAME,
                user_id=game_session_id,
                session_id=session_id,
            )
            if session is not None:
                await self._memory_service.add_session_to_memory(session)
        except Exception as exc:
            logger.warning(
                "Context compression flush failed",
                session_id=session_id,
                error=str(exc),
            )

        # 2. ADK セッション削除 (best effort)
        try:
            await self._runner.session_service.delete_session(
                app_name=self._APP_NAME,
                user_id=game_session_id,
                session_id=session_id,
            )
        except Exception as exc:
            logger.warning(
                "ADK session cleanup failed",
                session_id=session_id,
                error=str(exc),
            )
