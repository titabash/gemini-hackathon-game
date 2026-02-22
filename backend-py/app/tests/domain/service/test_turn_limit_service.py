"""Tests for TurnLimitService.

Validates hard/soft limit detection, remaining turn calculation,
and response/prompt generation for turn-based game ending.
"""

from src.domain.service.turn_limit_service import TurnLimitService


class TestIsHardLimitReached:
    """Tests for hard limit boundary detection."""

    def test_below_limit(self) -> None:
        """Should return False when current turn is below max."""
        svc = TurnLimitService()
        assert svc.is_hard_limit_reached(29, 30) is False

    def test_at_limit(self) -> None:
        """Should return True when current turn equals max."""
        svc = TurnLimitService()
        assert svc.is_hard_limit_reached(30, 30) is True

    def test_above_limit(self) -> None:
        """Should return True when current turn exceeds max."""
        svc = TurnLimitService()
        assert svc.is_hard_limit_reached(31, 30) is True

    def test_first_turn(self) -> None:
        """Should return False on first turn."""
        svc = TurnLimitService()
        assert svc.is_hard_limit_reached(1, 30) is False

    def test_zero_turn(self) -> None:
        """Should return False at turn 0."""
        svc = TurnLimitService()
        assert svc.is_hard_limit_reached(0, 30) is False


class TestIsSoftLimitActive:
    """Tests for soft limit (convergence zone) detection."""

    def test_not_active_early(self) -> None:
        """Should return False when far from limit."""
        svc = TurnLimitService()
        assert svc.is_soft_limit_active(20, 30) is False

    def test_active_at_boundary(self) -> None:
        """Should return True when exactly 5 turns remain."""
        svc = TurnLimitService()
        assert svc.is_soft_limit_active(25, 30) is True

    def test_active_near_end(self) -> None:
        """Should return True when 1 turn remains."""
        svc = TurnLimitService()
        assert svc.is_soft_limit_active(29, 30) is True

    def test_not_active_at_hard_limit(self) -> None:
        """Should return False at hard limit (hard limit takes precedence)."""
        svc = TurnLimitService()
        assert svc.is_soft_limit_active(30, 30) is False

    def test_not_active_beyond_limit(self) -> None:
        """Should return False beyond hard limit."""
        svc = TurnLimitService()
        assert svc.is_soft_limit_active(31, 30) is False

    def test_six_turns_remaining(self) -> None:
        """Should return False when 6 turns remain."""
        svc = TurnLimitService()
        assert svc.is_soft_limit_active(24, 30) is False


class TestRemainingTurns:
    """Tests for remaining turns calculation."""

    def test_normal(self) -> None:
        """Should return positive remaining count."""
        svc = TurnLimitService()
        assert svc.remaining_turns(25, 30) == 5

    def test_at_limit(self) -> None:
        """Should return 0 at the limit."""
        svc = TurnLimitService()
        assert svc.remaining_turns(30, 30) == 0

    def test_beyond_limit(self) -> None:
        """Should return 0 beyond the limit (not negative)."""
        svc = TurnLimitService()
        assert svc.remaining_turns(35, 30) == 0

    def test_first_turn(self) -> None:
        """Should return max_turns - 1 on first turn."""
        svc = TurnLimitService()
        assert svc.remaining_turns(1, 30) == 29


class TestBuildHardLimitResponse:
    """Tests for bad-end response generation."""

    def test_response_type(self) -> None:
        """Should return a valid GmDecisionResponse."""
        svc = TurnLimitService()
        resp = svc.build_hard_limit_response(30)
        assert type(resp).__name__ == "GmDecisionResponse"

    def test_decision_type_is_narrate(self) -> None:
        """Should use narrate decision type."""
        svc = TurnLimitService()
        resp = svc.build_hard_limit_response(30)
        assert resp.decision_type == "narrate"

    def test_has_bad_end(self) -> None:
        """Should set session_end with bad_end ending type."""
        svc = TurnLimitService()
        resp = svc.build_hard_limit_response(30)
        assert resp.state_changes is not None
        assert resp.state_changes.session_end is not None
        assert resp.state_changes.session_end.ending_type == "bad_end"

    def test_narration_mentions_turns(self) -> None:
        """Should include turn count in narration text."""
        svc = TurnLimitService()
        resp = svc.build_hard_limit_response(30)
        assert "30" in resp.narration_text

    def test_ending_summary_present(self) -> None:
        """Should have non-empty ending summary."""
        svc = TurnLimitService()
        resp = svc.build_hard_limit_response(30)
        assert resp.state_changes.session_end.ending_summary != ""


class TestBuildSoftLimitPromptAddition:
    """Tests for convergence prompt generation."""

    def test_includes_remaining_turns(self) -> None:
        """Should mention the remaining turn count."""
        svc = TurnLimitService()
        addition = svc.build_soft_limit_prompt_addition(3)
        assert "3" in addition

    def test_not_empty(self) -> None:
        """Should return non-empty string."""
        svc = TurnLimitService()
        addition = svc.build_soft_limit_prompt_addition(5)
        assert len(addition) > 0

    def test_one_turn_remaining(self) -> None:
        """Should work with 1 turn remaining."""
        svc = TurnLimitService()
        addition = svc.build_soft_limit_prompt_addition(1)
        assert "1" in addition
