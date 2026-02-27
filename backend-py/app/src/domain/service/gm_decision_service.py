"""Core GM decision engine using Gemini structured output."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING

from domain.entity.gm_prompts import GM_SYSTEM_PROMPT
from domain.entity.gm_types import GmDecisionResponse
from util.logging import get_logger

if TYPE_CHECKING:
    from infra.gemini_client import GeminiClient, GeminiUsageMetadata

logger = get_logger(__name__)


@dataclass
class GmDecisionRuntime:
    """Per-request runtime state for Gemini acceleration helpers."""

    use_interactions: bool = False
    previous_interaction_id: str | None = None
    interaction_ids: list[str] = field(default_factory=list)
    cached_content_name: str | None = None
    prompt_cache_attempted: bool = False


class GmDecisionService:
    """Call Gemini structured output for GM decisions."""

    MAX_RETRIES = 3
    MODEL = "gemini-2.5-flash"

    def __init__(self, gemini: GeminiClient) -> None:
        self.gemini = gemini

    async def decide(
        self,
        prompt: str,
        *,
        runtime: GmDecisionRuntime | None = None,
    ) -> GmDecisionResponse:
        """Get GM decision with retry and fallback."""
        temp = 0.8
        for attempt in range(self.MAX_RETRIES):
            try:
                result = await self.gemini.generate_structured_with_meta(
                    contents=prompt,
                    system_instruction=GM_SYSTEM_PROMPT,
                    response_type=GmDecisionResponse,
                    model=self.MODEL,
                    temperature=temp,
                    previous_interaction_id=(
                        runtime.previous_interaction_id if runtime else None
                    ),
                    use_interactions=runtime.use_interactions if runtime else False,
                    cached_content_name=(
                        runtime.cached_content_name if runtime else None
                    ),
                )
                self._apply_runtime(runtime, result.interaction_id)
                self._log_usage(result.usage, runtime)
                return result.value
            except Exception as exc:
                logger.exception(
                    "GM decision attempt failed",
                    attempt=attempt + 1,
                    error=str(exc),
                )
                if runtime and runtime.use_interactions:
                    logger.warning(
                        "Disabling interactions for this request after error",
                        error=str(exc),
                    )
                    runtime.use_interactions = False
                    runtime.previous_interaction_id = None
                temp = 0.0
        return self._fallback()

    async def create_prompt_cache(
        self,
        *,
        contents: str,
        ttl_seconds: int,
        display_name: str | None = None,
    ) -> str | None:
        """Create cache for stable prompt prefix; return cache name or None."""
        try:
            return await self.gemini.create_prompt_cache(
                model=self.MODEL,
                contents=contents,
                ttl=f"{ttl_seconds}s",
                display_name=display_name,
            )
        except Exception as exc:
            logger.warning("Prompt cache creation failed", error=str(exc))
            return None

    async def cleanup_runtime(self, runtime: GmDecisionRuntime) -> None:
        """Delete ephemeral interaction/cache resources (best effort)."""
        for interaction_id in list(runtime.interaction_ids):
            try:
                await self.gemini.delete_interaction(interaction_id)
            except Exception as exc:
                logger.warning(
                    "Interaction cleanup failed",
                    interaction_id=interaction_id,
                    error=str(exc),
                )
        runtime.interaction_ids.clear()
        runtime.previous_interaction_id = None

        cache_name = runtime.cached_content_name
        runtime.cached_content_name = None
        if not cache_name:
            return
        try:
            await self.gemini.delete_prompt_cache(cache_name)
        except Exception as exc:
            logger.warning(
                "Prompt cache cleanup failed",
                cache_name=cache_name,
                error=str(exc),
            )

    @staticmethod
    def _apply_runtime(
        runtime: GmDecisionRuntime | None,
        interaction_id: str | None,
    ) -> None:
        """Update runtime interaction chain after a successful decision."""
        if runtime is None or not runtime.use_interactions or not interaction_id:
            return
        runtime.previous_interaction_id = interaction_id
        runtime.interaction_ids.append(interaction_id)

    @staticmethod
    def _log_usage(
        usage: GeminiUsageMetadata | None,
        runtime: GmDecisionRuntime | None,
    ) -> None:
        """Emit normalized usage logs for observability."""
        if usage is None:
            return
        logger.info(
            "Gemini token usage",
            total_tokens=usage.total_tokens,
            prompt_tokens=usage.prompt_tokens,
            output_tokens=usage.output_tokens,
            cached_tokens=usage.cached_tokens,
            used_interactions=runtime.use_interactions if runtime else False,
            used_prompt_cache=bool(runtime.cached_content_name) if runtime else False,
        )

    @staticmethod
    def _fallback() -> GmDecisionResponse:
        return GmDecisionResponse(
            decision_type="narrate",
            narration_text=(
                "The world seems to pause for a moment. What would you like to do?"
            ),
        )
