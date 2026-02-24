"""Clone scenario-level NPCs into session-scoped copies.

On game start, each template NPC defined at the scenario level is
duplicated with a fresh UUID so that state and relationship mutations
are isolated per session.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import TYPE_CHECKING, Any

from domain.entity.models import NpcRelationships, Npcs
from gateway.npc_gateway import NpcGateway

if TYPE_CHECKING:
    from sqlmodel import Session


class NpcCloneService:
    """Clones scenario NPCs into a session for independent state."""

    def __init__(self) -> None:
        self.npc_gw = NpcGateway()

    def clone_npcs_for_session(
        self,
        db: Session,
        scenario_id: uuid.UUID,
        session_id: uuid.UUID,
        initial_state: dict[str, Any],
    ) -> None:
        """Clone all scenario NPCs to the given session.

        Idempotent: if the session already has NPCs, this is a no-op.
        """
        existing = self.npc_gw.get_by_session(db, session_id)
        if existing:
            return

        templates = self.npc_gw.get_by_scenario(db, scenario_id)
        if not templates:
            return

        rel_map = _build_relationship_map(initial_state)
        now = datetime.now(UTC)

        for tmpl in templates:
            new_id = uuid.uuid4()
            cloned = Npcs(
                id=new_id,
                session_id=session_id,
                scenario_id=None,
                name=tmpl.name,
                profile=tmpl.profile,
                goals=tmpl.goals,
                state=tmpl.state,
                location_x=tmpl.location_x,
                location_y=tmpl.location_y,
                image_path=tmpl.image_path,
                emotion_images=tmpl.emotion_images,
                created_at=now,
                updated_at=now,
            )
            self.npc_gw.create(db, cloned)

            rel_data = rel_map.get(tmpl.name, {})
            rel = NpcRelationships(
                id=uuid.uuid4(),
                npc_id=new_id,
                affinity=int(rel_data.get("affinity", 0)),
                trust=int(rel_data.get("trust", 0)),
                fear=int(rel_data.get("fear", 0)),
                debt=int(rel_data.get("debt", 0)),
                flags=dict(rel_data.get("flags", {})),
                created_at=now,
                updated_at=now,
            )
            self.npc_gw.create_relationship(db, rel)


def _build_relationship_map(
    initial_state: dict[str, Any],
) -> dict[str, dict[str, Any]]:
    """Build name -> relationship dict from initial_state.npcs."""
    result: dict[str, dict[str, Any]] = {}
    for npc_data in initial_state.get("npcs", []):
        name = npc_data.get("name")
        rel = npc_data.get("relationship")
        if name and rel:
            result[name] = dict(rel)
    return result
