"""Turn limit management for game session pacing.

Provides soft limit (convergence promotion) and hard limit (forced ending)
logic to ensure game sessions reach a conclusion within a defined turn count.
"""

from __future__ import annotations

from domain.entity.gm_types import (
    GmDecisionResponse,
    SessionEnd,
    StateChanges,
)

SOFT_LIMIT_WINDOW = 5


class TurnLimitService:
    """Evaluates turn limits and builds limit-related responses."""

    def is_hard_limit_reached(
        self,
        current_turn: int,
        max_turns: int,
    ) -> bool:
        """Return True when the session has reached or exceeded max turns."""
        return current_turn >= max_turns

    def is_soft_limit_active(
        self,
        current_turn: int,
        max_turns: int,
    ) -> bool:
        """Return True when within the convergence window before hard limit."""
        remaining = max_turns - current_turn
        return 1 <= remaining <= SOFT_LIMIT_WINDOW

    def remaining_turns(
        self,
        current_turn: int,
        max_turns: int,
    ) -> int:
        """Return remaining turns, floored at 0."""
        return max(0, max_turns - current_turn)

    def build_hard_limit_response(
        self,
        max_turns: int,
    ) -> GmDecisionResponse:
        """Build a bad-end narration response for hard limit."""
        return GmDecisionResponse(
            decision_type="narrate",
            narration_text=(
                f"――{max_turns}ターンが経過した。"
                "時間切れだ。事態は取り返しのつかない方向へ動き出し、"
                "あなたの冒険はここで幕を閉じる……。"
            ),
            state_changes=StateChanges(
                session_end=SessionEnd(
                    ending_type="bad_end",
                    ending_summary=(
                        f"ターン制限（{max_turns}ターン）に達し、"
                        "目的を達成できないままゲームオーバーとなった。"
                    ),
                ),
            ),
        )

    def build_soft_limit_prompt_addition(
        self,
        remaining: int,
    ) -> str:
        """Build a prompt addition instructing the GM to converge the story."""
        return (
            "\n\n## URGENT: Turn Limit Approaching\n"
            f"Only {remaining} turn(s) remain before the session ends.\n"
            "You MUST begin wrapping up the story:\n"
            "- Guide the narrative toward a climax or resolution.\n"
            "- Evaluate win_conditions and fail_conditions actively.\n"
            "- If win_conditions can still be met, create opportunities.\n"
            "- If win_conditions cannot be met, steer toward a dramatic conclusion.\n"
            "- Avoid introducing new plot threads or characters.\n"
        )
