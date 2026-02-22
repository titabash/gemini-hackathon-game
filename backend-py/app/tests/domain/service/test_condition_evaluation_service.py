"""Tests for ConditionEvaluationService.

Validates win/fail condition evaluation, safe expression parsing,
and progress prompt generation.
"""

from __future__ import annotations

from typing import Any

import pytest

from src.domain.service.condition_evaluation_service import (
    ConditionEvaluationResult,
    ConditionEvaluationService,
    WinConditionProgress,
)


@pytest.fixture
def svc() -> ConditionEvaluationService:
    return ConditionEvaluationService()


# ---------------------------------------------------------------------------
# Win condition evaluation
# ---------------------------------------------------------------------------


class TestEvalWinCondition:
    """Test individual win condition flag matching."""

    def test_all_required_flags_achieved(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """All requiredFlags present and True → condition met."""
        condition: dict[str, Any] = {
            "id": "w1",
            "description": "Find all clues",
            "requiredFlags": ["clue_a", "clue_b"],
        }
        flags = {"clue_a": True, "clue_b": True}
        assert svc.eval_win_condition(condition, flags) is True

    def test_partial_flags(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """Only some requiredFlags → condition NOT met."""
        condition: dict[str, Any] = {
            "id": "w1",
            "description": "Find all clues",
            "requiredFlags": ["clue_a", "clue_b"],
        }
        flags = {"clue_a": True}
        assert svc.eval_win_condition(condition, flags) is False

    def test_empty_required_flags(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """Empty requiredFlags → condition NOT met (no auto-win)."""
        condition: dict[str, Any] = {
            "id": "w1",
            "description": "Empty",
            "requiredFlags": [],
        }
        assert svc.eval_win_condition(condition, {}) is False

    def test_flag_set_to_false(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """Flag exists but value is False → NOT achieved."""
        condition: dict[str, Any] = {
            "id": "w1",
            "description": "Test",
            "requiredFlags": ["flag_a"],
        }
        flags = {"flag_a": False}
        assert svc.eval_win_condition(condition, flags) is False

    def test_missing_required_flags_key(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """Condition without requiredFlags key → NOT met."""
        condition: dict[str, Any] = {
            "id": "w1",
            "description": "No flags key",
        }
        assert svc.eval_win_condition(condition, {"x": True}) is False


# ---------------------------------------------------------------------------
# Safe expression evaluation (fail conditions)
# ---------------------------------------------------------------------------


class TestSafeEvalCondition:
    """Test safe expression parsing for fail conditions."""

    def test_hp_zero(self, svc: ConditionEvaluationService) -> None:
        """pc.stats.hp <= 0 with hp=0 → True."""
        assert (
            svc.safe_eval_condition(
                "pc.stats.hp <= 0",
                stats={"hp": 0},
                current_turn=5,
            )
            is True
        )

    def test_hp_positive(self, svc: ConditionEvaluationService) -> None:
        """pc.stats.hp <= 0 with hp=50 → False."""
        assert (
            svc.safe_eval_condition(
                "pc.stats.hp <= 0",
                stats={"hp": 50},
                current_turn=5,
            )
            is False
        )

    def test_san_zero(self, svc: ConditionEvaluationService) -> None:
        """pc.stats.san <= 0 with san=0 → True."""
        assert (
            svc.safe_eval_condition(
                "pc.stats.san <= 0",
                stats={"san": 0, "hp": 100},
                current_turn=5,
            )
            is True
        )

    def test_turn_limit_reached(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """session.currentTurnNumber >= 30 with turn=30 → True."""
        assert (
            svc.safe_eval_condition(
                "session.currentTurnNumber >= 30",
                stats={"hp": 100},
                current_turn=30,
            )
            is True
        )

    def test_turn_limit_not_reached(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """session.currentTurnNumber >= 30 with turn=29 → False."""
        assert (
            svc.safe_eval_condition(
                "session.currentTurnNumber >= 30",
                stats={"hp": 100},
                current_turn=29,
            )
            is False
        )

    def test_unknown_expression(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """Unknown expression → False (safe fallback)."""
        assert (
            svc.safe_eval_condition(
                "some.unknown.expression",
                stats={"hp": 100},
                current_turn=5,
            )
            is False
        )

    def test_stat_less_than(self, svc: ConditionEvaluationService) -> None:
        """pc.stats.hp < 10 with hp=5 → True."""
        assert (
            svc.safe_eval_condition(
                "pc.stats.hp < 10",
                stats={"hp": 5},
                current_turn=5,
            )
            is True
        )

    def test_stat_equals(self, svc: ConditionEvaluationService) -> None:
        """pc.stats.hp == 0 with hp=0 → True."""
        assert (
            svc.safe_eval_condition(
                "pc.stats.hp == 0",
                stats={"hp": 0},
                current_turn=5,
            )
            is True
        )

    def test_missing_stat(self, svc: ConditionEvaluationService) -> None:
        """Missing stat key → False (safe fallback)."""
        assert (
            svc.safe_eval_condition(
                "pc.stats.sanity <= 0",
                stats={"hp": 100},
                current_turn=5,
            )
            is False
        )


# ---------------------------------------------------------------------------
# Full evaluate()
# ---------------------------------------------------------------------------


class TestEvaluate:
    """Test the full evaluate orchestration."""

    def test_fail_takes_priority(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """When both win and fail are triggered, fail wins."""
        win_conditions: list[dict[str, Any]] = [
            {
                "id": "w1",
                "description": "Find all clues",
                "requiredFlags": ["clue_a"],
            },
        ]
        fail_conditions: list[dict[str, Any]] = [
            {
                "id": "f1",
                "description": "HP reaches 0",
                "condition": "pc.stats.hp <= 0",
            },
        ]
        result = svc.evaluate(
            win_conditions=win_conditions,
            fail_conditions=fail_conditions,
            current_flags={"clue_a": True},
            player_stats={"hp": 0},
            current_turn=10,
        )
        assert result.triggered_fail is not None
        assert result.triggered_fail["id"] == "f1"
        assert result.triggered_win is None

    def test_win_detected(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """All flags achieved + no fail → victory triggered."""
        win_conditions: list[dict[str, Any]] = [
            {
                "id": "w1",
                "description": "Find all clues",
                "requiredFlags": ["clue_a", "clue_b"],
            },
        ]
        fail_conditions: list[dict[str, Any]] = [
            {
                "id": "f1",
                "description": "HP reaches 0",
                "condition": "pc.stats.hp <= 0",
            },
        ]
        result = svc.evaluate(
            win_conditions=win_conditions,
            fail_conditions=fail_conditions,
            current_flags={"clue_a": True, "clue_b": True},
            player_stats={"hp": 50},
            current_turn=10,
        )
        assert result.triggered_win is not None
        assert result.triggered_win["id"] == "w1"
        assert result.triggered_fail is None

    def test_nothing_triggered(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """No conditions met → both None, progress calculated."""
        win_conditions: list[dict[str, Any]] = [
            {
                "id": "w1",
                "description": "Find all clues",
                "requiredFlags": ["clue_a", "clue_b"],
            },
        ]
        fail_conditions: list[dict[str, Any]] = [
            {
                "id": "f1",
                "description": "HP reaches 0",
                "condition": "pc.stats.hp <= 0",
            },
        ]
        result = svc.evaluate(
            win_conditions=win_conditions,
            fail_conditions=fail_conditions,
            current_flags={"clue_a": True},
            player_stats={"hp": 50},
            current_turn=10,
        )
        assert result.triggered_win is None
        assert result.triggered_fail is None
        assert len(result.win_progress) == 1
        assert result.win_progress[0].achieved_flags == ["clue_a"]
        assert result.win_progress[0].progress_ratio == pytest.approx(0.5)

    def test_empty_conditions(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """No conditions defined → nothing triggered."""
        result = svc.evaluate(
            win_conditions=[],
            fail_conditions=[],
            current_flags={},
            player_stats={"hp": 100},
            current_turn=1,
        )
        assert result.triggered_win is None
        assert result.triggered_fail is None
        assert result.win_progress == []

    def test_multiple_win_conditions_first_wins(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """First satisfied win condition is returned."""
        win_conditions: list[dict[str, Any]] = [
            {
                "id": "w1",
                "description": "Path A",
                "requiredFlags": ["a"],
            },
            {
                "id": "w2",
                "description": "Path B",
                "requiredFlags": ["b"],
            },
        ]
        result = svc.evaluate(
            win_conditions=win_conditions,
            fail_conditions=[],
            current_flags={"b": True},
            player_stats={"hp": 100},
            current_turn=5,
        )
        assert result.triggered_win is not None
        assert result.triggered_win["id"] == "w2"

    def test_fail_condition_without_condition_key(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """Fail condition without 'condition' key → not triggered."""
        fail_conditions: list[dict[str, Any]] = [
            {"id": "f1", "description": "Broken condition"},
        ]
        result = svc.evaluate(
            win_conditions=[],
            fail_conditions=fail_conditions,
            current_flags={},
            player_stats={"hp": 0},
            current_turn=10,
        )
        assert result.triggered_fail is None


# ---------------------------------------------------------------------------
# Progress prompt generation
# ---------------------------------------------------------------------------


class TestBuildProgressPrompt:
    """Test LLM-facing progress text generation."""

    def test_with_progress(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """Progress prompt should include achieved and missing flags."""
        result = ConditionEvaluationResult(
            triggered_win=None,
            triggered_fail=None,
            win_progress=[
                WinConditionProgress(
                    condition_id="w1",
                    description="Find all clues",
                    required_flags=["clue_a", "clue_b", "clue_c"],
                    achieved_flags=["clue_a"],
                    is_achieved=False,
                    progress_ratio=1 / 3,
                ),
            ],
        )
        prompt = svc.build_progress_prompt(result)
        assert "clue_a" in prompt
        assert "clue_b" in prompt
        assert "1/3" in prompt

    def test_empty_progress(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """No progress → empty string."""
        result = ConditionEvaluationResult(
            triggered_win=None,
            triggered_fail=None,
            win_progress=[],
        )
        prompt = svc.build_progress_prompt(result)
        assert prompt == ""

    def test_triggered_returns_empty(
        self,
        svc: ConditionEvaluationService,
    ) -> None:
        """When a condition is triggered, no progress prompt needed."""
        result = ConditionEvaluationResult(
            triggered_win={"id": "w1", "description": "Win!"},
            triggered_fail=None,
            win_progress=[],
        )
        prompt = svc.build_progress_prompt(result)
        assert prompt == ""
