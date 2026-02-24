from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from sqlmodel import select

from domain.entity.models import NpcRelationships, Npcs

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session


@dataclass(frozen=True)
class RelationshipDelta:
    """Delta values for NPC relationship updates."""

    affinity: int = 0
    trust: int = 0
    fear: int = 0
    debt: int = 0


class NpcGateway:
    """Gateway for NPC database operations."""

    def get_by_session(
        self,
        session: Session,
        session_id: uuid.UUID,
    ) -> list[Npcs]:
        """Get all NPCs for a session."""
        statement = select(Npcs).where(
            Npcs.session_id == session_id,
        )
        return list(session.exec(statement).all())

    def create(
        self,
        session: Session,
        npc: Npcs,
    ) -> None:
        """Persist a new NPC record."""
        session.add(npc)
        session.commit()
        session.refresh(npc)

    def create_relationship(
        self,
        session: Session,
        rel: NpcRelationships,
    ) -> None:
        """Persist a new NPC relationship record."""
        session.add(rel)
        session.commit()
        session.refresh(rel)

    def get_by_scenario(
        self,
        session: Session,
        scenario_id: uuid.UUID,
    ) -> list[Npcs]:
        """Get all NPCs defined at the scenario level."""
        statement = select(Npcs).where(
            Npcs.scenario_id == scenario_id,
        )
        return list(session.exec(statement).all())

    def get_with_relationship(
        self,
        session: Session,
        npc_id: uuid.UUID,
    ) -> tuple[Npcs, NpcRelationships | None] | None:
        """Get an NPC with its relationship data."""
        npc_stmt = select(Npcs).where(Npcs.id == npc_id)
        npc = session.exec(npc_stmt).first()
        if npc is None:
            return None
        rel_stmt = select(NpcRelationships).where(
            NpcRelationships.npc_id == npc_id,
        )
        rel = session.exec(rel_stmt).first()
        return (npc, rel)

    def update_state(
        self,
        session: Session,
        npc_id: uuid.UUID,
        state: dict[str, object],
    ) -> None:
        """Update the state of an NPC."""
        statement = select(Npcs).where(Npcs.id == npc_id)
        record = session.exec(statement).first()
        if record is None:
            msg = f"NPC {npc_id} not found"
            raise ValueError(msg)
        record.state = state
        session.add(record)
        session.commit()
        session.refresh(record)

    def update_location(
        self,
        session: Session,
        npc_id: uuid.UUID,
        x: int,
        y: int,
    ) -> None:
        """Update the location of an NPC."""
        statement = select(Npcs).where(Npcs.id == npc_id)
        record = session.exec(statement).first()
        if record is None:
            msg = f"NPC {npc_id} not found"
            raise ValueError(msg)
        record.location_x = x
        record.location_y = y
        session.add(record)
        session.commit()
        session.refresh(record)

    def find_by_name_and_session(
        self,
        session: Session,
        session_id: uuid.UUID,
        name: str,
    ) -> Npcs | None:
        """Find an NPC by name within a session."""
        statement = select(Npcs).where(
            Npcs.session_id == session_id,
            Npcs.name == name,
        )
        return session.exec(statement).first()

    def update_image_path(
        self,
        session: Session,
        npc_id: uuid.UUID,
        image_path: str,
    ) -> None:
        """Set the default image_path for an NPC."""
        statement = select(Npcs).where(Npcs.id == npc_id)
        record = session.exec(statement).first()
        if record is None:
            msg = f"NPC {npc_id} not found"
            raise ValueError(msg)
        record.image_path = image_path
        session.add(record)
        session.commit()

    def update_emotion_image(
        self,
        session: Session,
        npc_id: uuid.UUID,
        emotion: str,
        image_path: str,
    ) -> None:
        """Add or update a single emotion image entry."""
        statement = select(Npcs).where(Npcs.id == npc_id)
        record = session.exec(statement).first()
        if record is None:
            msg = f"NPC {npc_id} not found"
            raise ValueError(msg)
        images = dict(record.emotion_images or {})
        images[emotion] = image_path
        record.emotion_images = images
        session.add(record)
        session.commit()

    def update_relationship(
        self,
        session: Session,
        npc_id: uuid.UUID,
        delta: RelationshipDelta,
    ) -> None:
        """Increment relationship values by the given deltas."""
        statement = select(NpcRelationships).where(
            NpcRelationships.npc_id == npc_id,
        )
        record = session.exec(statement).first()
        if record is None:
            msg = f"NpcRelationship for NPC {npc_id} not found"
            raise ValueError(msg)
        record.affinity = int(record.affinity) + delta.affinity
        record.trust = int(record.trust) + delta.trust
        record.fear = int(record.fear) + delta.fear
        record.debt = int(record.debt) + delta.debt
        session.add(record)
        session.commit()
        session.refresh(record)
