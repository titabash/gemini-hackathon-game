from __future__ import annotations

from typing import TYPE_CHECKING

from sqlmodel import select

from domain.entity.models import Sessions

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session


class SessionGateway:
    """Gateway for session database operations."""

    def get_by_id(
        self,
        session: Session,
        session_id: uuid.UUID,
    ) -> Sessions | None:
        """Get a session by its ID."""
        statement = select(Sessions).where(Sessions.id == session_id)
        return session.exec(statement).first()

    def update_state(
        self,
        session: Session,
        session_id: uuid.UUID,
        state: dict[str, object],
    ) -> None:
        """Update the current state of a session."""
        record = self.get_by_id(session, session_id)
        if record is None:
            msg = f"Session {session_id} not found"
            raise ValueError(msg)
        record.current_state = state
        session.add(record)
        session.commit()
        session.refresh(record)

    def increment_turn(
        self,
        session: Session,
        session_id: uuid.UUID,
    ) -> int:
        """Increment the turn number and return the new value."""
        record = self.get_by_id(session, session_id)
        if record is None:
            msg = f"Session {session_id} not found"
            raise ValueError(msg)
        record.current_turn_number += 1
        session.add(record)
        session.commit()
        session.refresh(record)
        return int(record.current_turn_number)

    def update_status(
        self,
        session: Session,
        session_id: uuid.UUID,
        status: str,
        ending_type: str | None = None,
        ending_summary: str | None = None,
    ) -> None:
        """Update the status of a session."""
        record = self.get_by_id(session, session_id)
        if record is None:
            msg = f"Session {session_id} not found"
            raise ValueError(msg)
        record.status = status
        record.ending_type = ending_type
        record.ending_summary = ending_summary
        session.add(record)
        session.commit()
        session.refresh(record)
