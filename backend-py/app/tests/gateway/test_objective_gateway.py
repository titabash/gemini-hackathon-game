"""Tests for ObjectiveGateway."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from domain.entity.models import Objectives
from gateway.objective_gateway import ObjectiveGateway
from tests.gateway.conftest import _now

if TYPE_CHECKING:
    from sqlmodel import Session

    from domain.entity.models import Sessions


class TestObjectiveGateway:
    """Tests for ObjectiveGateway operations."""

    def test_get_active_by_session(
        self,
        db_session: Session,
        seed_session: Sessions,
        seed_objective: Objectives,
    ) -> None:
        """Verify get_active_by_session returns active objectives."""
        gw = ObjectiveGateway()

        result = gw.get_active_by_session(db_session, seed_session.id)

        assert len(result) == 1
        assert result[0].title == "Find the Exit"
        assert result[0].status == "active"

    def test_get_active_by_session_empty(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify get_active_by_session returns empty when none exist."""
        gw = ObjectiveGateway()

        result = gw.get_active_by_session(db_session, seed_session.id)

        assert result == []

    def test_create_persists_objective(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify create persists a new objective."""
        gw = ObjectiveGateway()
        obj = Objectives(
            id=uuid.uuid4(),
            session_id=seed_session.id,
            title="Defeat the Boss",
            description="Find and defeat the forest guardian.",
            status="active",
            sort_order=2,
            created_at=_now(),
            updated_at=_now(),
        )

        result = gw.create(db_session, obj)

        assert result.title == "Defeat the Boss"
        assert result.status == "active"

    def test_update_status(
        self,
        db_session: Session,
        seed_session: Sessions,
        seed_objective: Objectives,
    ) -> None:
        """Verify update_status changes objective status."""
        gw = ObjectiveGateway()

        gw.update_status(
            db_session,
            seed_session.id,
            title="Find the Exit",
            status="completed",
        )

        refreshed = db_session.get(Objectives, seed_objective.id)
        assert refreshed is not None
        assert refreshed.status == "completed"
