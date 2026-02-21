"""Tests for ScenarioGateway."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from gateway.scenario_gateway import ScenarioGateway

if TYPE_CHECKING:
    from sqlmodel import Session

    from domain.entity.models import Scenarios


class TestScenarioGateway:
    """Tests for ScenarioGateway operations."""

    def test_get_by_id_returns_scenario(
        self, db_session: Session, seed_scenario: Scenarios
    ) -> None:
        """Verify get_by_id returns the matching scenario."""
        gw = ScenarioGateway()

        result = gw.get_by_id(db_session, seed_scenario.id)

        assert result is not None
        assert result.id == seed_scenario.id
        assert result.title == "Dark Forest Adventure"

    def test_get_by_id_returns_none_for_missing(
        self, db_session: Session, seed_scenario: Scenarios
    ) -> None:
        """Verify get_by_id returns None when scenario does not exist."""
        gw = ScenarioGateway()

        result = gw.get_by_id(db_session, uuid.uuid4())

        assert result is None
