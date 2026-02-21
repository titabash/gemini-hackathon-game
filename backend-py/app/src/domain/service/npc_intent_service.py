"""NPC context builder for GM prompt."""

from __future__ import annotations

import json
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from domain.entity.models import NpcRelationships, Npcs


class NpcIntentService:
    """Build NPC section text for GM prompt."""

    def build_npc_context(
        self,
        npcs_with_relationships: list[tuple[Npcs, NpcRelationships | None]],
    ) -> str:
        """Format NPC data for inclusion in GM prompt."""
        lines = []
        for npc, rel in npcs_with_relationships:
            rel_str = self._format_relationship(rel)
            lines.append(
                f"## {npc.name}\n"
                f"Profile: {json.dumps(npc.profile)}\n"
                f"Goals: {json.dumps(npc.goals)}\n"
                f"State: {json.dumps(npc.state)}\n"
                f"Location: ({npc.location_x}, {npc.location_y})\n"
                f"Relationship: {rel_str}",
            )
        return "\n\n".join(lines)

    @staticmethod
    def _format_relationship(rel: NpcRelationships | None) -> str:
        if rel is None:
            return "None"
        return (
            f"affinity={rel.affinity} trust={rel.trust} fear={rel.fear} debt={rel.debt}"
        )
