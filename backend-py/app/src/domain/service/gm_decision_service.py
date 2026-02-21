"""Core GM decision engine using Gemini structured output."""

from __future__ import annotations

from typing import TYPE_CHECKING

from domain.entity.gm_prompts import GM_SYSTEM_PROMPT
from domain.entity.gm_types import GmDecisionResponse
from util.logging import get_logger

if TYPE_CHECKING:
    from infra.gemini_client import GeminiClient

logger = get_logger(__name__)


class GmDecisionService:
    """Call Gemini structured output for GM decisions."""

    MAX_RETRIES = 3

    def __init__(self, gemini: GeminiClient) -> None:
        self.gemini = gemini

    async def decide(self, prompt: str) -> GmDecisionResponse:
        """Get GM decision with retry and fallback."""
        temp = 0.8
        for attempt in range(self.MAX_RETRIES):
            try:
                return await self.gemini.generate_structured(
                    contents=prompt,
                    system_instruction=GM_SYSTEM_PROMPT,
                    response_type=GmDecisionResponse,
                    temperature=temp,
                )
            except Exception as exc:
                logger.exception(
                    "GM decision attempt failed",
                    attempt=attempt + 1,
                    error=str(exc),
                )
                temp = 0.0
        return self._fallback()

    @staticmethod
    def _fallback() -> GmDecisionResponse:
        return GmDecisionResponse(
            decision_type="narrate",
            narration_text=(
                "The world seems to pause for a moment. What would you like to do?"
            ),
        )
