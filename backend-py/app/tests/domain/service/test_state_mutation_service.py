"""Tests for StateMutationService flag persistence and session end.

Verifies flag_changes are applied to current_state.flags,
and apply_session_end can be called independently.
"""

from __future__ import annotations

import uuid
from unittest.mock import MagicMock

from src.domain.entity.gm_types import FlagChange, SessionEnd, StateChanges
from src.domain.service.state_mutation_service import StateMutationService


def _make_svc() -> StateMutationService:
    """Create service with mocked gateways."""
    svc = StateMutationService()
    svc.pc_gw = MagicMock()
    svc.item_gw = MagicMock()
    svc.npc_gw = MagicMock()
    svc.objective_gw = MagicMock()
    svc.session_gw = MagicMock()
    return svc


def _fake_session(
    *,
    current_state: dict[str, object] | None = None,
) -> MagicMock:
    sess = MagicMock()
    sess.current_state = current_state or {}
    return sess


class TestApplyFlags:
    """Tests for flag persistence in current_state."""

    def test_flag_set_true(self) -> None:
        """Setting a flag to True → stored in current_state.flags."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        sess = _fake_session()
        svc.session_gw.get_by_id.return_value = sess

        changes = StateChanges(
            flag_changes=[FlagChange(flag_id="found_secret", value=True)],
        )
        svc.apply(db, session_id, changes)

        svc.session_gw.update_state.assert_called_once()
        call_args = svc.session_gw.update_state.call_args
        updated_state = call_args[0][2]
        assert updated_state["flags"]["found_secret"] is True

    def test_flag_set_false_removes(self) -> None:
        """Setting a flag to False → removed from flags dict."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        sess = _fake_session(
            current_state={"flags": {"old_flag": True, "keep": True}},
        )
        svc.session_gw.get_by_id.return_value = sess

        changes = StateChanges(
            flag_changes=[FlagChange(flag_id="old_flag", value=False)],
        )
        svc.apply(db, session_id, changes)

        svc.session_gw.update_state.assert_called_once()
        call_args = svc.session_gw.update_state.call_args
        updated_state = call_args[0][2]
        assert "old_flag" not in updated_state["flags"]
        assert updated_state["flags"]["keep"] is True

    def test_flag_changes_none_no_update(self) -> None:
        """flag_changes=None → no state update call."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        changes = StateChanges()
        # Still need to mock pc_gw for hp etc.
        svc.pc_gw.get_by_session.return_value = None
        svc.npc_gw.get_active_by_session.return_value = []
        svc.apply(db, session_id, changes)

        svc.session_gw.update_state.assert_not_called()

    def test_multiple_flag_changes(self) -> None:
        """Multiple flags set in one turn."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        sess = _fake_session(
            current_state={"flags": {"existing": True}},
        )
        svc.session_gw.get_by_id.return_value = sess

        changes = StateChanges(
            flag_changes=[
                FlagChange(flag_id="new_a", value=True),
                FlagChange(flag_id="new_b", value=True),
                FlagChange(flag_id="existing", value=False),
            ],
        )
        svc.apply(db, session_id, changes)

        call_args = svc.session_gw.update_state.call_args
        updated_state = call_args[0][2]
        assert updated_state["flags"]["new_a"] is True
        assert updated_state["flags"]["new_b"] is True
        assert "existing" not in updated_state["flags"]


class TestApplySessionEnd:
    """Tests for apply_session_end public method."""

    def test_apply_session_end_victory(self) -> None:
        """apply_session_end should call session_gw.update_status."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        end = SessionEnd(
            ending_type="victory",
            ending_summary="The hero won!",
        )
        svc.apply_session_end(db, session_id, end)

        svc.session_gw.update_status.assert_called_once_with(
            db,
            session_id,
            status="completed",
            ending_type="victory",
            ending_summary="The hero won!",
        )

    def test_apply_session_end_bad_end(self) -> None:
        """apply_session_end with bad_end type."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        end = SessionEnd(
            ending_type="bad_end",
            ending_summary="The hero fell.",
        )
        svc.apply_session_end(db, session_id, end)

        svc.session_gw.update_status.assert_called_once_with(
            db,
            session_id,
            status="completed",
            ending_type="bad_end",
            ending_summary="The hero fell.",
        )
