"""Automatic action resolution service.

Generates a luck roll (1-100) each turn and builds a resolution
context string for injection into the GM prompt.  The LLM uses
the roll-under formula (luck_roll <= stat x modifier) to determine
success/failure without exposing dice mechanics to the player.
"""

from __future__ import annotations

import json
import random
from typing import Any

# Stats that represent capacity/pool rather than action ability.
# Excluded from check-stats to prevent the LLM from using them
# as the basis for a resolution check.
_EXCLUDED_FROM_CHECKS: frozenset[str] = frozenset({"hp", "san", "maxHp", "maxSan"})


class ActionResolutionService:
    """Generates luck rolls and builds resolution context for GM prompts."""

    def generate_luck_factor(self, *, seed: int | None = None) -> int:
        """Return a random integer in [1, 100].

        Args:
            seed: Optional RNG seed for reproducible tests.
        """
        rng = random.Random(seed)  # noqa: S311
        return rng.randint(1, 100)

    def build_resolution_context(
        self,
        player_stats: dict[str, Any],
        luck_roll: int,
    ) -> str:
        """Build the action resolution block for the GM prompt.

        Uses a roll-under system: the LLM picks the most relevant stat,
        chooses a difficulty modifier, computes the threshold
        (stat x modifier), and checks whether luck_roll <= threshold.

        Args:
            player_stats: Current player stats dict (e.g. STR, DEX ...).
            luck_roll: Random value 1-100 for this turn.
        """
        check_stats = {
            k: v for k, v in player_stats.items() if k not in _EXCLUDED_FROM_CHECKS
        }
        stats_json = json.dumps(check_stats, ensure_ascii=False)
        return (
            "# Action Resolution (MANDATORY)\n"
            f"Luck Roll this turn: {luck_roll} (1-100)\n"
            f"Player Stats (for checks): {stats_json}\n\n"
            "Formula (roll-under):\n"
            "  luck_roll <= (stat x modifier) -> SUCCESS\n"
            "  luck_roll >  (stat x modifier) -> FAILURE\n\n"
            "Difficulty modifiers:\n"
            "  easy:      stat x 1.0  (slight risk only)\n"
            "  normal:    stat x 0.8  (default -- most uncertain actions)\n"
            "  hard:      stat x 0.5  (dangerous, skilled, or contested)\n"
            "  very_hard: stat x 0.25 (near-impossible)\n\n"
            "Choose the stat most relevant to the action, then the difficulty.\n"
            "Example: STR=60, hard -> threshold=30."
            " luck_roll(47) <= 30? NO -> FAILURE\n\n"
            "FAILURE is part of the story. When FAILURE occurs, you MUST:\n"
            "1. Narrate the failure vividly and naturally\n"
            "2. Apply negative state_changes.stats_delta proportional to the"
            " situation:\n"
            "   Minor failure -> small penalty (e.g. -1 to -3 on a stat)\n"
            "   Major failure -> significant penalty (e.g. -5 to -10 HP,"
            " item lost,\n"
            "     NPC relationship drops sharply, harmful status effect)\n\n"
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
