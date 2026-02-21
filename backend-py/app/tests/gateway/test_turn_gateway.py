"""Tests for TurnGateway."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from domain.entity.models import Turns
from gateway.turn_gateway import TurnGateway
from tests.gateway.conftest import _now

if TYPE_CHECKING:
    from sqlmodel import Session

    from domain.entity.models import Sessions


class TestTurnGateway:
    """Tests for TurnGateway operations."""

    def test_create_persists_turn(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify create persists a turn and returns it."""
        gw = TurnGateway()
        turn = Turns(
            id=uuid.uuid4(),
            session_id=seed_session.id,
            turn_number=1,
            input_type="do",
            input_text="Open the chest",
            gm_decision_type="narrate",
            output={"narrative": "You opened the chest."},
            created_at=_now(),
        )

        result = gw.create(db_session, turn)

        assert result.id == turn.id
        assert result.turn_number == 1
        assert result.input_type == "do"

    def test_get_recent_returns_ordered_turns(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify get_recent returns turns in descending order."""
        gw = TurnGateway()
        for i in range(1, 4):
            turn = Turns(
                id=uuid.uuid4(),
                session_id=seed_session.id,
                turn_number=i,
                input_type="say",
                input_text=f"Turn {i}",
                gm_decision_type="narrate",
                output={"text": f"Response {i}"},
                created_at=_now(),
            )
            gw.create(db_session, turn)

        recent = gw.get_recent(db_session, seed_session.id, limit=2)

        assert len(recent) == 2
        assert recent[0].turn_number > recent[1].turn_number

    def test_get_recent_empty_session(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify get_recent returns empty list for session with no turns."""
        gw = TurnGateway()

        recent = gw.get_recent(db_session, seed_session.id)

        assert recent == []
