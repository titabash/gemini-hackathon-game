"""Turn limit management for game session pacing.

Provides soft limit (convergence promotion) and hard limit (forced ending)
logic to ensure game sessions reach a conclusion within a defined turn count.
"""

from __future__ import annotations

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

    def build_hard_limit_prompt_addition(
        self,
        max_turns: int,
    ) -> str:
        """Build a prompt addition for the final turn at hard limit.

        Instead of generating a canned response, this instructs the GM
        to write a narrative conclusion as the last turn.
        """
        return (
            "\n\n## FINAL TURN — HARD LIMIT REACHED (CRITICAL)\n"
            f"The session has reached its maximum of {max_turns} turns.\n"
            "This is the LAST turn. You MUST:\n"
            "1. Write a narrative ending that concludes the story in context.\n"
            "2. Include session_end in state_changes with an appropriate "
            "ending_type (victory, bad_end, or normal_end).\n"
            "3. The ending must feel like a natural story conclusion, "
            "not an abrupt cutoff.\n"
            "4. Reflect the current situation: if the player was winning, "
            "give a bittersweet or victorious ending; if losing, "
            "a dramatic defeat.\n"
            "5. Do NOT present choices — this is the final narration.\n"
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
