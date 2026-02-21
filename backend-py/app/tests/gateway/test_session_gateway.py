"""Tests for SessionGateway."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from domain.entity.models import Sessions
from gateway.session_gateway import SessionGateway

if TYPE_CHECKING:
    from sqlmodel import Session


class TestSessionGateway:
    """Tests for SessionGateway operations."""

    def test_get_by_id_returns_session(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify get_by_id returns the matching session."""
        gw = SessionGateway()

        result = gw.get_by_id(db_session, seed_session.id)

        assert result is not None
        assert result.id == seed_session.id
        assert result.status == "active"

    def test_get_by_id_returns_none_for_missing(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify get_by_id returns None when session does not exist."""
        gw = SessionGateway()

        result = gw.get_by_id(db_session, uuid.uuid4())

        assert result is None

    def test_update_state(self, db_session: Session, seed_session: Sessions) -> None:
        """Verify update_state overwrites current_state JSON."""
        gw = SessionGateway()
        new_state = {"phase": "combat", "round": 1}

        gw.update_state(db_session, seed_session.id, new_state)

        refreshed = db_session.get(Sessions, seed_session.id)
        assert refreshed is not None
        assert refreshed.current_state == new_state

    def test_increment_turn(self, db_session: Session, seed_session: Sessions) -> None:
        """Verify increment_turn returns new turn number."""
        gw = SessionGateway()

        new_turn = gw.increment_turn(db_session, seed_session.id)

        assert new_turn == 1
        refreshed = db_session.get(Sessions, seed_session.id)
        assert refreshed is not None
        assert refreshed.current_turn_number == 1

    def test_update_status(self, db_session: Session, seed_session: Sessions) -> None:
        """Verify update_status changes status and ending fields."""
        gw = SessionGateway()

        gw.update_status(
            db_session,
            seed_session.id,
            status="completed",
            ending_type="victory",
            ending_summary="The hero escaped the forest.",
        )

        refreshed = db_session.get(Sessions, seed_session.id)
        assert refreshed is not None
        assert refreshed.status == "completed"
        assert refreshed.ending_type == "victory"
        assert refreshed.ending_summary == "The hero escaped the forest."
