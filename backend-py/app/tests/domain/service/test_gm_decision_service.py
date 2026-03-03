"""Tests for GmDecisionService ADK session/runtime behaviors."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest

from src.domain.entity.gm_types import GmDecisionResponse
from src.domain.service.gm_decision_service import GmDecisionRuntime, GmDecisionService


def _make_adk_mock(
    *,
    side_effect: object = None,
    return_value: GmDecisionResponse | None = None,
) -> MagicMock:
    """AdkGmClient のモックを構築する."""
    adk = MagicMock()
    if side_effect is not None:
        adk.decide = AsyncMock(side_effect=side_effect)
    else:
        response = return_value or GmDecisionResponse(
            decision_type="narrate",
            narration_text="ok",
        )
        adk.decide = AsyncMock(return_value=response)
    adk.cleanup_session = AsyncMock()
    return adk


class TestGmDecisionRuntime:
    """ADK セッション管理を中心とした GmDecisionService のテスト."""

    @pytest.mark.asyncio
    async def test_decide_creates_adk_session_id_in_runtime(self) -> None:
        """初回 decide() は runtime.adk_session_id を設定すること."""
        adk = _make_adk_mock()
        svc = GmDecisionService(adk)
        runtime = GmDecisionRuntime(use_interactions=True)

        assert runtime.adk_session_id is None

        decision = await svc.decide("prompt", runtime=runtime)

        assert decision.decision_type == "narrate"
        assert runtime.adk_session_id is not None
        # ADK に渡った session_id が runtime に保存されたものと一致
        call_kwargs = adk.decide.call_args.kwargs
        assert call_kwargs["session_id"] == runtime.adk_session_id

    @pytest.mark.asyncio
    async def test_decide_reuses_adk_session_id_across_turns(self) -> None:
        """2回目以降の decide() は同じ adk_session_id を使うこと."""
        adk = _make_adk_mock()
        svc = GmDecisionService(adk)
        runtime = GmDecisionRuntime(use_interactions=True)

        await svc.decide("turn 1", runtime=runtime)
        first_session_id = runtime.adk_session_id

        await svc.decide("turn 2", runtime=runtime)
        second_session_id = runtime.adk_session_id

        assert first_session_id == second_session_id
        assert adk.decide.await_count == 2
        # 両ターンで同じ session_id が渡されること
        calls = adk.decide.call_args_list
        assert calls[0].kwargs["session_id"] == first_session_id
        assert calls[1].kwargs["session_id"] == first_session_id

    @pytest.mark.asyncio
    async def test_decide_raises_after_all_retries_fail(self) -> None:
        """MAX_RETRIES 回すべて失敗した場合、最後の例外を raise すること."""
        adk = _make_adk_mock(side_effect=RuntimeError("ADK down"))
        svc = GmDecisionService(adk)

        with pytest.raises(RuntimeError, match="ADK down"):
            await svc.decide("prompt")

        assert adk.decide.await_count == GmDecisionService.MAX_RETRIES

    @pytest.mark.asyncio
    async def test_decide_succeeds_on_second_attempt(self) -> None:
        """1回目失敗・2回目成功の場合、正しい決定を返すこと."""
        success_response = GmDecisionResponse(
            decision_type="choice",
            narration_text="Choose your path.",
        )
        adk = _make_adk_mock(
            side_effect=[
                RuntimeError("transient error"),
                success_response,
            ],
        )
        svc = GmDecisionService(adk)

        decision = await svc.decide("prompt")

        assert decision.decision_type == "choice"
        assert adk.decide.await_count == 2

    @pytest.mark.asyncio
    async def test_cleanup_runtime_deletes_adk_session(self) -> None:
        """cleanup_runtime() は adk.cleanup_session を呼び出すこと."""
        adk = _make_adk_mock()
        svc = GmDecisionService(adk)
        runtime = GmDecisionRuntime(
            use_interactions=True,
            adk_session_id="session-to-cleanup",
        )

        await svc.cleanup_runtime(runtime)

        adk.cleanup_session.assert_awaited_once_with("session-to-cleanup")
        assert runtime.adk_session_id is None

    @pytest.mark.asyncio
    async def test_cleanup_runtime_no_session_is_noop(self) -> None:
        """adk_session_id が None の場合、cleanup_session を呼ばないこと."""
        adk = _make_adk_mock()
        svc = GmDecisionService(adk)
        runtime = GmDecisionRuntime()

        await svc.cleanup_runtime(runtime)

        adk.cleanup_session.assert_not_awaited()
