"""Tests for GmDecisionService runtime/session behaviors."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest

from src.domain.entity.gm_types import GmDecisionResponse
from src.domain.service.gm_decision_service import GmDecisionRuntime, GmDecisionService
from src.infra.gemini_client import GeminiStructuredResult, GeminiUsageMetadata


class TestGmDecisionRuntime:
    """Runtime state handling for interactions/cache."""

    @pytest.mark.asyncio
    async def test_decide_updates_interaction_chain(self) -> None:
        """Successful interaction decision should update runtime ids."""
        gemini = MagicMock()
        gemini.generate_structured_with_meta = AsyncMock(
            return_value=GeminiStructuredResult(
                value=GmDecisionResponse(
                    decision_type="narrate",
                    narration_text="ok",
                ),
                interaction_id="interaction-1",
                usage=GeminiUsageMetadata(total_tokens=42),
            ),
        )
        svc = GmDecisionService(gemini)  # type: ignore[arg-type]
        runtime = GmDecisionRuntime(
            use_interactions=True,
            cached_content_name="cachedContents/game",
        )

        decision = await svc.decide("prompt", runtime=runtime)

        assert decision.decision_type == "narrate"
        assert runtime.previous_interaction_id == "interaction-1"
        assert runtime.interaction_ids == ["interaction-1"]
        kwargs = gemini.generate_structured_with_meta.call_args.kwargs
        assert kwargs["use_interactions"] is True
        assert kwargs["cached_content_name"] == "cachedContents/game"

    @pytest.mark.asyncio
    async def test_decide_disables_interactions_after_failure(self) -> None:
        """When interactions call fails, retry should continue without it."""
        gemini = MagicMock()
        gemini.generate_structured_with_meta = AsyncMock(
            side_effect=[
                RuntimeError("interaction failed"),
                GeminiStructuredResult(
                    value=GmDecisionResponse(
                        decision_type="narrate",
                        narration_text="fallback",
                    ),
                ),
            ],
        )
        svc = GmDecisionService(gemini)  # type: ignore[arg-type]
        runtime = GmDecisionRuntime(
            use_interactions=True,
            previous_interaction_id="prev-id",
        )

        decision = await svc.decide("prompt", runtime=runtime)

        assert decision.narration_text == "fallback"
        assert runtime.use_interactions is False
        assert runtime.previous_interaction_id is None
        second_kwargs = gemini.generate_structured_with_meta.call_args_list[1].kwargs
        assert second_kwargs["use_interactions"] is False

    @pytest.mark.asyncio
    async def test_cleanup_runtime_deletes_interactions_and_cache(self) -> None:
        """cleanup_runtime should remove ephemeral interaction/cache resources."""
        gemini = MagicMock()
        gemini.delete_interaction = AsyncMock()
        gemini.delete_prompt_cache = AsyncMock()
        svc = GmDecisionService(gemini)  # type: ignore[arg-type]
        runtime = GmDecisionRuntime(
            use_interactions=True,
            previous_interaction_id="interaction-2",
            interaction_ids=["interaction-1", "interaction-2"],
            cached_content_name="cachedContents/game",
        )

        await svc.cleanup_runtime(runtime)

        assert gemini.delete_interaction.await_count == 2
        gemini.delete_prompt_cache.assert_awaited_once_with("cachedContents/game")
        assert runtime.interaction_ids == []
        assert runtime.previous_interaction_id is None
        assert runtime.cached_content_name is None
