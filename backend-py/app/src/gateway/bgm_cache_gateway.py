"""BGM cache data access gateway."""

from __future__ import annotations

from typing import TYPE_CHECKING

from sqlmodel import select

from domain.entity.models import Bgm

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session


class BgmCacheGateway:
    """Gateway for bgm table operations."""

    def find_by_scenario_and_mood(
        self,
        session: Session,
        scenario_id: uuid.UUID,
        mood: str,
    ) -> Bgm | None:
        """Find a cached BGM by scenario and mood."""
        statement = (
            select(Bgm)
            .where(
                Bgm.scenario_id == scenario_id,
                Bgm.mood == mood,
            )
            .limit(1)
        )
        return session.exec(statement).first()

    def create(
        self,
        session: Session,
        record: Bgm,
    ) -> Bgm:
        """Insert a bgm record."""
        session.add(record)
        session.commit()
        session.refresh(record)
        return record

    def update(
        self,
        session: Session,
        record: Bgm,
    ) -> Bgm:
        """Update a bgm record."""
        session.add(record)
        session.commit()
        session.refresh(record)
        return record

    def delete(
        self,
        session: Session,
        record: Bgm,
    ) -> None:
        """Delete a bgm record."""
        session.delete(record)
        session.commit()
