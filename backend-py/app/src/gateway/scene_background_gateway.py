"""Scene background data access gateway."""

from __future__ import annotations

from typing import TYPE_CHECKING

from sqlmodel import select

from domain.entity.models import SceneBackgrounds

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session


class SceneBackgroundGateway:
    """Gateway for scene_backgrounds read operations."""

    def find_all_by_scenario(
        self,
        session: Session,
        scenario_id: uuid.UUID,
    ) -> list[SceneBackgrounds]:
        """Find all base-asset backgrounds for a scenario."""
        statement = select(SceneBackgrounds).where(
            SceneBackgrounds.scenario_id == scenario_id,
        )
        return list(session.exec(statement).all())

    def find_by_id(
        self,
        session: Session,
        bg_id: uuid.UUID,
    ) -> SceneBackgrounds | None:
        """Find a background by its primary key."""
        statement = select(SceneBackgrounds).where(
            SceneBackgrounds.id == bg_id,
        )
        return session.exec(statement).first()

    def create(
        self,
        session: Session,
        record: SceneBackgrounds,
    ) -> SceneBackgrounds:
        """Insert a new scene background record."""
        session.add(record)
        session.commit()
        session.refresh(record)
        return record
