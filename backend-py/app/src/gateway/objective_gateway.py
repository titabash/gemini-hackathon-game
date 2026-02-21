from __future__ import annotations

from typing import TYPE_CHECKING

from sqlmodel import select

from domain.entity.models import Objectives

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session


class ObjectiveGateway:
    """Gateway for objective database operations."""

    def get_active_by_session(
        self,
        session: Session,
        session_id: uuid.UUID,
    ) -> list[Objectives]:
        """Get all active objectives for a session."""
        statement = select(Objectives).where(
            Objectives.session_id == session_id,
            Objectives.status == "active",
        )
        return list(session.exec(statement).all())

    def create(
        self,
        session: Session,
        objective: Objectives,
    ) -> Objectives:
        """Create a new objective record."""
        session.add(objective)
        session.commit()
        session.refresh(objective)
        return objective

    def update_status(
        self,
        session: Session,
        session_id: uuid.UUID,
        title: str,
        status: str,
    ) -> None:
        """Update the status of an objective by session and title."""
        statement = select(Objectives).where(
            Objectives.session_id == session_id,
            Objectives.title == title,
        )
        record = session.exec(statement).first()
        if record is None:
            msg = f"Objective '{title}' not found"
            raise ValueError(msg)
        record.status = status
        session.add(record)
        session.commit()
        session.refresh(record)
