"""Tests for NpcGateway."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from domain.entity.models import Npcs
from gateway.npc_gateway import NpcGateway

if TYPE_CHECKING:
    from sqlmodel import Session

    from domain.entity.models import NpcRelationships, Sessions


class TestNpcGateway:
    """Tests for NpcGateway operations."""

    def test_get_active_by_session(
        self, db_session: Session, seed_session: Sessions, seed_npc: Npcs
    ) -> None:
        """Verify get_active_by_session returns only active NPCs."""
        gw = NpcGateway()

        result = gw.get_active_by_session(db_session, seed_session.id)

        assert len(result) == 1
        assert result[0].name == "Merchant"
        assert result[0].is_active is True

    def test_get_active_by_session_excludes_inactive(
        self, db_session: Session, seed_session: Sessions, seed_npc: Npcs
    ) -> None:
        """Verify inactive NPCs are excluded from results."""
        gw = NpcGateway()
        seed_npc.is_active = False
        db_session.add(seed_npc)
        db_session.commit()

        result = gw.get_active_by_session(db_session, seed_session.id)

        assert result == []

    def test_get_with_relationship(
        self,
        db_session: Session,
        seed_npc: Npcs,
        seed_npc_relationship: NpcRelationships,
    ) -> None:
        """Verify get_with_relationship returns NPC and relationship tuple."""
        gw = NpcGateway()

        result = gw.get_with_relationship(db_session, seed_npc.id)

        assert result is not None
        npc, rel = result
        assert npc.id == seed_npc.id
        assert rel is not None
        assert rel.affinity == 10

    def test_get_with_relationship_missing_npc(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify get_with_relationship returns None for unknown NPC."""
        gw = NpcGateway()

        result = gw.get_with_relationship(db_session, uuid.uuid4())

        assert result is None

    def test_update_state(self, db_session: Session, seed_npc: Npcs) -> None:
        """Verify update_state overwrites NPC state JSON."""
        gw = NpcGateway()
        new_state = {"mood": "angry", "reason": "robbed"}

        gw.update_state(db_session, seed_npc.id, new_state)

        refreshed = db_session.get(Npcs, seed_npc.id)
        assert refreshed is not None
        assert refreshed.state == new_state

    def test_update_relationship(
        self,
        db_session: Session,
        seed_npc: Npcs,
        seed_npc_relationship: NpcRelationships,
    ) -> None:
        """Verify update_relationship applies deltas correctly."""
        gw = NpcGateway()

        gw.update_relationship(
            db_session,
            seed_npc.id,
            affinity_delta=5,
            trust_delta=-2,
            fear_delta=1,
            debt_delta=3,
        )

        db_session.refresh(seed_npc_relationship)
        assert seed_npc_relationship.affinity == 15
        assert seed_npc_relationship.trust == 3
        assert seed_npc_relationship.fear == 1
        assert seed_npc_relationship.debt == 3
