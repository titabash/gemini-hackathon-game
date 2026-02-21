from __future__ import annotations

from typing import TYPE_CHECKING

from sqlmodel import select

from domain.entity.models import PlayerCharacters

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session


class PlayerCharacterGateway:
    """Gateway for player character database operations."""

    def get_by_session(
        self,
        session: Session,
        session_id: uuid.UUID,
    ) -> PlayerCharacters | None:
        """Get the player character for a session."""
        statement = select(PlayerCharacters).where(
            PlayerCharacters.session_id == session_id,
        )
        return session.exec(statement).first()

    def update_stats(
        self,
        session: Session,
        pc_id: uuid.UUID,
        stats: dict[str, object],
    ) -> None:
        """Update the stats of a player character."""
        record = self._get_by_id(session, pc_id)
        record.stats = stats
        session.add(record)
        session.commit()
        session.refresh(record)

    def update_location(
        self,
        session: Session,
        pc_id: uuid.UUID,
        x: int,
        y: int,
    ) -> None:
        """Update the location of a player character."""
        record = self._get_by_id(session, pc_id)
        record.location_x = x
        record.location_y = y
        session.add(record)
        session.commit()
        session.refresh(record)

    def update_status_effects(
        self,
        session: Session,
        pc_id: uuid.UUID,
        status_effects: list[object],
    ) -> None:
        """Update the status effects of a player character."""
        record = self._get_by_id(session, pc_id)
        record.status_effects = status_effects
        session.add(record)
        session.commit()
        session.refresh(record)

    @staticmethod
    def _get_by_id(
        session: Session,
        pc_id: uuid.UUID,
    ) -> PlayerCharacters:
        """Get a player character by ID or raise ValueError."""
        statement = select(PlayerCharacters).where(
            PlayerCharacters.id == pc_id,
        )
        record = session.exec(statement).first()
        if record is None:
            msg = f"PlayerCharacter {pc_id} not found"
            raise ValueError(msg)
        return record
