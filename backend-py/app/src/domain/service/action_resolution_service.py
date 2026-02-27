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
        stat_names = ", ".join(player_stats.keys()) if player_stats else "(no stats)"
        return (
            "# Action Resolution (MANDATORY)\n"
            f"Luck Factor this turn: {luck_factor}\n"
            f"Player Stats: {stats_json}\n"
            f"Available stats for checks: {stat_names}\n\n"
            "You MUST resolve EVERY uncertain action using this formula:\n"
            "  most_relevant_stat + luck_factor vs difficulty_threshold\n"
            "Choose the player stat most relevant to the attempted action.\n\n"
            "Difficulty thresholds (default to 15 — err on the harder side):\n"
            "  10=easy, 15=normal (default), 20=hard, 25=very hard\n"
            "  stat + luck_factor >= difficulty → SUCCESS\n"
            "  stat + luck_factor <  difficulty → FAILURE\n\n"
            "FAILURE GUIDELINES:\n"
            "- Narrate the failure vividly and naturally\n"
            "- Apply negative state_changes proportional to the situation:\n"
            "  Minor failure → small penalty (-1 to -3 stat)\n"
            "  Major failure → significant penalty (-5 to -10 HP, item lost,\n"
            "    NPC relationship drop, harmful status effect)\n"
            "- Failure should create interesting complications,\n"
            "  not just 'nothing happens'\n\n"
            "WHAT REQUIRES A CHECK (always):\n"
            "- Combat, persuasion, stealth, magic, acrobatics\n"
            "- Lockpicking, crafting, investigation\n"
            "- Any action an NPC would resist or oppose\n"
            "- Any action with risk of harm or consequences\n\n"
            "WHAT SKIPS A CHECK (no roll needed):\n"
            "- Walking, looking around, casual conversation\n"
            "- Using items in inventory normally\n"
            "- Opening unlocked doors, reading signs\n\n"
            "NEVER mention dice, numbers, or mechanics in narration.\n"
            "Describe outcomes purely through storytelling."
        )
