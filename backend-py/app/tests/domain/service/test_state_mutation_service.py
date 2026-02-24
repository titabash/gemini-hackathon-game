"""Tests for StateMutationService.

Verifies stats_delta, flag_changes, npc_state_updates,
item_updates, npc_location_changes, and session_end.
"""

from __future__ import annotations

import uuid
from unittest.mock import MagicMock

from src.domain.entity.gm_types import (
    FlagChange,
    ItemUpdate,
    NpcLocationChange,
    NpcStateUpdate,
    SessionEnd,
    StateChanges,
)
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
        svc.pc_gw.get_by_session.return_value = None
        svc.npc_gw.get_by_session.return_value = []
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


class TestApplyStats:
    """Tests for stats_delta application."""

    def test_single_stat_delta(self) -> None:
        """Single stat delta should update that stat."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        pc = MagicMock()
        pc.stats = {"hp": 100, "san": 50}
        svc.pc_gw.get_by_session.return_value = pc

        changes = StateChanges(stats_delta={"hp": -10})
        svc.apply(db, session_id, changes)

        svc.pc_gw.update_stats.assert_called_once()
        updated = svc.pc_gw.update_stats.call_args[0][2]
        assert updated["hp"] == 90
        assert updated["san"] == 50

    def test_multiple_stat_deltas(self) -> None:
        """Multiple stat deltas should all be applied."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        pc = MagicMock()
        pc.stats = {"hp": 100, "san": 50}
        svc.pc_gw.get_by_session.return_value = pc

        changes = StateChanges(stats_delta={"hp": -10, "san": -5})
        svc.apply(db, session_id, changes)

        svc.pc_gw.update_stats.assert_called_once()
        updated = svc.pc_gw.update_stats.call_args[0][2]
        assert updated["hp"] == 90
        assert updated["san"] == 45

    def test_new_stat_key_defaults_zero(self) -> None:
        """Unknown stat key should default to 0 before adding delta."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        pc = MagicMock()
        pc.stats = {"hp": 100}
        svc.pc_gw.get_by_session.return_value = pc

        changes = StateChanges(stats_delta={"mp": 30})
        svc.apply(db, session_id, changes)

        svc.pc_gw.update_stats.assert_called_once()
        updated = svc.pc_gw.update_stats.call_args[0][2]
        assert updated["mp"] == 30
        assert updated["hp"] == 100

    def test_stats_delta_none_no_update(self) -> None:
        """stats_delta=None should not call update_stats."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        svc.pc_gw.get_by_session.return_value = None
        svc.npc_gw.get_by_session.return_value = []
        changes = StateChanges()
        svc.apply(db, session_id, changes)

        svc.pc_gw.update_stats.assert_not_called()


class TestApplyNpcStates:
    """Tests for NPC internal state updates."""

    def test_npc_state_updated(self) -> None:
        """Matching NPC name should trigger update_state."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        npc = MagicMock()
        npc.name = "Guard"
        npc.id = uuid.uuid4()
        svc.npc_gw.get_by_session.return_value = [npc]

        changes = StateChanges(
            npc_state_updates=[
                NpcStateUpdate(
                    npc_name="Guard",
                    state={"mood": "angry"},
                ),
            ],
        )
        svc.apply(db, session_id, changes)

        svc.npc_gw.update_state.assert_called_once_with(db, npc.id, {"mood": "angry"})

    def test_unknown_npc_name_skipped(self) -> None:
        """Unknown NPC name should be silently skipped."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        svc.npc_gw.get_by_session.return_value = []

        changes = StateChanges(
            npc_state_updates=[
                NpcStateUpdate(
                    npc_name="Ghost",
                    state={"visible": True},
                ),
            ],
        )
        svc.apply(db, session_id, changes)

        svc.npc_gw.update_state.assert_not_called()

    def test_multiple_npc_state_updates(self) -> None:
        """Multiple NPC state updates should all be applied."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        npc_a = MagicMock()
        npc_a.name = "Guard"
        npc_a.id = uuid.uuid4()
        npc_b = MagicMock()
        npc_b.name = "Merchant"
        npc_b.id = uuid.uuid4()
        svc.npc_gw.get_by_session.return_value = [npc_a, npc_b]

        changes = StateChanges(
            npc_state_updates=[
                NpcStateUpdate(npc_name="Guard", state={"alert": True}),
                NpcStateUpdate(
                    npc_name="Merchant",
                    state={"shop_open": False},
                ),
            ],
        )
        svc.apply(db, session_id, changes)

        assert svc.npc_gw.update_state.call_count == 2


class TestApplyItemUpdates:
    """Tests for item quantity/equipped updates."""

    def test_quantity_delta_applied(self) -> None:
        """quantity_delta should call update_quantity."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        changes = StateChanges(
            item_updates=[
                ItemUpdate(name="Health Potion", quantity_delta=-1),
            ],
        )
        svc.apply(db, session_id, changes)

        svc.item_gw.update_quantity.assert_called_once_with(
            db, session_id, "Health Potion", -1
        )

    def test_equipped_applied(self) -> None:
        """is_equipped should call update_equipped."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        changes = StateChanges(
            item_updates=[
                ItemUpdate(name="Iron Sword", is_equipped=True),
            ],
        )
        svc.apply(db, session_id, changes)

        svc.item_gw.update_equipped.assert_called_once_with(
            db, session_id, "Iron Sword", is_equipped=True
        )

    def test_both_quantity_and_equipped(self) -> None:
        """Both quantity_delta and is_equipped should be applied."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        changes = StateChanges(
            item_updates=[
                ItemUpdate(
                    name="Shield",
                    quantity_delta=1,
                    is_equipped=True,
                ),
            ],
        )
        svc.apply(db, session_id, changes)

        svc.item_gw.update_quantity.assert_called_once()
        svc.item_gw.update_equipped.assert_called_once()


class TestApplyNpcLocations:
    """Tests for NPC location updates."""

    def test_npc_location_updated(self) -> None:
        """Matching NPC name should trigger update_location."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        npc = MagicMock()
        npc.name = "Guard"
        npc.id = uuid.uuid4()
        svc.npc_gw.get_by_session.return_value = [npc]

        changes = StateChanges(
            npc_location_changes=[
                NpcLocationChange(npc_name="Guard", x=10, y=20),
            ],
        )
        svc.apply(db, session_id, changes)

        svc.npc_gw.update_location.assert_called_once_with(db, npc.id, 10, 20)

    def test_unknown_npc_skipped(self) -> None:
        """Unknown NPC name should be silently skipped."""
        svc = _make_svc()
        session_id = uuid.uuid4()
        db = MagicMock()

        svc.npc_gw.get_by_session.return_value = []

        changes = StateChanges(
            npc_location_changes=[
                NpcLocationChange(npc_name="Ghost", x=5, y=5),
            ],
        )
        svc.apply(db, session_id, changes)

        svc.npc_gw.update_location.assert_not_called()


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
