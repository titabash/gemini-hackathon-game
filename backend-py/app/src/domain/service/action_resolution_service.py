"""Automatic action resolution service.

Generates a luck factor (1-20) each turn and builds a resolution
context string for injection into the GM prompt.  The LLM uses
player stats + luck factor to determine success/failure without
exposing dice mechanics to the player.
"""

from __future__ import annotations

import json
import random
from typing import Any


class ActionResolutionService:
    """Generates luck values and builds resolution context for GM prompts."""

    def generate_luck_factor(self, *, seed: int | None = None) -> int:
        """Return a random integer in [1, 20].

        Args:
            seed: Optional RNG seed for reproducible tests.
        """
        rng = random.Random(seed)  # noqa: S311
        return rng.randint(1, 20)

    def build_resolution_context(
        self,
        player_stats: dict[str, Any],
        luck_factor: int,
    ) -> str:
        """Build the action resolution block for the GM prompt.

        Args:
            player_stats: Current player stats dict (e.g. STR, DEX …).
            luck_factor: Random value 1-20 for this turn.
        """
        stats_json = json.dumps(player_stats, ensure_ascii=False)
        return (
            "# Action Resolution\n"
            f"Luck Factor this turn: {luck_factor}\n"
            f"Player Stats: {stats_json}\n"
            "When the player attempts an action with uncertain outcome, "
            "determine success or failure using:\n"
            "- Physical actions: STR or DEX + luck_factor\n"
            "- Mental actions: INT or WIS + luck_factor\n"
            "- Social actions: CHA + luck_factor\n"
            "Difficulty thresholds: 10=easy, 15=normal, 20=hard, 25=very hard\n"
            "stat + luck_factor >= difficulty -> SUCCESS\n"
            "stat + luck_factor < difficulty -> FAILURE\n"
            "Narrate results naturally WITHOUT mentioning dice, numbers, or luck.\n"
            "Reflect outcomes in state_changes (e.g. HP loss on combat failure).\n"
            "Routine tasks always succeed without a check."
        )
