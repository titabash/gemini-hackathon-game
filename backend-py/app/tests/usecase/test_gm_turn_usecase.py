"""Tests for GmTurnUseCase turn-limit and condition evaluation integration.

Verifies hard-limit bypass, soft-limit prompt injection,
normal-turn passthrough, and condition-triggered session endings.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.domain.entity.gm_types import (
    FlagChange,
    GmDecisionResponse,
    GmTurnRequest,
    SessionEnd,
    StateChanges,
)

if TYPE_CHECKING:
    from collections.abc import AsyncIterator


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_request(
    *,
    session_id: str = "00000000-0000-0000-0000-000000000001",
    input_type: str = "do",
    input_text: str = "look around",
) -> GmTurnRequest:
    return GmTurnRequest(
        session_id=session_id,
        input_type=input_type,  # type: ignore[arg-type]
        input_text=input_text,
    )


def _fake_session(
    *,
    status: str = "active",
    turn: int = 5,
    scenario_id: str = "11111111-1111-1111-1111-111111111111",
    current_state: dict[str, Any] | None = None,
) -> MagicMock:
    sess = MagicMock()
    sess.status = status
    sess.current_turn_number = turn
    sess.id = "00000000-0000-0000-0000-000000000001"
    sess.scenario_id = scenario_id
    sess.current_state = current_state or {}
    return sess


def _fake_decision(
    *,
    state_changes: StateChanges | None = None,
) -> GmDecisionResponse:
    return GmDecisionResponse(
        decision_type="narrate",
        narration_text="You see a dark room.",
        state_changes=state_changes,
    )


async def _collect(it: AsyncIterator[str]) -> list[str]:
    return [e async for e in it]


async def _async_iter(items: list[str]) -> AsyncIterator[str]:
    for item in items:
        yield item


def _stub_common(uc: object, *, turn_return: int) -> None:
    """Wire up mutation / persist / compress stubs."""
    uc.mutation_svc.apply = MagicMock()  # type: ignore[attr-defined]
    uc.mutation_svc.apply_session_end = MagicMock()  # type: ignore[attr-defined]
    uc.session_gw.increment_turn = MagicMock(  # type: ignore[attr-defined]
        return_value=turn_return,
    )
    uc.turn_gw.create = MagicMock()  # type: ignore[attr-defined]
    uc.context_gw.get_by_session = MagicMock(  # type: ignore[attr-defined]
        return_value=None,
    )
    uc.npc_gw.get_active_by_session = MagicMock(  # type: ignore[attr-defined]
        return_value=[],
    )
    uc.npc_gw.get_by_scenario = MagicMock(  # type: ignore[attr-defined]
        return_value=[],
    )


async def _empty_stream(
    *_args: object,
    **_: object,
) -> AsyncIterator[str]:
    return
    yield  # pragma: no cover


class _CtxBuilder:
    """Fluent builder for fake GameContext mocks."""

    def __init__(self) -> None:
        self._attrs: dict[str, object] = {
            "current_turn_number": 5,
            "max_turns": 30,
            "win_conditions": [],
            "fail_conditions": [],
            "current_state": {},
        }
        self._stats: dict[str, object] = {"hp": 100}

    def conditions(
        self,
        *,
        win: list[dict[str, object]] | None = None,
        fail: list[dict[str, object]] | None = None,
    ) -> _CtxBuilder:
        if win is not None:
            self._attrs["win_conditions"] = win
        if fail is not None:
            self._attrs["fail_conditions"] = fail
        return self

    def state(
        self,
        *,
        stats: dict[str, object] | None = None,
        current: dict[str, object] | None = None,
    ) -> _CtxBuilder:
        if stats is not None:
            self._stats = stats
        if current is not None:
            self._attrs["current_state"] = current
        return self

    def build(self) -> MagicMock:
        ctx = MagicMock()
        for k, v in self._attrs.items():
            setattr(ctx, k, v)
        ctx.player = MagicMock()
        ctx.player.stats = self._stats
        return ctx


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


class TestHardLimit:
    """When turn >= max_turns, Gemini must NOT be called."""

    @pytest.mark.asyncio
    async def test_hard_limit_skips_gemini(self) -> None:
        """At hard limit, decision_svc.decide must not be called."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=30),
            )
            uc.context_svc.build_context = MagicMock()
            ctx = uc.context_svc.build_context.return_value
            ctx.current_turn_number = 30
            ctx.max_turns = 30

            uc.decision_svc.decide = AsyncMock(
                return_value=_fake_decision(),
            )
            _stub_common(uc, turn_return=31)

            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))
            uc.decision_svc.decide.assert_not_called()

    @pytest.mark.asyncio
    async def test_hard_limit_yields_bad_end(self) -> None:
        """At hard limit, SSE stream must contain bad_end content."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=30),
            )
            uc.context_svc.build_context = MagicMock()
            ctx = uc.context_svc.build_context.return_value
            ctx.current_turn_number = 30
            ctx.max_turns = 30

            uc.decision_svc.decide = AsyncMock(
                return_value=_fake_decision(),
            )
            _stub_common(uc, turn_return=31)

            captured: list[GmDecisionResponse] = []

            async def _capture_stream(
                decision: GmDecisionResponse,
                **_: object,
            ) -> AsyncIterator[str]:
                captured.append(decision)
                return
                yield  # pragma: no cover

            uc.bridge_svc.stream_decision = _capture_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            assert len(captured) == 1
            d = captured[0]
            assert d.state_changes is not None
            assert d.state_changes.session_end is not None
            assert d.state_changes.session_end.ending_type == "bad_end"


class TestSoftLimit:
    """When close to max_turns, prompt must include convergence instructions."""

    @pytest.mark.asyncio
    async def test_soft_limit_adds_convergence_prompt(self) -> None:
        """Within soft-limit window, prompt must contain turn-limit addition."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=27),
            )
            uc.context_svc.build_context = MagicMock()
            ctx = uc.context_svc.build_context.return_value
            ctx.current_turn_number = 27
            ctx.max_turns = 30

            captured_kw: list[dict[str, object]] = []

            def _spy(
                *_args: object,
                **kwargs: object,
            ) -> str:
                captured_kw.append(kwargs)
                return "mocked prompt"

            uc.context_svc.build_prompt = _spy

            uc.decision_svc.decide = AsyncMock(
                return_value=_fake_decision(),
            )
            _stub_common(uc, turn_return=28)

            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            assert len(captured_kw) == 1
            raw_sections: Any = captured_kw[0].get("extra_sections", [])
            full = "\n".join(str(s) for s in raw_sections if s)
            assert full != ""
            assert "3" in full


class TestNormalTurn:
    """When far from limit, no turn-limit additions should be present."""

    @pytest.mark.asyncio
    async def test_no_convergence_on_early_turn(self) -> None:
        """Early turns must NOT inject convergence prompt."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=5),
            )
            uc.context_svc.build_context = MagicMock()
            ctx = uc.context_svc.build_context.return_value
            ctx.current_turn_number = 5
            ctx.max_turns = 30

            captured_kw: list[dict[str, object]] = []

            def _spy(
                *_args: object,
                **kwargs: object,
            ) -> str:
                captured_kw.append(kwargs)
                return "mocked prompt"

            uc.context_svc.build_prompt = _spy

            uc.decision_svc.decide = AsyncMock(
                return_value=_fake_decision(),
            )
            _stub_common(uc, turn_return=6)

            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            assert len(captured_kw) == 1
            raw_sections: Any = captured_kw[0].get("extra_sections", [])
            soft_parts = [
                str(s) for s in raw_sections if s and "remaining" in str(s).lower()
            ]
            assert soft_parts == []


class TestConditionEvaluation:
    """Condition evaluation integration in the turn pipeline."""

    @pytest.mark.asyncio
    async def test_flags_achieved_triggers_victory(self) -> None:
        """All required flags achieved → session_end(victory) applied."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(
                    turn=10,
                    current_state={"flags": {"clue_a": True}},
                ),
            )
            ctx = (
                _CtxBuilder()
                .conditions(
                    win=[
                        {
                            "id": "w1",
                            "description": "Find clues",
                            "requiredFlags": ["clue_a", "clue_b"],
                        },
                    ],
                    fail=[
                        {
                            "id": "f1",
                            "description": "HP zero",
                            "condition": "pc.stats.hp <= 0",
                        },
                    ],
                )
                .state(
                    stats={"hp": 50},
                    current={"flags": {"clue_a": True}},
                )
                .build()
            )
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")

            # Decision sets clue_b flag → all flags achieved
            decision = _fake_decision(
                state_changes=StateChanges(
                    flag_changes=[
                        FlagChange(flag_id="clue_b", value=True),
                    ],
                ),
            )
            uc.decision_svc.decide = AsyncMock(return_value=decision)
            _stub_common(uc, turn_return=11)
            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            uc.mutation_svc.apply_session_end.assert_called_once()
            call_args = uc.mutation_svc.apply_session_end.call_args
            end: SessionEnd = call_args[0][2]
            assert end.ending_type == "victory"

    @pytest.mark.asyncio
    async def test_hp_zero_triggers_bad_end(self) -> None:
        """HP reaching 0 → session_end(bad_end) applied."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=10),
            )
            ctx = (
                _CtxBuilder()
                .conditions(
                    win=[
                        {
                            "id": "w1",
                            "description": "Find clues",
                            "requiredFlags": ["clue_a"],
                        },
                    ],
                    fail=[
                        {
                            "id": "f1",
                            "description": "HP zero",
                            "condition": "pc.stats.hp <= 0",
                        },
                    ],
                )
                .state(stats={"hp": 10})
                .build()
            )
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")

            # HP delta makes HP go to 0
            decision = _fake_decision(
                state_changes=StateChanges(hp_delta=-10),
            )
            uc.decision_svc.decide = AsyncMock(return_value=decision)
            _stub_common(uc, turn_return=11)
            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            uc.mutation_svc.apply_session_end.assert_called_once()
            call_args = uc.mutation_svc.apply_session_end.call_args
            end: SessionEnd = call_args[0][2]
            assert end.ending_type == "bad_end"

    @pytest.mark.asyncio
    async def test_llm_session_end_skips_evaluation(self) -> None:
        """LLM already set session_end → condition evaluation skipped."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=10),
            )
            ctx = (
                _CtxBuilder()
                .conditions(
                    win=[
                        {
                            "id": "w1",
                            "description": "Win",
                            "requiredFlags": ["a"],
                        },
                    ],
                )
                .state(
                    stats={"hp": 100},
                    current={"flags": {"a": True}},
                )
                .build()
            )
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")

            # LLM already ends session
            decision = _fake_decision(
                state_changes=StateChanges(
                    session_end=SessionEnd(
                        ending_type="custom_end",
                        ending_summary="LLM ended it",
                    ),
                ),
            )
            uc.decision_svc.decide = AsyncMock(return_value=decision)
            _stub_common(uc, turn_return=11)
            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            # apply_session_end should NOT be called (LLM end handled by apply)
            uc.mutation_svc.apply_session_end.assert_not_called()

    @pytest.mark.asyncio
    async def test_normal_turn_no_condition_end(self) -> None:
        """Normal turn without conditions met → no session end."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=5),
            )
            ctx = (
                _CtxBuilder()
                .conditions(
                    win=[
                        {
                            "id": "w1",
                            "description": "Win",
                            "requiredFlags": ["a", "b"],
                        },
                    ],
                    fail=[
                        {
                            "id": "f1",
                            "description": "Fail",
                            "condition": "pc.stats.hp <= 0",
                        },
                    ],
                )
                .build()
            )
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")

            decision = _fake_decision()
            uc.decision_svc.decide = AsyncMock(return_value=decision)
            _stub_common(uc, turn_return=6)
            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            uc.mutation_svc.apply_session_end.assert_not_called()
