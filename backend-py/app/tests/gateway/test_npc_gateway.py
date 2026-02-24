"""Tests for NpcGateway."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from domain.entity.models import NpcRelationships, Npcs
from gateway.npc_gateway import NpcGateway, RelationshipDelta

if TYPE_CHECKING:
    from sqlmodel import Session

    from domain.entity.models import Sessions


class TestNpcGateway:
    """Tests for NpcGateway operations."""

    def test_get_by_session(
        self, db_session: Session, seed_session: Sessions, seed_npc: Npcs
    ) -> None:
        """Verify get_by_session returns all NPCs for the session."""
        gw = NpcGateway()

        result = gw.get_by_session(db_session, seed_session.id)

        assert len(result) == 1
        assert result[0].name == "Merchant"

    def test_create(self, db_session: Session, seed_session: Sessions) -> None:
        """Verify create persists a new NPC record."""
        gw = NpcGateway()
        npc = Npcs(
            id=uuid.uuid4(),
            session_id=seed_session.id,
            name="Guard",
            profile={"role": "guard"},
            goals={"primary": "Guard the gate"},
            state={"mood": "alert"},
            location_x=0,
            location_y=0,
            created_at=seed_session.created_at,
            updated_at=seed_session.updated_at,
        )

        gw.create(db_session, npc)

        result = gw.get_by_session(db_session, seed_session.id)
        assert len(result) == 1
        assert result[0].name == "Guard"

    def test_create_relationship(self, db_session: Session, seed_npc: Npcs) -> None:
        """Verify create_relationship persists a new relationship record."""
        gw = NpcGateway()
        rel = NpcRelationships(
            id=uuid.uuid4(),
            npc_id=seed_npc.id,
            affinity=10,
            trust=5,
            fear=0,
            debt=0,
            flags={},
            created_at=seed_npc.created_at,
            updated_at=seed_npc.updated_at,
        )

        gw.create_relationship(db_session, rel)

        result = gw.get_with_relationship(db_session, seed_npc.id)
        assert result is not None
        _, fetched_rel = result
        assert fetched_rel is not None
        assert fetched_rel.affinity == 10
        assert fetched_rel.trust == 5

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
            RelationshipDelta(
                affinity=5,
                trust=-2,
                fear=1,
                debt=3,
            ),
        )

        db_session.refresh(seed_npc_relationship)
        assert seed_npc_relationship.affinity == 15
        assert seed_npc_relationship.trust == 3
        assert seed_npc_relationship.fear == 1
        assert seed_npc_relationship.debt == 3

    def test_update_location(self, db_session: Session, seed_npc: Npcs) -> None:
        """Verify update_location overwrites NPC coordinates."""
        gw = NpcGateway()

        gw.update_location(db_session, seed_npc.id, 10, 20)

        refreshed = db_session.get(Npcs, seed_npc.id)
        assert refreshed is not None
        assert refreshed.location_x == 10
        assert refreshed.location_y == 20
