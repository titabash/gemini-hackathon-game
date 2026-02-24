"""Tests for NpcCloneService.

Verifies that scenario NPCs are cloned to session-level NPCs
with independent relationships on game start.
"""

from __future__ import annotations

import uuid
from typing import Any
from unittest.mock import MagicMock

from domain.entity.models import NpcRelationships, Npcs
from domain.service.npc_clone_service import NpcCloneService


def _make_template_npc(
    *,
    name: str = "NPC",
    scenario_id: uuid.UUID | None = None,
    image_path: str | None = None,
    emotion_images: dict[str, str] | None = None,
) -> Npcs:
    """Create a scenario-level template NPC."""
    npc = MagicMock(spec=Npcs)
    npc.id = uuid.uuid4()
    npc.scenario_id = scenario_id or uuid.uuid4()
    npc.session_id = None
    npc.name = name
    npc.profile = {"role": "test"}
    npc.goals = {"primary": "test goal"}
    npc.state = {"mood": "neutral"}
    npc.location_x = 0
    npc.location_y = 0
    npc.image_path = image_path
    npc.emotion_images = emotion_images
    return npc


def _initial_state_with_npcs(
    npcs: list[dict[str, Any]],
) -> dict[str, Any]:
    return {"npcs": npcs}


class TestCloneNpcsForSession:
    """Tests for NpcCloneService.clone_npcs_for_session."""

    def test_clone_creates_session_npcs(self) -> None:
        """Scenario NPCs are cloned as session NPCs with new IDs."""
        svc = NpcCloneService()
        svc.npc_gw = MagicMock()
        db = MagicMock()
        scenario_id = uuid.uuid4()
        session_id = uuid.uuid4()

        template = _make_template_npc(
            name="Guard",
            scenario_id=scenario_id,
            image_path="/img/guard.png",
            emotion_images={"happy": "/img/guard_happy.png"},
        )
        svc.npc_gw.get_by_session.return_value = []
        svc.npc_gw.get_by_scenario.return_value = [template]

        initial_state: dict[str, Any] = _initial_state_with_npcs(
            [
                {
                    "name": "Guard",
                    "relationship": {
                        "affinity": 10,
                        "trust": 5,
                        "fear": 0,
                        "debt": 0,
                        "flags": {},
                    },
                },
            ]
        )

        svc.clone_npcs_for_session(db, scenario_id, session_id, initial_state)

        # Verify NPC was created
        assert svc.npc_gw.create.call_count == 1
        created_npc: Npcs = svc.npc_gw.create.call_args[0][1]
        assert created_npc.session_id == session_id
        assert created_npc.scenario_id is None
        assert created_npc.name == "Guard"
        assert created_npc.id != template.id
        assert created_npc.image_path == "/img/guard.png"
        assert created_npc.emotion_images == {"happy": "/img/guard_happy.png"}

    def test_clone_creates_relationships(self) -> None:
        """Relationships are created with initial_state values."""
        svc = NpcCloneService()
        svc.npc_gw = MagicMock()
        db = MagicMock()
        scenario_id = uuid.uuid4()
        session_id = uuid.uuid4()

        template = _make_template_npc(
            name="Merchant",
            scenario_id=scenario_id,
        )
        svc.npc_gw.get_by_session.return_value = []
        svc.npc_gw.get_by_scenario.return_value = [template]

        initial_state: dict[str, Any] = _initial_state_with_npcs(
            [
                {
                    "name": "Merchant",
                    "relationship": {
                        "affinity": -10,
                        "trust": 15,
                        "fear": 0,
                        "debt": 0,
                        "flags": {"met": True},
                    },
                },
            ]
        )

        svc.clone_npcs_for_session(db, scenario_id, session_id, initial_state)

        assert svc.npc_gw.create_relationship.call_count == 1
        rel: NpcRelationships = svc.npc_gw.create_relationship.call_args[0][1]
        assert rel.affinity == -10
        assert rel.trust == 15
        assert rel.fear == 0
        assert rel.debt == 0
        assert rel.flags == {"met": True}

    def test_clone_idempotent(self) -> None:
        """If session already has NPCs, clone is skipped."""
        svc = NpcCloneService()
        svc.npc_gw = MagicMock()
        db = MagicMock()
        scenario_id = uuid.uuid4()
        session_id = uuid.uuid4()

        existing_npc = MagicMock(spec=Npcs)
        svc.npc_gw.get_by_session.return_value = [existing_npc]

        svc.clone_npcs_for_session(db, scenario_id, session_id, {})

        svc.npc_gw.get_by_scenario.assert_not_called()
        svc.npc_gw.create.assert_not_called()
        svc.npc_gw.create_relationship.assert_not_called()

    def test_clone_default_relationship(self) -> None:
        """NPC without relationship in initial_state gets all-zero defaults."""
        svc = NpcCloneService()
        svc.npc_gw = MagicMock()
        db = MagicMock()
        scenario_id = uuid.uuid4()
        session_id = uuid.uuid4()

        template = _make_template_npc(
            name="Stranger",
            scenario_id=scenario_id,
        )
        svc.npc_gw.get_by_session.return_value = []
        svc.npc_gw.get_by_scenario.return_value = [template]

        # No npcs entry in initial_state
        initial_state: dict[str, Any] = {"npcs": []}

        svc.clone_npcs_for_session(db, scenario_id, session_id, initial_state)

        assert svc.npc_gw.create_relationship.call_count == 1
        rel: NpcRelationships = svc.npc_gw.create_relationship.call_args[0][1]
        assert rel.affinity == 0
        assert rel.trust == 0
        assert rel.fear == 0
        assert rel.debt == 0
        assert rel.flags == {}

    def test_clone_multiple_npcs(self) -> None:
        """Multiple scenario NPCs are all cloned."""
        svc = NpcCloneService()
        svc.npc_gw = MagicMock()
        db = MagicMock()
        scenario_id = uuid.uuid4()
        session_id = uuid.uuid4()

        t1 = _make_template_npc(name="NPC_A", scenario_id=scenario_id)
        t2 = _make_template_npc(name="NPC_B", scenario_id=scenario_id)
        svc.npc_gw.get_by_session.return_value = []
        svc.npc_gw.get_by_scenario.return_value = [t1, t2]

        initial_state: dict[str, Any] = _initial_state_with_npcs(
            [
                {
                    "name": "NPC_A",
                    "relationship": {
                        "affinity": 5,
                        "trust": 0,
                        "fear": 0,
                        "debt": 0,
                        "flags": {},
                    },
                },
                {
                    "name": "NPC_B",
                    "relationship": {
                        "affinity": -5,
                        "trust": 10,
                        "fear": 3,
                        "debt": 0,
                        "flags": {},
                    },
                },
            ]
        )

        svc.clone_npcs_for_session(db, scenario_id, session_id, initial_state)

        assert svc.npc_gw.create.call_count == 2
        assert svc.npc_gw.create_relationship.call_count == 2

        names = [svc.npc_gw.create.call_args_list[i][0][1].name for i in range(2)]
        assert "NPC_A" in names
        assert "NPC_B" in names
