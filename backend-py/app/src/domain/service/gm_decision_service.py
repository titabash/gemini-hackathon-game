"""Core GM decision engine using ADK structured output.

google-adk の AdkGmClient を介して GmDecisionResponse を取得する。
直接 SDK (google-genai) を使わず ADK 経由にすることで:
- output_schema (Pydantic) のネイティブサポート
- use_interactions_api による自動セッション管理
- セッションベースのマルチターン連鎖
を実現する。
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import TYPE_CHECKING

from util.logging import get_logger

if TYPE_CHECKING:
    from domain.entity.gm_types import GmDecisionResponse
    from infra.adk_gm_client import AdkGmClient

logger = get_logger(__name__)


@dataclass
class GmDecisionRuntime:
    """Per-request runtime state for ADK session management.

    use_interactions=True のとき、同一リクエスト内の複数ターンで
    adk_session_id を共有し、ADK セッション経由で会話履歴を引き継ぐ。
    use_interactions=False のときは各ターンを独立したセッションで実行する。
    """

    use_interactions: bool = False
    adk_session_id: str | None = None


class GmDecisionService:
    """Call ADK agent for GM decisions (structured output via GmDecisionResponse)."""

    MAX_RETRIES = 3

    def __init__(self, adk: AdkGmClient) -> None:
        self._adk = adk

    async def decide(
        self,
        prompt: str,
        *,
        game_session_id: str,
        runtime: GmDecisionRuntime | None = None,
    ) -> GmDecisionResponse:
        """Get GM decision with retry.  Raises the last exception on exhaustion."""
        last_exc: BaseException = RuntimeError("GM decision retries exhausted")
        for attempt in range(self.MAX_RETRIES):
            try:
                session_id = self._get_or_create_session_id(runtime)
                result = await self._adk.decide(
                    prompt=prompt,
                    session_id=session_id,
                    game_session_id=game_session_id,
                )
                logger.info("GM decision succeeded", attempt=attempt + 1)
                return result
            except Exception as exc:
                last_exc = exc
                logger.exception(
                    "GM decision attempt failed",
                    attempt=attempt + 1,
                )
        logger.error(
            "All GM decision retries exhausted",
            max_retries=self.MAX_RETRIES,
        )
        raise last_exc

    async def cleanup_runtime(
        self, runtime: GmDecisionRuntime, *, game_session_id: str
    ) -> None:
        """Delete ephemeral ADK session resources (best effort)."""
        session_id = runtime.adk_session_id
        runtime.adk_session_id = None

        if not session_id:
            return

        await self._adk.cleanup_session(session_id, game_session_id=game_session_id)

    @staticmethod
    def _get_or_create_session_id(runtime: GmDecisionRuntime | None) -> str:
        """Return session ID based on interaction mode.

        use_interactions=True: 同一 runtime で session_id を共有し、ADK セッション
        経由で会話履歴を引き継ぐ (auto-advance マルチターン用)。
        use_interactions=False または runtime=None: ターンごとに独立した UUID を生成。
        """
        if runtime is None or not runtime.use_interactions:
            return str(uuid.uuid4())
        if runtime.adk_session_id is None:
            runtime.adk_session_id = str(uuid.uuid4())
        return runtime.adk_session_id
