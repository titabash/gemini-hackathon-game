"""Tests for ContextService formatting and background loading."""

from __future__ import annotations

import uuid
from unittest.mock import MagicMock

from domain.entity.gm_types import NpcSummary, TurnSummary
from domain.service.context_service import (
    ContextService,
    extract_nodes_text,
)


class TestFormatNpcs:
    """Tests for _format_npcs including location data."""

    def test_format_includes_location(self) -> None:
        """NPC location should appear in formatted output."""
        npcs = [
            NpcSummary(
                name="Guard",
                profile={"role": "guard"},
                goals={"primary": "Protect"},
                state={"mood": "alert"},
                relationship={"affinity": 5},
                location_x=5,
                location_y=3,
            ),
        ]

        result = ContextService._format_npcs(npcs)

        assert "location=(5, 3)" in result

    def test_format_multiple_npcs(self) -> None:
        """Multiple NPCs should all include location."""
        npcs = [
            NpcSummary(
                name="Guard",
                profile={},
                goals={},
                state={},
                relationship={},
                location_x=5,
                location_y=3,
            ),
            NpcSummary(
                name="Merchant",
                profile={},
                goals={},
                state={},
                relationship={},
                location_x=10,
                location_y=7,
            ),
        ]

        result = ContextService._format_npcs(npcs)

        assert "location=(5, 3)" in result
        assert "location=(10, 7)" in result
        assert "Guard" in result
        assert "Merchant" in result


def _fake_bg(
    *,
    bg_id: str | None = None,
    location: str = "Cave",
    description: str = "A dark cave",
    scenario_id: str | None = None,
    session_id: str | None = None,
) -> MagicMock:
    rec = MagicMock()
    rec.id = uuid.UUID(bg_id) if bg_id else uuid.uuid4()
    rec.location_name = location
    rec.description = description
    rec.scenario_id = uuid.UUID(scenario_id) if scenario_id else None
    rec.session_id = uuid.UUID(session_id) if session_id else None
    return rec


_SCENARIO_ID = "11111111-1111-1111-1111-111111111111"
_SESSION_ID = "22222222-2222-2222-2222-222222222222"


class TestLoadBackgrounds:
    """Tests for _load_backgrounds including session-generated assets."""

    def test_includes_scenario_backgrounds(self) -> None:
        """Scenario backgrounds should be included."""
        svc = ContextService()
        svc._bg_gw.find_all_by_scenario = MagicMock(
            return_value=[
                _fake_bg(
                    location="Castle",
                    description="Grand castle",
                    scenario_id=_SCENARIO_ID,
                ),
            ],
        )
        svc._bg_gw.find_all_by_session = MagicMock(return_value=[])

        result = svc._load_backgrounds(
            MagicMock(),
            uuid.UUID(_SCENARIO_ID),
            uuid.UUID(_SESSION_ID),
        )
        assert len(result) == 1
        assert result[0].location_name == "Castle"


class TestPromptCacheHelpers:
    """Tests for cache seed + dynamic prompt helper methods."""

    def _context(self) -> MagicMock:
        ctx = MagicMock()
        ctx.scenario_title = "Scenario A"
        ctx.scenario_setting = "Foggy town."
        ctx.system_prompt = "Follow rules."
        ctx.win_conditions = [{"id": "w1"}]
        ctx.fail_conditions = [{"id": "f1"}]
        ctx.plot_essentials = {"chapter": 1}
        ctx.short_term_summary = "You arrived."
        ctx.confirmed_facts = {"met_guard": True}
        ctx.recent_turns = []
        ctx.active_npcs = []
        ctx.active_objectives = []
        ctx.player_items = []
        ctx.current_turn_number = 3
        ctx.max_turns = 30
        ctx.current_state = {"flags": {"met_guard": True}}
        ctx.available_backgrounds = []
        ctx.player = MagicMock()
        ctx.player.name = "Hero"
        ctx.player.stats = {"hp": 10}
        ctx.player.status_effects = []
        ctx.player.location_x = 1
        ctx.player.location_y = 2
        return ctx

    def test_build_prompt_cache_seed_contains_stable_sections(self) -> None:
        """Cache seed should include immutable scenario/conditions section."""
        svc = ContextService()
        seed = svc.build_prompt_cache_seed(self._context())

        assert "# Scenario: Scenario A" in seed
        assert "# Win Conditions" in seed
        assert "# Fail Conditions" in seed
        assert "# Story So Far" not in seed

    def test_build_prompt_delta_contains_dynamic_sections_only(self) -> None:
        """Prompt delta should contain runtime state and user input."""
        svc = ContextService()
        prompt = svc.build_prompt_delta(
            self._context(),
            "do",
            "open the door",
        )

        assert "# Scenario:" not in prompt
        assert "# Plot Essentials" in prompt
        assert "# Player Input (do)" in prompt
        assert "open the door" in prompt

    def test_includes_session_backgrounds(self) -> None:
        """Session-generated backgrounds should also be included."""
        svc = ContextService()
        svc._bg_gw.find_all_by_scenario = MagicMock(return_value=[])
        svc._bg_gw.find_all_by_session = MagicMock(
            return_value=[
                _fake_bg(
                    location="Forest",
                    description="A misty forest",
                    session_id=_SESSION_ID,
                ),
            ],
        )

        result = svc._load_backgrounds(
            MagicMock(),
            uuid.UUID(_SCENARIO_ID),
            uuid.UUID(_SESSION_ID),
        )
        assert len(result) == 1
        assert result[0].location_name == "Forest"

    def test_deduplicates_by_id(self) -> None:
        """Same background ID from both queries → single entry."""
        shared_id = "33333333-3333-3333-3333-333333333333"
        bg = _fake_bg(bg_id=shared_id, location="Cave")
        svc = ContextService()
        svc._bg_gw.find_all_by_scenario = MagicMock(return_value=[bg])
        svc._bg_gw.find_all_by_session = MagicMock(return_value=[bg])

        result = svc._load_backgrounds(
            MagicMock(),
            uuid.UUID(_SCENARIO_ID),
            uuid.UUID(_SESSION_ID),
        )
        assert len(result) == 1


class TestExtractNodesText:
    """Tests for extract_nodes_text helper."""

    def test_empty_output(self) -> None:
        """Empty output dict should return empty string."""
        assert extract_nodes_text({}) == ""

    def test_no_nodes_key(self) -> None:
        """Output without nodes should return empty string."""
        output = {"narration_text": "Summary."}
        assert extract_nodes_text(output) == ""

    def test_narration_node(self) -> None:
        """Narration node should be prefixed with (narration)."""
        output = {
            "nodes": [
                {"type": "narration", "text": "Dark alley."},
            ],
        }
        assert extract_nodes_text(output) == "  (narration) Dark alley."

    def test_dialogue_node(self) -> None:
        """Dialogue node should show [speaker] quoted text."""
        output = {
            "nodes": [
                {
                    "type": "dialogue",
                    "speaker": "Rio",
                    "text": "Welcome.",
                },
            ],
        }
        assert extract_nodes_text(output) == '  [Rio] "Welcome."'

    def test_mixed_nodes(self) -> None:
        """Mixed narration and dialogue nodes joined by newlines."""
        output = {
            "nodes": [
                {"type": "narration", "text": "Dark alley."},
                {
                    "type": "dialogue",
                    "speaker": "Rio",
                    "text": "Welcome.",
                },
                {"type": "narration", "text": "Rio smiles."},
            ],
        }
        result = extract_nodes_text(output)
        assert "(narration) Dark alley." in result
        assert '[Rio] "Welcome."' in result
        assert "(narration) Rio smiles." in result
        assert "\n" in result

    def test_choice_nodes_included(self) -> None:
        """Choice nodes should appear as choice prompt."""
        output = {
            "nodes": [
                {"type": "narration", "text": "Scene."},
                {
                    "type": "choice",
                    "text": "What do you do?",
                    "choices": [{"id": "a", "text": "Go"}],
                },
            ],
        }
        result = extract_nodes_text(output)
        assert "(choice prompt) What do you do?" in result
        assert "(narration) Scene." in result

    def test_empty_text_skipped(self) -> None:
        """Nodes with empty text should be skipped."""
        output = {
            "nodes": [
                {"type": "narration", "text": ""},
                {"type": "narration", "text": "Valid."},
            ],
        }
        assert extract_nodes_text(output) == "  (narration) Valid."

    def test_dialogue_without_speaker_excluded(self) -> None:
        """Dialogue without speaker should be excluded."""
        output = {
            "nodes": [
                {"type": "dialogue", "text": "No speaker."},
            ],
        }
        assert extract_nodes_text(output) == ""


class TestFormatTurnsRich:
    """Tests for _format_turns with nodes_text."""

    def test_format_with_nodes_text(self) -> None:
        """Turns with nodes_text should include detail lines."""
        turns = [
            TurnSummary(
                turn_number=3,
                input_type="do",
                input_text="enter tavern",
                decision_type="narrate",
                narration_summary="Summary.",
                nodes_text='  (narration) Dark.\n  [Rio] "Hi."',
            ),
        ]
        result = ContextService._format_turns(turns)
        assert "Turn 3" in result
        assert "enter tavern" in result
        assert "(narration) Dark." in result
        assert '[Rio] "Hi."' in result

    def test_format_without_nodes_text(self) -> None:
        """Turns without nodes_text should show narration_summary."""
        turns = [
            TurnSummary(
                turn_number=1,
                input_type="do",
                input_text="look",
                decision_type="narrate",
                narration_summary="You looked around.",
            ),
        ]
        result = ContextService._format_turns(turns)
        assert "Turn 1" in result
        assert "You looked around." in result

    def test_format_multiple_turns(self) -> None:
        """Multiple turns should all appear in output."""
        turns = [
            TurnSummary(
                turn_number=1,
                input_type="do",
                input_text="explore",
                decision_type="narrate",
                narration_summary="Explored.",
            ),
            TurnSummary(
                turn_number=2,
                input_type="say",
                input_text="hello",
                decision_type="narrate",
                narration_summary="Greeted.",
                nodes_text='  [Guard] "Hello back."',
            ),
        ]
        result = ContextService._format_turns(turns)
        assert "Turn 1" in result
        assert "Turn 2" in result
        assert '[Guard] "Hello back."' in result


class TestLoadTurnsNodesExtraction:
    """Tests for _load_turns extracting nodes_text."""

    def test_load_turns_extracts_nodes(self) -> None:
        """_load_turns should extract nodes_text from output."""
        svc = ContextService()
        turn_row = MagicMock()
        turn_row.turn_number = 3
        turn_row.input_type = "do"
        turn_row.input_text = "enter tavern"
        turn_row.gm_decision_type = "narrate"
        turn_row.output = {
            "narration_text": "Summary.",
            "nodes": [
                {"type": "narration", "text": "Dark."},
                {
                    "type": "dialogue",
                    "speaker": "Rio",
                    "text": "Welcome.",
                },
            ],
        }
        svc._turn_gw.get_recent = MagicMock(
            return_value=[turn_row],
        )

        result = svc._load_turns(MagicMock(), uuid.uuid4())

        assert len(result) == 1
        assert result[0].nodes_text != ""
        assert '[Rio] "Welcome."' in result[0].nodes_text
        assert "(narration) Dark." in result[0].nodes_text

    def test_load_turns_no_nodes(self) -> None:
        """_load_turns with no nodes returns empty nodes_text."""
        svc = ContextService()
        turn_row = MagicMock()
        turn_row.turn_number = 1
        turn_row.input_type = "do"
        turn_row.input_text = "look"
        turn_row.gm_decision_type = "narrate"
        turn_row.output = {"narration_text": "You looked."}
        svc._turn_gw.get_recent = MagicMock(
            return_value=[turn_row],
        )

        result = svc._load_turns(MagicMock(), uuid.uuid4())

        assert len(result) == 1
        assert result[0].nodes_text == ""
        assert result[0].narration_summary == "You looked."


class TestExtractPreviousBgmMood:
    """Tests for _extract_previous_bgm_mood."""

    def test_returns_mood_from_last_turn(self) -> None:
        """Should return bgm_mood from most recent turn output."""
        svc = ContextService()
        turn_row = MagicMock()
        turn_row.output = {"bgm_mood": "battle"}
        svc._turn_gw.get_recent = MagicMock(
            return_value=[turn_row],
        )

        result = svc._extract_previous_bgm_mood(
            MagicMock(),
            uuid.uuid4(),
        )

        assert result == "battle"

    def test_returns_none_when_no_turns(self) -> None:
        """Should return None when no turns exist."""
        svc = ContextService()
        svc._turn_gw.get_recent = MagicMock(return_value=[])

        result = svc._extract_previous_bgm_mood(
            MagicMock(),
            uuid.uuid4(),
        )

        assert result is None

    def test_returns_none_when_empty_mood(self) -> None:
        """Should return None when bgm_mood is empty string."""
        svc = ContextService()
        turn_row = MagicMock()
        turn_row.output = {"bgm_mood": ""}
        svc._turn_gw.get_recent = MagicMock(
            return_value=[turn_row],
        )

        result = svc._extract_previous_bgm_mood(
            MagicMock(),
            uuid.uuid4(),
        )

        assert result is None

    def test_returns_none_when_mood_key_missing(self) -> None:
        """Should return None when output has no bgm_mood key."""
        svc = ContextService()
        turn_row = MagicMock()
        turn_row.output = {"narration_text": "Something."}
        svc._turn_gw.get_recent = MagicMock(
            return_value=[turn_row],
        )

        result = svc._extract_previous_bgm_mood(
            MagicMock(),
            uuid.uuid4(),
        )

        assert result is None

    def test_normalizes_mood_to_lowercase(self) -> None:
        """Should normalize mood to lowercase and strip whitespace."""
        svc = ContextService()
        turn_row = MagicMock()
        turn_row.output = {"bgm_mood": "  Exploration  "}
        svc._turn_gw.get_recent = MagicMock(
            return_value=[turn_row],
        )

        result = svc._extract_previous_bgm_mood(
            MagicMock(),
            uuid.uuid4(),
        )

        assert result == "exploration"


class TestBuildContextBgmMood:
    """Tests for build_context including previous_bgm_mood."""

    def test_build_context_includes_previous_bgm_mood(self) -> None:
        """build_context result should contain previous_bgm_mood."""
        svc = ContextService()
        session_id = uuid.uuid4()
        scenario_id = uuid.uuid4()

        # Mock session
        sess = MagicMock()
        sess.scenario_id = scenario_id
        sess.current_turn_number = 3
        sess.current_state = {}
        svc._session_gw.get_by_id = MagicMock(return_value=sess)

        # Mock scenario
        scenario = MagicMock()
        scenario.title = "Test Scenario"
        scenario.description = "A test."
        scenario.win_conditions = []
        scenario.fail_conditions = []
        scenario.max_turns = 30
        svc._scenario_gw.get_by_id = MagicMock(return_value=scenario)

        # Mock player character
        svc._pc_gw.get_by_session = MagicMock(return_value=None)

        # Mock context summary
        svc._context_gw.get_by_session = MagicMock(return_value=None)

        # Mock turns with bgm_mood
        turn_row = MagicMock()
        turn_row.turn_number = 2
        turn_row.input_type = "do"
        turn_row.input_text = "walk"
        turn_row.gm_decision_type = "narrate"
        turn_row.output = {
            "narration_text": "Walking.",
            "bgm_mood": "peaceful",
        }
        svc._turn_gw.get_recent = MagicMock(
            return_value=[turn_row],
        )

        # Mock npcs, objectives, items, backgrounds
        svc._npc_gw.get_by_session = MagicMock(return_value=[])
        svc._objective_gw.get_active_by_session = MagicMock(
            return_value=[],
        )
        svc._item_gw.get_by_session = MagicMock(return_value=[])
        svc._bg_gw.find_all_by_scenario = MagicMock(
            return_value=[],
        )
        svc._bg_gw.find_all_by_session = MagicMock(
            return_value=[],
        )

        ctx = svc.build_context(MagicMock(), session_id)

        assert ctx.previous_bgm_mood == "peaceful"


class TestPromptBgmSection:
    """Tests for BGM state section in prompts."""

    def _context(
        self,
        *,
        previous_bgm_mood: str | None = None,
    ) -> MagicMock:
        ctx = MagicMock()
        ctx.scenario_title = "Scenario A"
        ctx.scenario_setting = "Foggy town."
        ctx.system_prompt = "Follow rules."
        ctx.win_conditions = [{"id": "w1"}]
        ctx.fail_conditions = [{"id": "f1"}]
        ctx.plot_essentials = {"chapter": 1}
        ctx.short_term_summary = "You arrived."
        ctx.confirmed_facts = {"met_guard": True}
        ctx.recent_turns = []
        ctx.active_npcs = []
        ctx.active_objectives = []
        ctx.player_items = []
        ctx.current_turn_number = 3
        ctx.max_turns = 30
        ctx.current_state = {"flags": {"met_guard": True}}
        ctx.available_backgrounds = []
        ctx.previous_bgm_mood = previous_bgm_mood
        ctx.player = MagicMock()
        ctx.player.name = "Hero"
        ctx.player.stats = {"hp": 10}
        ctx.player.status_effects = []
        ctx.player.location_x = 1
        ctx.player.location_y = 2
        return ctx

    def test_build_prompt_includes_bgm_section_with_mood(self) -> None:
        """Prompt should include BGM state with current mood."""
        svc = ContextService()
        prompt = svc.build_prompt(
            self._context(previous_bgm_mood="exploration"),
            "do",
            "open the door",
        )

        assert "# Current BGM State" in prompt
        assert "exploration" in prompt

    def test_build_prompt_includes_bgm_section_without_mood(
        self,
    ) -> None:
        """Prompt should include BGM state even without mood."""
        svc = ContextService()
        prompt = svc.build_prompt(
            self._context(previous_bgm_mood=None),
            "do",
            "open the door",
        )

        assert "# Current BGM State" in prompt
        assert "No BGM playing" in prompt

    def test_build_prompt_delta_includes_bgm_section(self) -> None:
        """Prompt delta should also include BGM state section."""
        svc = ContextService()
        prompt = svc.build_prompt_delta(
            self._context(previous_bgm_mood="battle"),
            "do",
            "attack",
        )

        assert "# Current BGM State" in prompt
        assert "battle" in prompt

    def test_build_prompt_delta_no_mood(self) -> None:
        """Prompt delta without mood should show no BGM."""
        svc = ContextService()
        prompt = svc.build_prompt_delta(
            self._context(previous_bgm_mood=None),
            "do",
            "look",
        )

        assert "# Current BGM State" in prompt
        assert "No BGM playing" in prompt


class TestExtractPreviousBackground:
    """Tests for _extract_previous_background."""

    def test_returns_background_from_last_node(self) -> None:
        """Should return last effective background from nodes."""
        svc = ContextService()
        turn_row = MagicMock()
        turn_row.output = {
            "nodes": [
                {"type": "narration", "text": "A.", "background": "forest_bg"},
                {"type": "dialogue", "text": "B.", "speaker": "NPC"},
            ],
        }
        svc._turn_gw.get_recent = MagicMock(
            return_value=[turn_row],
        )

        result = svc._extract_previous_background(
            MagicMock(),
            uuid.uuid4(),
        )

        assert result == "forest_bg"

    def test_returns_last_background_when_multiple(self) -> None:
        """Should return the last non-null background in nodes."""
        svc = ContextService()
        turn_row = MagicMock()
        turn_row.output = {
            "nodes": [
                {"type": "narration", "text": "A.", "background": "forest_bg"},
                {
                    "type": "narration",
                    "text": "B.",
                    "background": "castle_bg",
                },
                {"type": "dialogue", "text": "C.", "speaker": "NPC"},
            ],
        }
        svc._turn_gw.get_recent = MagicMock(
            return_value=[turn_row],
        )

        result = svc._extract_previous_background(
            MagicMock(),
            uuid.uuid4(),
        )

        assert result == "castle_bg"

    def test_returns_none_when_no_turns(self) -> None:
        """Should return None when no turns exist."""
        svc = ContextService()
        svc._turn_gw.get_recent = MagicMock(return_value=[])

        result = svc._extract_previous_background(
            MagicMock(),
            uuid.uuid4(),
        )

        assert result is None

    def test_returns_none_when_no_background_in_nodes(self) -> None:
        """Should return None when nodes have no background."""
        svc = ContextService()
        turn_row = MagicMock()
        turn_row.output = {
            "nodes": [
                {"type": "narration", "text": "A."},
                {"type": "dialogue", "text": "B.", "speaker": "NPC"},
            ],
        }
        svc._turn_gw.get_recent = MagicMock(
            return_value=[turn_row],
        )

        result = svc._extract_previous_background(
            MagicMock(),
            uuid.uuid4(),
        )

        assert result is None

    def test_fallback_to_selected_background_id(self) -> None:
        """Should fallback to selected_background_id if no nodes."""
        svc = ContextService()
        turn_row = MagicMock()
        turn_row.output = {
            "selected_background_id": "abc-123",
        }
        svc._turn_gw.get_recent = MagicMock(
            return_value=[turn_row],
        )

        result = svc._extract_previous_background(
            MagicMock(),
            uuid.uuid4(),
        )

        assert result == "abc-123"


class TestFormatBackgroundStateSection:
    """Tests for _format_background_state_section."""

    def test_with_background(self) -> None:
        """Should describe current background."""
        result = ContextService._format_background_state_section(
            "forest_bg",
        )

        assert "forest_bg" in result
        assert "Currently displayed" in result

    def test_without_background(self) -> None:
        """Should indicate no background set."""
        result = ContextService._format_background_state_section(None)

        assert "No background" in result


class TestPromptBackgroundStateSection:
    """Tests for background state section in prompts."""

    def _context(
        self,
        *,
        previous_background: str | None = None,
    ) -> MagicMock:
        ctx = MagicMock()
        ctx.scenario_title = "Scenario A"
        ctx.scenario_setting = "Foggy town."
        ctx.system_prompt = "Follow rules."
        ctx.win_conditions = [{"id": "w1"}]
        ctx.fail_conditions = [{"id": "f1"}]
        ctx.plot_essentials = {"chapter": 1}
        ctx.short_term_summary = "You arrived."
        ctx.confirmed_facts = {"met_guard": True}
        ctx.recent_turns = []
        ctx.active_npcs = []
        ctx.active_objectives = []
        ctx.player_items = []
        ctx.current_turn_number = 3
        ctx.max_turns = 30
        ctx.current_state = {"flags": {"met_guard": True}}
        ctx.available_backgrounds = []
        ctx.previous_bgm_mood = None
        ctx.previous_background = previous_background
        ctx.player = MagicMock()
        ctx.player.name = "Hero"
        ctx.player.stats = {"hp": 10}
        ctx.player.status_effects = []
        ctx.player.location_x = 1
        ctx.player.location_y = 2
        return ctx

    def test_build_prompt_includes_background_section(self) -> None:
        """Prompt should include background state section."""
        svc = ContextService()
        prompt = svc.build_prompt(
            self._context(previous_background="forest_bg"),
            "do",
            "look around",
        )

        assert "# Current Scene Background" in prompt
        assert "forest_bg" in prompt

    def test_build_prompt_no_background(self) -> None:
        """Prompt should include background section even without bg."""
        svc = ContextService()
        prompt = svc.build_prompt(
            self._context(previous_background=None),
            "do",
            "look around",
        )

        assert "# Current Scene Background" in prompt
        assert "No background" in prompt

    def test_build_prompt_delta_includes_background_section(
        self,
    ) -> None:
        """Prompt delta should include background state section."""
        svc = ContextService()
        prompt = svc.build_prompt_delta(
            self._context(previous_background="castle_bg"),
            "do",
            "enter",
        )

        assert "# Current Scene Background" in prompt
        assert "castle_bg" in prompt
