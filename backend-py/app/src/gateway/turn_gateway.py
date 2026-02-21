from __future__ import annotations

from typing import TYPE_CHECKING

from sqlmodel import select

from domain.entity.models import Turns

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session


class TurnGateway:
    """Gateway for turn database operations."""

    def create(self, session: Session, turn: Turns) -> Turns:
        """Create a new turn record."""
        session.add(turn)
        session.commit()
        session.refresh(turn)
        return turn

    def get_recent(
        self,
        session: Session,
        session_id: uuid.UUID,
        limit: int = 5,
    ) -> list[Turns]:
        """Get recent turns ordered by turn_number descending."""
        statement = (
            select(Turns)
            .where(Turns.session_id == session_id)
            .order_by(Turns.turn_number.desc())
            .limit(limit)
        )
        return list(session.exec(statement).all())
