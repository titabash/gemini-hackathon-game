"""Tests for GM Pydantic type definitions.

Validates serialization, deserialization, and schema generation
for all Gemini structured output types.
"""

from src.domain.entity.gm_types import (
    CharacterDisplay,
    ChoiceOption,
    FlagChange,
    GameContext,
    GmDecisionResponse,
    GmTurnRequest,
    ItemSummary,
    LocationChange,
    NewItem,
    NpcDialogue,
    NpcIntent,
    NpcSummary,
    ObjectiveSummary,
    ObjectiveUpdate,
    PlayerSummary,
    RelationshipChange,
    RepairData,
    SceneNode,
    SessionEnd,
    StateChanges,
    TurnSummary,
)


class TestGmTurnRequest:
    """Tests for player input request model."""

    def test_valid_do_input(self) -> None:
        """'do' input type should be accepted."""
        req = GmTurnRequest(
            session_id="abc-123",
            input_type="do",
            input_text="I open the chest",
        )
        assert req.input_type == "do"

    def test_valid_say_input(self) -> None:
        """'say' input type should be accepted."""
        req = GmTurnRequest(
            session_id="abc-123",
            input_type="say",
            input_text="Hello traveler",
        )
        assert req.input_type == "say"

    def test_all_input_types(self) -> None:
        """All defined input types should be valid."""
        for itype in ("do", "say", "choice", "clarify_answer"):
            req = GmTurnRequest(
                session_id="s1",
                input_type=itype,
                input_text="test",
            )
            assert req.input_type == itype

    def test_json_roundtrip(self) -> None:
        """Model should serialize and deserialize correctly."""
        req = GmTurnRequest(
            session_id="s1",
            input_type="do",
            input_text="enter the cave",
        )
        data = req.model_dump_json()
        restored = GmTurnRequest.model_validate_json(data)
        assert restored == req


class TestGmDecisionResponse:
    """Tests for GM decision output model."""

    def test_narrate_decision(self) -> None:
        """Narrate decision should have narration_text."""
        resp = GmDecisionResponse(
            decision_type="narrate",
            narration_text="You enter a dark cave.",
        )
        assert resp.decision_type == "narrate"
        assert resp.choices is None

    def test_choice_decision(self) -> None:
        """Choice decision should contain choices list."""
        resp = GmDecisionResponse(
            decision_type="choice",
            narration_text="The merchant offers you three items.",
            choices=[
                ChoiceOption(id="a", text="Buy the sword"),
                ChoiceOption(id="b", text="Buy the shield"),
                ChoiceOption(id="c", text="Leave", hint="safe option"),
            ],
        )
        assert resp.choices is not None
        assert len(resp.choices) == 3
        assert resp.choices[2].hint == "safe option"

    def test_clarify_decision(self) -> None:
        """Clarify decision should contain a question."""
        resp = GmDecisionResponse(
            decision_type="clarify",
            narration_text="",
            clarify_question="Do you mean the red or blue door?",
        )
        assert resp.clarify_question is not None

    def test_repair_decision(self) -> None:
        """Repair decision should contain contradiction info."""
        resp = GmDecisionResponse(
            decision_type="repair",
            narration_text="",
            repair=RepairData(
                contradiction="You said you don't have a sword.",
                proposed_fix="Use your fists instead.",
            ),
        )
        assert resp.repair is not None
        assert resp.repair.contradiction is not None

    def test_with_npc_dialogues(self) -> None:
        """NPC dialogues should be optional list."""
        resp = GmDecisionResponse(
            decision_type="narrate",
            narration_text="The innkeeper greets you.",
            npc_dialogues=[
                NpcDialogue(
                    npc_name="Innkeeper",
                    dialogue="Welcome, traveler!",
                    emotion="friendly",
                ),
            ],
        )
        assert resp.npc_dialogues is not None
        assert len(resp.npc_dialogues) == 1

    def test_with_state_changes(self) -> None:
        """State changes should be parsed correctly."""
        resp = GmDecisionResponse(
            decision_type="narrate",
            narration_text="You found a potion.",
            state_changes=StateChanges(
                stats_delta={"hp": 10},
                new_items=[NewItem(name="Health Potion", description="Heals 50 HP")],
                objective_updates=[
                    ObjectiveUpdate(
                        title="Find the potion",
                        status="completed",
                    ),
                ],
            ),
        )
        assert resp.state_changes is not None
        assert resp.state_changes.stats_delta == {"hp": 10}
        assert resp.state_changes.new_items is not None
        assert len(resp.state_changes.new_items) == 1

    def test_json_schema_generation(self) -> None:
        """Model should produce valid JSON schema for Gemini."""
        schema = GmDecisionResponse.model_json_schema()
        assert "properties" in schema
        assert "decision_type" in schema["properties"]

    def test_json_roundtrip(self) -> None:
        """Full model should serialize and deserialize correctly."""
        resp = GmDecisionResponse(
            decision_type="choice",
            narration_text="Choose wisely.",
            choices=[ChoiceOption(id="a", text="Option A")],
            npc_dialogues=[
                NpcDialogue(npc_name="Guide", dialogue="Pick carefully."),
            ],
            npc_intents=[
                NpcIntent(
                    npc_name="Guide",
                    intended_action="advise player",
                    adopted=True,
                ),
            ],
            state_changes=StateChanges(
                relationship_changes=[
                    RelationshipChange(
                        npc_name="Guide",
                        affinity_delta=5,
                    ),
                ],
            ),
        )
        data = resp.model_dump_json()
        restored = GmDecisionResponse.model_validate_json(data)
        assert restored.decision_type == "choice"
        assert restored.choices is not None
        assert len(restored.choices) == 1

    def test_session_end(self) -> None:
        """Session end should be part of state changes."""
        resp = GmDecisionResponse(
            decision_type="narrate",
            narration_text="You have won!",
            state_changes=StateChanges(
                session_end=SessionEnd(
                    ending_type="victory",
                    ending_summary="The hero saved the kingdom.",
                ),
            ),
        )
        assert resp.state_changes is not None
        assert resp.state_changes.session_end is not None
        assert resp.state_changes.session_end.ending_type == "victory"

    def test_with_nodes(self) -> None:
        """Decision with nodes should store SceneNode list."""
        resp = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Summary of nodes.",
            nodes=[
                SceneNode(
                    type="narration",
                    text="The forest grows quiet.",
                    background="forest_01",
                ),
                SceneNode(
                    type="dialogue",
                    text="Hello, traveler!",
                    speaker="Innkeeper",
                    characters=[
                        CharacterDisplay(
                            npc_name="Innkeeper",
                            expression="joy",
                            position="center",
                        ),
                    ],
                ),
                SceneNode(
                    type="choice",
                    text="What will you do?",
                    choices=[
                        ChoiceOption(id="a", text="Stay"),
                        ChoiceOption(id="b", text="Leave"),
                    ],
                ),
            ],
        )
        assert resp.nodes is not None
        assert len(resp.nodes) == 3
        assert resp.nodes[0].type == "narration"
        assert resp.nodes[1].speaker == "Innkeeper"
        assert resp.nodes[2].choices is not None

    def test_nodes_default_none(self) -> None:
        """Nodes should default to None for backward compatibility."""
        resp = GmDecisionResponse(
            decision_type="narrate",
            narration_text="No nodes.",
        )
        assert resp.nodes is None

    def test_with_nodes_json_roundtrip(self) -> None:
        """Decision with nodes should serialize and deserialize."""
        resp = GmDecisionResponse(
            decision_type="choice",
            narration_text="Summary.",
            nodes=[
                SceneNode(
                    type="dialogue",
                    text="Pick carefully.",
                    speaker="Guide",
                ),
                SceneNode(
                    type="choice",
                    text="Choose.",
                    choices=[ChoiceOption(id="a", text="Go")],
                ),
            ],
        )
        data = resp.model_dump_json()
        restored = GmDecisionResponse.model_validate_json(data)
        assert restored.nodes is not None
        assert len(restored.nodes) == 2
        assert restored.nodes[0].speaker == "Guide"


class TestStateChanges:
    """Tests for state change sub-models."""

    def test_location_change(self) -> None:
        """Location change should have name and coordinates."""
        sc = StateChanges(
            location_change=LocationChange(
                location_name="Dark Forest",
                x=10,
                y=20,
            ),
        )
        assert sc.location_change is not None
        assert sc.location_change.x == 10

    def test_status_effects(self) -> None:
        """Status effects add/remove should work."""
        sc = StateChanges(
            status_effect_adds=["poisoned", "blinded"],
            status_effect_removes=["blessed"],
        )
        assert sc.status_effect_adds is not None
        assert len(sc.status_effect_adds) == 2

    def test_empty_state_changes(self) -> None:
        """All fields should be optional."""
        sc = StateChanges()
        assert sc.stats_delta is None
        assert sc.new_items is None


class TestGameContext:
    """Tests for game context model."""

    def test_minimal_context(self) -> None:
        """Minimal required fields should construct valid context."""
        ctx = GameContext(
            scenario_title="Test Scenario",
            scenario_setting="A fantasy world",
            system_prompt="You are a game master.",
            win_conditions=[{"defeat_boss": True}],
            fail_conditions=[{"party_wipe": True}],
            plot_essentials={"main_quest": "Defeat the dragon"},
            short_term_summary="The party entered the dungeon.",
            confirmed_facts={"has_sword": True},
            recent_turns=[],
            player=PlayerSummary(
                name="Hero",
                stats={"hp": 100},
                status_effects=[],
                location_x=0,
                location_y=0,
            ),
            active_npcs=[],
            active_objectives=[],
            player_items=[],
            current_turn_number=1,
            current_state={},
        )
        assert ctx.scenario_title == "Test Scenario"
        assert ctx.max_turns == 30

    def test_custom_max_turns(self) -> None:
        """max_turns should accept custom values."""
        ctx = GameContext(
            scenario_title="T",
            scenario_setting="S",
            system_prompt="P",
            win_conditions=[],
            fail_conditions=[],
            plot_essentials={},
            short_term_summary="",
            confirmed_facts={},
            recent_turns=[],
            player=PlayerSummary(
                name="H",
                stats={},
                status_effects=[],
                location_x=0,
                location_y=0,
            ),
            active_npcs=[],
            active_objectives=[],
            player_items=[],
            current_turn_number=5,
            max_turns=20,
            current_state={},
        )
        assert ctx.max_turns == 20

    def test_with_npcs_and_objectives(self) -> None:
        """Context with NPCs and objectives should be valid."""
        ctx = GameContext(
            scenario_title="T",
            scenario_setting="S",
            system_prompt="P",
            win_conditions=[],
            fail_conditions=[],
            plot_essentials={},
            short_term_summary="",
            confirmed_facts={},
            recent_turns=[
                TurnSummary(
                    turn_number=1,
                    input_type="do",
                    input_text="explore",
                    decision_type="narrate",
                    narration_summary="You explored.",
                ),
            ],
            player=PlayerSummary(
                name="H",
                stats={},
                status_effects=[],
                location_x=0,
                location_y=0,
            ),
            active_npcs=[
                NpcSummary(
                    name="Guard",
                    profile={"role": "guard"},
                    goals={"patrol": True},
                    state={"alert": False},
                    relationship={"affinity": 0, "trust": 0},
                ),
            ],
            active_objectives=[
                ObjectiveSummary(title="Find the key", status="active"),
            ],
            player_items=[
                ItemSummary(name="Torch", item_type="tool", quantity=1),
            ],
            current_turn_number=2,
            current_state={"time_of_day": "night"},
        )
        assert len(ctx.active_npcs) == 1
        assert len(ctx.active_objectives) == 1
        assert len(ctx.player_items) == 1


class TestFlagChange:
    """Tests for FlagChange model and flag_changes in StateChanges."""

    def test_flag_change_creation(self) -> None:
        """FlagChange should accept flag_id and value."""
        fc = FlagChange(flag_id="found_secret", value=True)
        assert fc.flag_id == "found_secret"
        assert fc.value is True

    def test_flag_change_json_roundtrip(self) -> None:
        """FlagChange should serialize and deserialize correctly."""
        fc = FlagChange(flag_id="defeated_boss", value=False)
        data = fc.model_dump_json()
        restored = FlagChange.model_validate_json(data)
        assert restored == fc

    def test_state_changes_with_flag_changes(self) -> None:
        """StateChanges should accept flag_changes list."""
        sc = StateChanges(
            flag_changes=[
                FlagChange(flag_id="found_warehouse_secret", value=True),
                FlagChange(flag_id="talked_to_npc", value=True),
            ],
        )
        assert sc.flag_changes is not None
        assert len(sc.flag_changes) == 2
        assert sc.flag_changes[0].flag_id == "found_warehouse_secret"

    def test_state_changes_flag_changes_default_none(self) -> None:
        """flag_changes should default to None."""
        sc = StateChanges()
        assert sc.flag_changes is None

    def test_state_changes_with_flags_json_roundtrip(self) -> None:
        """StateChanges with flag_changes should serialize correctly."""
        sc = StateChanges(
            stats_delta={"hp": -5},
            flag_changes=[
                FlagChange(flag_id="key_found", value=True),
            ],
        )
        data = sc.model_dump_json()
        restored = StateChanges.model_validate_json(data)
        assert restored.flag_changes is not None
        assert len(restored.flag_changes) == 1
        assert restored.flag_changes[0].flag_id == "key_found"
        assert restored.flag_changes[0].value is True
        assert restored.stats_delta == {"hp": -5}
