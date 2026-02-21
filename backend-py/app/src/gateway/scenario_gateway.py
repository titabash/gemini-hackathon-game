"""Scenario data access gateway."""

from __future__ import annotations

from typing import TYPE_CHECKING

from sqlmodel import select

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session

from domain.entity.models import Scenarios


class ScenarioGateway:
    """Gateway for scenario read operations."""

    def get_by_id(
        self,
        session: Session,
        scenario_id: uuid.UUID,
    ) -> Scenarios | None:
        statement = select(Scenarios).where(Scenarios.id == scenario_id)
        return session.exec(statement).first()
