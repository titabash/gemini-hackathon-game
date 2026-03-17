"""Tests for GenuiBridgeService.

Validates SSE event generation, A2UI protocol formatting,
helper functions (_split_words, _collect_npcs), and edge cases.
"""

from __future__ import annotations

import json
from typing import Any

import pytest

from src.domain.entity.gm_types import (
    CharacterDisplay,
    ChoiceOption,
    GmDecisionResponse,
    ItemUpdate,
    LocationChange,
    NewItem,
    NpcDialogue,
    NpcIntent,
    ObjectiveUpdate,
    RelationshipChange,
    RepairData,
    SceneNode,
    StatDelta,
    StateChanges,
)
from src.domain.service.genui_bridge_service import (
    GenuiBridgeService,
    NpcImageMap,
    _a2ui_delete,
    _a2ui_surface,
    _collect_npcs,
    _sse,
)


def _parse_sse_events(raw: str) -> list[dict[str, Any]]:
    """Parse multi-event SSE string into list of dicts."""
    return [
        json.loads(e.removeprefix("data: ")) for e in raw.split("\n\n") if e.strip()
    ]


def _classify_event(payload: dict[str, Any]) -> str:
    """Return a short label for an SSE event payload."""
    if "deleteSurface" in payload:
        return "delete"
    if "surfaceUpdate" in payload:
        return "surfaceUpdate"
    if "beginRendering" in payload:
        return "beginRendering"
    return str(payload.get("type", "unknown"))


def _parse_raw_events(raw_events: list[str]) -> list[dict[str, Any]]:
    """Split raw SSE yields (which may contain multiple data lines) into dicts.

    ``_a2ui_surface`` concatenates surfaceUpdate + beginRendering into
    one string, so a single yield can contain multiple ``data:`` lines.
    """
    parsed: list[dict[str, Any]] = []
    for raw in raw_events:
        for line in raw.split("\n"):
            stripped = line.strip()
            if stripped.startswith("data: "):
                parsed.append(json.loads(stripped.removeprefix("data: ")))
    return parsed


async def _collect_stream(
    svc: GenuiBridgeService,
    decision: GmDecisionResponse,
    *,
    npc_images: NpcImageMap | None = None,
) -> list[str]:
    """Drain stream_decision into a list."""
    return [
        event
        async for event in svc.stream_decision(
            decision,
            npc_images=npc_images,
        )
    ]


# ---------------------------------------------------------------------------
# Helper function tests
# ---------------------------------------------------------------------------


class TestSse:
    """Tests for _sse() SSE formatter."""

    def test_basic_payload(self) -> None:
        """SSE data line should be formatted correctly."""
        result = _sse({"type": "done"})
        assert result.startswith("data: ")
        assert result.endswith("\n\n")
        parsed = json.loads(result.removeprefix("data: ").strip())
        assert parsed == {"type": "done"}

    def test_japanese_text_unescaped(self) -> None:
        """Japanese text should not be unicode-escaped."""
        result = _sse({"type": "text", "content": "こんにちは"})
        assert "こんにちは" in result
        assert "\\u" not in result


class TestA2uiDelete:
    """Tests for _a2ui_delete() helper."""

    def test_delete_event_format(self) -> None:
        """Event should contain the deleteSurface key with surfaceId."""
        result = _a2ui_delete("game-narration")
        parsed = json.loads(result.removeprefix("data: ").strip())
        assert parsed == {"deleteSurface": {"surfaceId": "game-narration"}}


class TestA2uiSurface:
    """Tests for _a2ui_surface() helper."""

    def test_produces_two_events(self) -> None:
        """Should emit surfaceUpdate + beginRendering (2 SSE events)."""
        result = _a2ui_surface("game-surface", "choiceGroup", {"choices": []})
        events = [e for e in result.split("\n\n") if e.strip()]
        assert len(events) == 2

    def test_surface_update_structure(self) -> None:
        """Update event should contain components with correct structure."""
        result = _a2ui_surface("s1", "novelTextBox", {"text": "Hello"})
        events = _parse_sse_events(result)
        surface_update = events[0]
        assert "surfaceUpdate" in surface_update
        su = surface_update["surfaceUpdate"]
        assert su["surfaceId"] == "s1"
        assert len(su["components"]) == 1
        comp = su["components"][0]
        assert comp["id"] == "root"
        assert comp["component"] == {"novelTextBox": {"text": "Hello"}}

    def test_begin_rendering_structure(self) -> None:
        """Rendering event should reference the surface and root."""
        result = _a2ui_surface("s1", "test", {})
        events = _parse_sse_events(result)
        begin = events[1]
        assert begin == {"beginRendering": {"surfaceId": "s1", "root": "root"}}


# ---------------------------------------------------------------------------
# _split_words tests
# ---------------------------------------------------------------------------


class TestSplitWords:
    """Tests for GenuiBridgeService._split_words()."""

    def test_normal_sentence(self) -> None:
        """Words should be split with trailing spaces except last."""
        result = GenuiBridgeService._split_words("Hello world")
        assert result == ["Hello ", "world"]

    def test_single_word(self) -> None:
        """Single word should return as-is."""
        result = GenuiBridgeService._split_words("Hello")
        assert result == ["Hello"]

    def test_empty_string(self) -> None:
        """Empty string should return empty list."""
        result = GenuiBridgeService._split_words("")
        assert result == []

    def test_multiple_words(self) -> None:
        """Multiple words should each have trailing space except last."""
        result = GenuiBridgeService._split_words("a b c d")
        assert result == ["a ", "b ", "c ", "d"]


# ---------------------------------------------------------------------------
# _collect_npcs tests
# ---------------------------------------------------------------------------


class TestCollectNpcs:
    """Tests for _collect_npcs() shared NPC builder."""

    def _make_decision(
        self,
        *,
        intents: list[NpcIntent] | None = None,
        dialogues: list[NpcDialogue] | None = None,
    ) -> GmDecisionResponse:
        return GmDecisionResponse(
            decision_type="narrate",
            narration_text="test",
            npc_intents=intents,
            npc_dialogues=dialogues,
        )

    def test_empty_npcs(self) -> None:
        """No intents or dialogues should return empty list."""
        decision = self._make_decision()
        result = _collect_npcs(decision, None, image_key="imagePath")
        assert result == []

    def test_intent_only(self) -> None:
        """NPC from intent should appear with emotion=None."""
        decision = self._make_decision(
            intents=[
                NpcIntent(
                    npc_name="Guard",
                    intended_action="patrol",
                    adopted=True,
                ),
            ],
        )
        result = _collect_npcs(decision, None, image_key="imagePath")
        assert len(result) == 1
        assert result[0]["name"] == "Guard"
        assert result[0]["emotion"] is None
        assert result[0]["imagePath"] is None

    def test_dialogue_only(self) -> None:
        """NPC from dialogue should appear with emotion."""
        decision = self._make_decision(
            dialogues=[
                NpcDialogue(
                    npc_name="Innkeeper",
                    dialogue="Welcome!",
                    emotion="happy",
                ),
            ],
        )
        result = _collect_npcs(decision, None, image_key="imagePath")
        assert len(result) == 1
        assert result[0]["name"] == "Innkeeper"
        assert result[0]["emotion"] == "happy"

    def test_dialogue_overrides_intent(self) -> None:
        """Same NPC in both intent and dialogue: dialogue wins."""
        decision = self._make_decision(
            intents=[
                NpcIntent(
                    npc_name="Guard",
                    intended_action="greet",
                    adopted=True,
                ),
            ],
            dialogues=[
                NpcDialogue(
                    npc_name="Guard",
                    dialogue="Halt!",
                    emotion="angry",
                ),
            ],
        )
        result = _collect_npcs(decision, None, image_key="imagePath")
        assert len(result) == 1
        assert result[0]["emotion"] == "angry"

    def test_image_path_with_bucket_prefix(self) -> None:
        """Image path should be prefixed with scenario-assets bucket."""
        decision = self._make_decision(
            dialogues=[
                NpcDialogue(
                    npc_name="Wizard",
                    dialogue="Greetings!",
                ),
            ],
        )
        images: NpcImageMap = {"Wizard": ("npcs/wizard.png", {})}
        result = _collect_npcs(decision, images, image_key="imagePath")
        assert result[0]["imagePath"] == "scenario-assets/npcs/wizard.png"

    def test_image_key_parameter(self) -> None:
        """Key name in output dict should match image_key arg."""
        decision = self._make_decision(
            dialogues=[
                NpcDialogue(npc_name="A", dialogue="Hi"),
            ],
        )
        result_camel = _collect_npcs(decision, None, image_key="imagePath")
        result_snake = _collect_npcs(decision, None, image_key="image_path")
        assert "imagePath" in result_camel[0]
        assert "image_path" in result_snake[0]

    def test_missing_image_returns_none(self) -> None:
        """NPC not in images dict should have None image path."""
        decision = self._make_decision(
            dialogues=[
                NpcDialogue(npc_name="Ghost", dialogue="Boo"),
            ],
        )
        images: NpcImageMap = {"Other": ("other.png", {})}
        result = _collect_npcs(decision, images, image_key="imagePath")
        assert result[0]["imagePath"] is None

    def test_max_npcs_limits_output(self) -> None:
        """When max_npcs is set, output should be truncated."""
        decision = self._make_decision(
            intents=[
                NpcIntent(npc_name="A", intended_action="wait", adopted=True),
                NpcIntent(npc_name="B", intended_action="wait", adopted=True),
                NpcIntent(npc_name="C", intended_action="wait", adopted=True),
                NpcIntent(npc_name="D", intended_action="wait", adopted=True),
            ],
        )
        result = _collect_npcs(decision, None, image_key="imagePath", max_npcs=3)
        assert len(result) == 3

    def test_max_npcs_prioritises_dialogue(self) -> None:
        """Dialogue NPCs should be kept when truncating."""
        decision = self._make_decision(
            intents=[
                NpcIntent(npc_name="A", intended_action="wait", adopted=True),
                NpcIntent(npc_name="B", intended_action="wait", adopted=True),
                NpcIntent(npc_name="C", intended_action="wait", adopted=True),
            ],
            dialogues=[
                NpcDialogue(npc_name="D", dialogue="Hello"),
            ],
        )
        result = _collect_npcs(decision, None, image_key="imagePath", max_npcs=3)
        assert len(result) == 3
        names = {npc["name"] for npc in result}
        assert "D" in names  # dialogue NPC must be kept

    def test_max_npcs_none_means_no_limit(self) -> None:
        """When max_npcs is None, all NPCs should be returned."""
        decision = self._make_decision(
            intents=[
                NpcIntent(npc_name=f"N{i}", intended_action="idle", adopted=True)
                for i in range(5)
            ],
        )
        result = _collect_npcs(decision, None, image_key="imagePath", max_npcs=None)
        assert len(result) == 5

    # --- Emotion-based image selection tests ---

    def test_emotion_image_selected(self) -> None:
        """LLM emotion=joy -> joy emotion image is selected."""
        decision = self._make_decision(
            dialogues=[
                NpcDialogue(
                    npc_name="Wizard",
                    dialogue="Ha!",
                    emotion="joy",
                ),
            ],
        )
        images: NpcImageMap = {
            "Wizard": ("npcs/wizard.png", {"joy": "npcs/wizard_joy.png"}),
        }
        result = _collect_npcs(decision, images, image_key="imagePath")
        assert result[0]["imagePath"] == "scenario-assets/npcs/wizard_joy.png"

    def test_emotion_fallback_to_default(self) -> None:
        """Emotion not in emotion_images -> default image."""
        decision = self._make_decision(
            dialogues=[
                NpcDialogue(
                    npc_name="Wizard",
                    dialogue="Hmm",
                    emotion="sadness",
                ),
            ],
        )
        images: NpcImageMap = {
            "Wizard": ("npcs/wizard.png", {"joy": "npcs/wizard_joy.png"}),
        }
        result = _collect_npcs(decision, images, image_key="imagePath")
        assert result[0]["imagePath"] == "scenario-assets/npcs/wizard.png"

    def test_no_emotion_uses_default(self) -> None:
        """emotion=None -> default image."""
        decision = self._make_decision(
            dialogues=[
                NpcDialogue(npc_name="Wizard", dialogue="..."),
            ],
        )
        images: NpcImageMap = {
            "Wizard": ("npcs/wizard.png", {"joy": "npcs/wizard_joy.png"}),
        }
        result = _collect_npcs(decision, images, image_key="imagePath")
        assert result[0]["imagePath"] == "scenario-assets/npcs/wizard.png"

    def test_empty_emotion_map_uses_default(self) -> None:
        """Empty emotion_images -> default image even with emotion set."""
        decision = self._make_decision(
            dialogues=[
                NpcDialogue(
                    npc_name="Wizard",
                    dialogue="Hi",
                    emotion="joy",
                ),
            ],
        )
        images: NpcImageMap = {"Wizard": ("npcs/wizard.png", {})}
        result = _collect_npcs(decision, images, image_key="imagePath")
        assert result[0]["imagePath"] == "scenario-assets/npcs/wizard.png"


# ---------------------------------------------------------------------------
# GenuiBridgeService method tests
# ---------------------------------------------------------------------------


class TestBuildNarrationSections:
    """Tests for _build_narration_sections()."""

    def test_narration_only(self) -> None:
        """Narration text only should produce a single narration section."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="The sun sets.",
        )
        result = GenuiBridgeService._build_narration_sections(decision)
        assert len(result) == 1
        assert result[0] == {"type": "narration", "text": "The sun sets."}

    def test_dialogue_and_narration(self) -> None:
        """Dialogues come first, then narration."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="The room is quiet.",
            npc_dialogues=[
                NpcDialogue(npc_name="Alice", dialogue="Hello!"),
            ],
        )
        result = GenuiBridgeService._build_narration_sections(decision)
        assert len(result) == 2
        assert result[0] == {
            "type": "dialogue",
            "speaker": "Alice",
            "text": "Hello!",
        }
        assert result[1] == {
            "type": "narration",
            "text": "The room is quiet.",
        }

    def test_multiple_dialogues(self) -> None:
        """Multiple NPC dialogues produce separate sections."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="",
            npc_dialogues=[
                NpcDialogue(npc_name="A", dialogue="Hi"),
                NpcDialogue(npc_name="B", dialogue="Hello"),
            ],
        )
        result = GenuiBridgeService._build_narration_sections(decision)
        assert len(result) == 2
        assert result[0]["speaker"] == "A"
        assert result[1]["speaker"] == "B"

    def test_empty_narration_no_dialogues(self) -> None:
        """Empty narration with no dialogues should return empty list."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="",
        )
        result = GenuiBridgeService._build_narration_sections(decision)
        assert result == []

    def test_dialogue_only_no_narration(self) -> None:
        """Dialogue with empty narration omits narration section."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="",
            npc_dialogues=[
                NpcDialogue(npc_name="Bob", dialogue="Hey"),
            ],
        )
        result = GenuiBridgeService._build_narration_sections(decision)
        assert len(result) == 1
        assert result[0]["type"] == "dialogue"


class TestBuildStateData:
    """Tests for _build_state_data()."""

    def test_no_state_returns_none(self) -> None:
        """Decision without state changes should return None."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Nothing happens.",
        )
        assert GenuiBridgeService._build_state_data(decision) is None

    def test_scene_description(self) -> None:
        """Scene description should be included."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="A dark cave.",
            scene_description="A vast underground cavern.",
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        assert result["scene_description"] == "A vast underground cavern."

    def test_stats_delta(self) -> None:
        """Stats delta should be included."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Ouch!",
            state_changes=StateChanges(
                stats_delta=[
                    StatDelta(stat="hp", delta=-5),
                    StatDelta(stat="san", delta=-3),
                ],
            ),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        assert result["stats_delta"] == {"hp": -5, "san": -3}

    def test_location_change(self) -> None:
        """Location change should be serialized."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="You move.",
            state_changes=StateChanges(
                location_change=LocationChange(
                    location_name="Forest",
                    x=5,
                    y=10,
                ),
            ),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        loc = result["location"]
        assert loc["location_name"] == "Forest"

    def test_npc_visual_data(self) -> None:
        """Active NPCs should use snake_case image_path key."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="test",
            npc_dialogues=[
                NpcDialogue(npc_name="Elf", dialogue="Greetings"),
            ],
        )
        images: NpcImageMap = {"Elf": ("npcs/elf.png", {})}
        result = GenuiBridgeService._build_state_data(
            decision,
            npc_images=images,
        )
        assert result is not None
        npcs = result["active_npcs"]
        assert len(npcs) == 1
        assert "image_path" in npcs[0]


class TestBuildSurfaceProperties:
    """Tests for _build_surface_properties()."""

    def test_choice_surface(self) -> None:
        """Choice decision should return choiceGroup surface from nodes."""
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="Choose.",
            nodes=[
                SceneNode(type="narration", text="You face a dilemma."),
                SceneNode(
                    type="choice",
                    text="What do you do?",
                    choices=[
                        ChoiceOption(id="a", text="Fight"),
                        ChoiceOption(id="b", text="Run"),
                    ],
                ),
            ],
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "choiceGroup"
        assert len(result["properties"]["choices"]) == 2
        assert result["properties"]["allowFreeInput"] is True

    def test_choice_surface_node_not_last(self) -> None:
        """Choice node does not need to be the last node."""
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="Choose.",
            nodes=[
                SceneNode(
                    type="choice",
                    text="What do you do?",
                    choices=[ChoiceOption(id="a", text="Fight")],
                ),
                SceneNode(type="narration", text="Trailing narration."),
            ],
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "choiceGroup"
        assert len(result["properties"]["choices"]) == 1

    def test_choice_surface_no_nodes_returns_action_input(self) -> None:
        """Choice with no nodes falls back to actionInput using narration_text."""
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="What will you do next?",
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "actionInput"
        assert result["properties"]["question"] == "What will you do next?"

    def test_choice_surface_only_narration_nodes_returns_action_input(self) -> None:
        """Choice decision with only narration nodes falls back to actionInput."""
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="Two paths diverge before you. Which do you take?",
            nodes=[
                SceneNode(type="narration", text="You face a crossroads."),
                SceneNode(type="narration", text="Two paths diverge."),
            ],
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "actionInput"
        assert (
            result["properties"]["question"]
            == "Two paths diverge before you. Which do you take?"
        )

    def test_act_surface_with_action_prompt(self) -> None:
        """Act decision returns actionInput surface with action_prompt."""
        decision = GmDecisionResponse(
            decision_type="act",
            narration_text="Summary.",
            action_prompt="次にどうする？",
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "actionInput"
        assert result["properties"]["question"] == "次にどうする？"

    def test_act_surface_falls_back_to_narration_text(self) -> None:
        """Act decision without action_prompt falls back to narration_text."""
        decision = GmDecisionResponse(
            decision_type="act",
            narration_text="You stand at the crossroads.",
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "actionInput"
        assert result["properties"]["question"] == "You stand at the crossroads."

    def test_clarify_surface(self) -> None:
        """Clarify decision should return clarifyQuestion surface."""
        decision = GmDecisionResponse(
            decision_type="clarify",
            narration_text="",
            clarify_question="Which path?",
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "clarifyQuestion"
        assert result["properties"]["question"] == "Which path?"

    def test_repair_surface(self) -> None:
        """Repair decision should return repairConfirm surface."""
        decision = GmDecisionResponse(
            decision_type="repair",
            narration_text="",
            repair=RepairData(
                contradiction="No sword.",
                proposed_fix="Use fists.",
            ),
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "repairConfirm"

    def test_clarify_without_question_falls_back_to_action_input(self) -> None:
        """Clarify without clarify_question should fall back to actionInput."""
        decision = GmDecisionResponse(
            decision_type="clarify",
            narration_text="Something is unclear here.",
            clarify_question=None,
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None, "Must never return None for clarify"
        assert result["type"] == "actionInput"
        assert result["properties"]["question"] == "Something is unclear here."

    def test_repair_without_data_falls_back_to_action_input(self) -> None:
        """Repair without repair data should fall back to actionInput."""
        decision = GmDecisionResponse(
            decision_type="repair",
            narration_text="Let me clarify what happened.",
            repair=None,
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None, "Must never return None for repair"
        assert result["type"] == "actionInput"
        assert result["properties"]["question"] == "Let me clarify what happened."

    def test_narrate_surface(self) -> None:
        """Narrate decision should return continueButton surface."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="The end.",
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "continueButton"
        assert result["properties"] == {}

    def test_narrate_surface_hidden_when_continue_disabled(self) -> None:
        """Narrate surface should be omitted when continue is disabled."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="The end.",
        )
        result = GenuiBridgeService._build_surface_properties(
            decision,
            show_continue_button=False,
        )
        assert result is None

    def test_narrate_surface_continue_or_input_when_handoff(self) -> None:
        """Narrate handoff should return continueOrInput surface."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="The end.",
        )
        result = GenuiBridgeService._build_surface_properties(
            decision,
            show_continue_button=True,
            show_continue_input_cta=True,
        )
        assert result is not None
        assert result["type"] == "continueOrInput"
        assert result["properties"] == {}

    def test_choice_without_nodes_returns_action_input(self) -> None:
        """Choice decision without nodes falls back to actionInput."""
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="Choose.",
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "actionInput"
        assert result["properties"]["question"] == "Choose."


# ---------------------------------------------------------------------------
# stream_decision integration test
# ---------------------------------------------------------------------------


class TestStreamDecision:
    """Integration tests for stream_decision()."""

    @pytest.mark.asyncio
    async def test_narrate_stream_events(self) -> None:
        """Narrate decision should produce expected event sequence."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Hello world",
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)
        event_types = [_classify_event(p) for p in parsed]

        # game-narration and game-surface are deleted; game-npcs is NOT
        # deleted (overwritten in-place to avoid ValueNotifier disposal).
        assert event_types[:2] == ["delete", "delete"]
        assert "text" in event_types
        assert "surfaceUpdate" in event_types
        assert event_types[-1] == "done"

    @pytest.mark.asyncio
    async def test_npc_gallery_emitted_even_when_empty(self) -> None:
        """NPC gallery surface must be emitted even with no NPCs.

        The GenUiSurface widget for game-npcs is always in the widget
        tree, so the surface must be updated in-place (not deleted and
        recreated) to avoid breaking the ValueNotifier reference.
        """
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="No NPCs here.",
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        npc_surfaces = [
            p["surfaceUpdate"]
            for p in parsed
            if p.get("surfaceUpdate", {}).get("surfaceId") == "game-npcs"
        ]
        assert len(npc_surfaces) == 1
        npcs = npc_surfaces[0]["components"][0]["component"]["npcGallery"]["npcs"]
        assert npcs == []

    @pytest.mark.asyncio
    async def test_no_delete_surface_for_game_npcs(self) -> None:
        """DeleteSurface must NOT be emitted for game-npcs."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="test",
            npc_dialogues=[
                NpcDialogue(npc_name="Elf", dialogue="Hello"),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        deleted_ids = [
            p["deleteSurface"]["surfaceId"] for p in parsed if "deleteSurface" in p
        ]
        assert "game-npcs" not in deleted_ids
        assert "game-narration" in deleted_ids
        assert "game-surface" in deleted_ids

    @pytest.mark.asyncio
    async def test_narration_surface_uses_narrative_panel(self) -> None:
        """Narration surface should use narrativePanel with sections."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="The sun sets.",
            npc_dialogues=[
                NpcDialogue(npc_name="Elf", dialogue="Greetings!"),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        narration_surfaces = [
            p["surfaceUpdate"]
            for p in parsed
            if p.get("surfaceUpdate", {}).get("surfaceId") == "game-narration"
        ]
        assert len(narration_surfaces) == 1
        comp = narration_surfaces[0]["components"][0]["component"]
        assert "narrativePanel" in comp
        sections = comp["narrativePanel"]["sections"]
        assert len(sections) == 2
        assert sections[0]["type"] == "dialogue"
        assert sections[0]["speaker"] == "Elf"
        assert sections[0]["text"] == "Greetings!"
        assert sections[1]["type"] == "narration"
        assert sections[1]["text"] == "The sun sets."

    @pytest.mark.asyncio
    async def test_choice_stream_has_surface(self) -> None:
        """Choice decision should include game-surface events."""
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="Choose wisely.",
            nodes=[
                SceneNode(
                    type="choice",
                    text="What do you do?",
                    choices=[ChoiceOption(id="a", text="Option A")],
                ),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        surface_ids = [
            p.get("surfaceUpdate", {}).get("surfaceId")
            for p in parsed
            if "surfaceUpdate" in p
        ]
        assert "game-surface" in surface_ids

    @pytest.mark.asyncio
    async def test_npc_dialogue_text_streaming(self) -> None:
        """NPC dialogues should be streamed as text events."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Silence.",
            npc_dialogues=[
                NpcDialogue(
                    npc_name="Guard",
                    dialogue="Stop!",
                    emotion="angry",
                ),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        text_parts = [p["content"] for p in parsed if p.get("type") == "text"]
        full_text = "".join(text_parts)
        assert "[Guard]" in full_text
        assert "Stop!" in full_text
        assert "Silence." in full_text

    @pytest.mark.asyncio
    async def test_text_streaming_newline_between_dialogue_and_narration(
        self,
    ) -> None:
        """Dialogue and narration should be separated by newline for paging."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="The room falls silent.",
            npc_dialogues=[
                NpcDialogue(
                    npc_name="Guard",
                    dialogue="Halt!",
                    emotion="angry",
                ),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        text_parts = [p["content"] for p in parsed if p.get("type") == "text"]
        full_text = "".join(text_parts)
        # Dialogue and narration must be on separate lines
        assert "\n" in full_text
        lines = full_text.split("\n")
        assert any("[Guard]" in line for line in lines)
        assert any("The room falls silent." in line for line in lines)

    @pytest.mark.asyncio
    async def test_text_streaming_newline_between_multiple_dialogues(
        self,
    ) -> None:
        """Multiple dialogues should be separated by newlines."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="",
            npc_dialogues=[
                NpcDialogue(npc_name="Alice", dialogue="Hello!"),
                NpcDialogue(npc_name="Bob", dialogue="Hi there!"),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        text_parts = [p["content"] for p in parsed if p.get("type") == "text"]
        full_text = "".join(text_parts)
        lines = full_text.split("\n")
        # Each dialogue should be on its own line
        alice_lines = [ln for ln in lines if "[Alice]" in ln]
        bob_lines = [ln for ln in lines if "[Bob]" in ln]
        assert len(alice_lines) >= 1
        assert len(bob_lines) >= 1

    @pytest.mark.asyncio
    async def test_npc_gallery_surface(self) -> None:
        """NPC intents should produce game-npcs surface."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="test",
            npc_intents=[
                NpcIntent(
                    npc_name="Elf",
                    intended_action="cast",
                    adopted=True,
                ),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        npc_surfaces = [
            p["surfaceUpdate"]
            for p in parsed
            if p.get("surfaceUpdate", {}).get("surfaceId") == "game-npcs"
        ]
        assert len(npc_surfaces) == 1
        comp = npc_surfaces[0]["components"][0]["component"]
        assert "npcGallery" in comp
        npcs = comp["npcGallery"]["npcs"]
        assert len(npcs) == 1
        assert npcs[0]["name"] == "Elf"

    @pytest.mark.asyncio
    async def test_npc_gallery_includes_speakers(self) -> None:
        """Gallery surface should include speakers list from dialogues."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="test",
            npc_dialogues=[
                NpcDialogue(npc_name="Alice", dialogue="Hi", emotion="happy"),
            ],
            npc_intents=[
                NpcIntent(npc_name="Bob", intended_action="wait", adopted=True),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        npc_surfaces = [
            p["surfaceUpdate"]
            for p in parsed
            if p.get("surfaceUpdate", {}).get("surfaceId") == "game-npcs"
        ]
        assert len(npc_surfaces) == 1
        props = npc_surfaces[0]["components"][0]["component"]["npcGallery"]
        assert "speakers" in props
        assert props["speakers"] == ["Alice"]

    @pytest.mark.asyncio
    async def test_npc_gallery_multiple_speakers(self) -> None:
        """Multiple dialogue NPCs should all appear in speakers."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="test",
            npc_dialogues=[
                NpcDialogue(npc_name="Alice", dialogue="Hi"),
                NpcDialogue(npc_name="Bob", dialogue="Hello"),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        npc_surfaces = [
            p["surfaceUpdate"]
            for p in parsed
            if p.get("surfaceUpdate", {}).get("surfaceId") == "game-npcs"
        ]
        props = npc_surfaces[0]["components"][0]["component"]["npcGallery"]
        assert sorted(props["speakers"]) == ["Alice", "Bob"]

    @pytest.mark.asyncio
    async def test_npc_gallery_no_speakers_when_intent_only(self) -> None:
        """Intent-only NPCs should result in empty speakers list."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="test",
            npc_intents=[
                NpcIntent(npc_name="Guard", intended_action="patrol", adopted=True),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        npc_surfaces = [
            p["surfaceUpdate"]
            for p in parsed
            if p.get("surfaceUpdate", {}).get("surfaceId") == "game-npcs"
        ]
        props = npc_surfaces[0]["components"][0]["component"]["npcGallery"]
        assert props["speakers"] == []

    @pytest.mark.asyncio
    async def test_npc_gallery_limited_to_max_display(self) -> None:
        """Gallery surface should show at most MAX_DISPLAY_NPCS."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="test",
            npc_intents=[
                NpcIntent(npc_name=f"N{i}", intended_action="idle", adopted=True)
                for i in range(5)
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        npc_surfaces = [
            p["surfaceUpdate"]
            for p in parsed
            if p.get("surfaceUpdate", {}).get("surfaceId") == "game-npcs"
        ]
        npcs = npc_surfaces[0]["components"][0]["component"]["npcGallery"]["npcs"]
        assert len(npcs) <= 3

    @pytest.mark.asyncio
    async def test_npc_gallery_image_is_raw_storage_path(self) -> None:
        """NPC gallery imagePath should be a raw storage path."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="test",
            npc_dialogues=[
                NpcDialogue(npc_name="Wizard", dialogue="Greetings!"),
            ],
        )
        images: NpcImageMap = {"Wizard": ("npcs/wizard.png", {})}
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision, npc_images=images)
        parsed = _parse_raw_events(raw_events)

        npc_surfaces = [
            p["surfaceUpdate"]
            for p in parsed
            if p.get("surfaceUpdate", {}).get("surfaceId") == "game-npcs"
        ]
        npcs = npc_surfaces[0]["components"][0]["component"]["npcGallery"]["npcs"]
        assert npcs[0]["imagePath"] == "scenario-assets/npcs/wizard.png"

    @pytest.mark.asyncio
    async def test_state_update_image_path_stays_raw(self) -> None:
        """StateUpdate active_npcs image_path should remain a raw path."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="test",
            npc_dialogues=[
                NpcDialogue(npc_name="Elf", dialogue="Hi"),
            ],
        )
        images: NpcImageMap = {"Elf": ("npcs/elf.png", {})}
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision, npc_images=images)
        parsed = _parse_raw_events(raw_events)

        state_events = [p for p in parsed if p.get("type") == "stateUpdate"]
        assert len(state_events) == 1
        npcs = state_events[0]["data"]["active_npcs"]
        # stateUpdate should keep raw bucket-prefixed path (no full URL)
        assert npcs[0]["image_path"] == "scenario-assets/npcs/elf.png"


# ---------------------------------------------------------------------------
# Node-based stream tests
# ---------------------------------------------------------------------------


class TestStreamDecisionWithNodes:
    """Tests for stream_decision() when nodes are present."""

    @pytest.mark.asyncio
    async def test_nodes_ready_event_emitted(self) -> None:
        """When nodes present, nodesReady event should be emitted."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Summary.",
            nodes=[
                SceneNode(type="narration", text="The forest grows quiet."),
                SceneNode(
                    type="dialogue",
                    text="Hello!",
                    speaker="Innkeeper",
                    characters=[
                        CharacterDisplay(npc_name="Innkeeper", expression="joy"),
                    ],
                ),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        nodes_ready = [p for p in parsed if p.get("type") == "nodesReady"]
        assert len(nodes_ready) == 1
        assert len(nodes_ready[0]["nodes"]) == 2
        assert nodes_ready[0]["nodes"][0]["type"] == "narration"
        assert nodes_ready[0]["nodes"][1]["speaker"] == "Innkeeper"

    @pytest.mark.asyncio
    async def test_nodes_ready_includes_all_fields(self) -> None:
        """NodesReady event should include all SceneNode fields."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Summary.",
            nodes=[
                SceneNode(
                    type="dialogue",
                    text="Welcome!",
                    speaker="Guard",
                    background="tavern_01",
                    characters=[
                        CharacterDisplay(
                            npc_name="Guard",
                            expression="anger",
                            position="left",
                        ),
                    ],
                ),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        nodes_ready = [p for p in parsed if p.get("type") == "nodesReady"]
        node = nodes_ready[0]["nodes"][0]
        assert node["background"] == "tavern_01"
        assert node["characters"][0]["npc_name"] == "Guard"
        assert node["characters"][0]["position"] == "left"

    @pytest.mark.asyncio
    async def test_without_nodes_no_nodes_ready(self) -> None:
        """When nodes is None, nodesReady event should NOT be emitted."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Normal text.",
            nodes=None,
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        nodes_ready = [p for p in parsed if p.get("type") == "nodesReady"]
        assert len(nodes_ready) == 0

    @pytest.mark.asyncio
    async def test_nodes_stream_still_has_done(self) -> None:
        """Node-based stream should still end with done event."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Summary.",
            nodes=[
                SceneNode(type="narration", text="A quiet scene."),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)
        event_types = [_classify_event(p) for p in parsed]

        assert event_types[-1] == "done"

    @pytest.mark.asyncio
    async def test_nodes_stream_has_state_update(self) -> None:
        """Node-based stream should still emit stateUpdate when present."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Summary.",
            nodes=[
                SceneNode(type="narration", text="Moving on."),
            ],
            state_changes=StateChanges(
                location_change=LocationChange(
                    location_name="Cave",
                    x=10,
                    y=20,
                ),
            ),
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        state_events = [p for p in parsed if p.get("type") == "stateUpdate"]
        assert len(state_events) == 1

    @pytest.mark.asyncio
    async def test_nodes_with_text_streaming_skipped(self) -> None:
        """When nodes present, typewriter text streaming should be skipped."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="This should not stream word-by-word.",
            nodes=[
                SceneNode(type="narration", text="Node text instead."),
            ],
        )
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision)
        parsed = _parse_raw_events(raw_events)

        text_events = [p for p in parsed if p.get("type") == "text"]
        assert len(text_events) == 0


# ---------------------------------------------------------------------------
# _build_state_data extended fields tests
# ---------------------------------------------------------------------------


class TestBuildStateDataExtended:
    """Tests for extended fields in _build_state_data()."""

    def test_status_effect_adds(self) -> None:
        """Status effect additions should be included."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Cursed!",
            state_changes=StateChanges(
                status_effect_adds=["poisoned", "blinded"],
            ),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        assert result["status_effect_adds"] == ["poisoned", "blinded"]

    def test_status_effect_removes(self) -> None:
        """Status effect removals should be included."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Healed!",
            state_changes=StateChanges(
                status_effect_removes=["poisoned"],
            ),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        assert result["status_effect_removes"] == ["poisoned"]

    def test_new_items(self) -> None:
        """New items should be serialized via model_dump."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Found a sword!",
            state_changes=StateChanges(
                new_items=[
                    NewItem(
                        name="Iron Sword",
                        description="A sturdy blade",
                        item_type="weapon",
                        quantity=1,
                    ),
                ],
            ),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        items = result["new_items"]
        assert len(items) == 1
        assert items[0]["name"] == "Iron Sword"
        assert items[0]["item_type"] == "weapon"

    def test_removed_items(self) -> None:
        """Removed item names should be included."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Lost a key.",
            state_changes=StateChanges(
                removed_items=["Old Key"],
            ),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        assert result["removed_items"] == ["Old Key"]

    def test_item_updates(self) -> None:
        """Item updates should be serialized via model_dump."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Used a potion.",
            state_changes=StateChanges(
                item_updates=[
                    ItemUpdate(
                        name="Health Potion",
                        quantity_delta=-1,
                    ),
                ],
            ),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        updates = result["item_updates"]
        assert len(updates) == 1
        assert updates[0]["name"] == "Health Potion"
        assert updates[0]["quantity_delta"] == -1

    def test_relationship_changes(self) -> None:
        """Relationship changes should be serialized via model_dump."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="The guard likes you.",
            state_changes=StateChanges(
                relationship_changes=[
                    RelationshipChange(
                        npc_name="Guard",
                        affinity_delta=10,
                        trust_delta=5,
                    ),
                ],
            ),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        rels = result["relationship_changes"]
        assert len(rels) == 1
        assert rels[0]["npc_name"] == "Guard"
        assert rels[0]["affinity_delta"] == 10
        assert rels[0]["trust_delta"] == 5

    def test_objective_updates(self) -> None:
        """Objective updates should be serialized via model_dump."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Quest complete!",
            state_changes=StateChanges(
                objective_updates=[
                    ObjectiveUpdate(
                        title="Find the amulet",
                        status="completed",
                        description="Retrieved from dungeon",
                    ),
                ],
            ),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        objs = result["objective_updates"]
        assert len(objs) == 1
        assert objs[0]["title"] == "Find the amulet"
        assert objs[0]["status"] == "completed"

    def test_all_extended_fields_together(self) -> None:
        """All extended fields should coexist in state data."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Complex turn.",
            state_changes=StateChanges(
                stats_delta=[
                    StatDelta(stat="hp", delta=-10),
                    StatDelta(stat="san", delta=-5),
                ],
                status_effect_adds=["cursed"],
                status_effect_removes=["blessed"],
                new_items=[NewItem(name="Ring", description="Magic ring")],
                removed_items=["Old Ring"],
                item_updates=[ItemUpdate(name="Potion", quantity_delta=-1)],
                relationship_changes=[
                    RelationshipChange(npc_name="Elf", affinity_delta=5),
                ],
                objective_updates=[
                    ObjectiveUpdate(title="Escape", status="active"),
                ],
            ),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        assert "stats_delta" in result
        assert "status_effect_adds" in result
        assert "status_effect_removes" in result
        assert "new_items" in result
        assert "removed_items" in result
        assert "item_updates" in result
        assert "relationship_changes" in result
        assert "objective_updates" in result

    def test_empty_lists_not_included(self) -> None:
        """Empty lists in state_changes should not appear in data."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Nothing extra.",
            state_changes=StateChanges(
                stats_delta=[StatDelta(stat="hp", delta=-1)],
                status_effect_adds=None,
                new_items=None,
            ),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        assert "stats_delta" in result
        assert "status_effect_adds" not in result
        assert "new_items" not in result


# ---------------------------------------------------------------------------
# Catalog format contract tests
# ---------------------------------------------------------------------------


def _extract_surface_component(
    events: list[dict[str, Any]],
    surface_id: str,
) -> dict[str, Any]:
    """Find surfaceUpdate for given surfaceId and return the root component dict.

    Returns the dict ``{"typeName": {...properties}}`` from the first
    component's ``component`` key.
    """
    for e in events:
        su = e.get("surfaceUpdate")
        if su and su.get("surfaceId") == surface_id:
            components = su.get("components", [])
            assert len(components) == 1, (
                f"Expected 1 component in {surface_id}, got {len(components)}"
            )
            comp = components[0]
            assert comp["id"] == "root", (
                f"Component id must be 'root', got {comp['id']!r}"
            )
            return comp["component"]  # type: ignore[return-value]
    msg = f"No surfaceUpdate for surfaceId={surface_id!r} in events"
    raise AssertionError(msg)


def _extract_begin_rendering(
    events: list[dict[str, Any]],
    surface_id: str,
) -> dict[str, Any]:
    """Find beginRendering event for given surfaceId."""
    for e in events:
        br = e.get("beginRendering")
        if br and br.get("surfaceId") == surface_id:
            return br  # type: ignore[return-value]
    msg = f"No beginRendering for surfaceId={surface_id!r} in events"
    raise AssertionError(msg)


class TestCatalogFormatContract:
    """Verify backend SSE payloads exactly match the genui catalog spec.

    The genui catalog (game_catalog_items.dart) defines the component
    typenames and property keys that the frontend reads.  These tests act as
    a contract between the backend SSE emitter and the frontend catalog parser.

    Naming convention mirrors the Dart catalog:
      - camelCase property keys (imagePath, allowFreeInput, …)
      - snake_case only where Pydantic model_dump() emits it (proposed_fix)
    """

    # ------------------------------------------------------------------
    # A2UI envelope structure
    # ------------------------------------------------------------------

    def test_a2ui_envelope_surfaceupdate_schema(self) -> None:
        """SurfaceUpdate must have surfaceId and single root component."""
        result = _a2ui_surface("game-test", "testWidget", {"key": "val"})
        events = _parse_sse_events(result)
        su = events[0]["surfaceUpdate"]
        assert su["surfaceId"] == "game-test"
        components = su["components"]
        assert isinstance(components, list)
        assert len(components) == 1
        comp = components[0]
        assert set(comp.keys()) == {"id", "component"}
        assert comp["id"] == "root"
        assert comp["component"] == {"testWidget": {"key": "val"}}

    def test_a2ui_envelope_begin_rendering_schema(self) -> None:
        """BeginRendering must reference surfaceId and root id."""
        result = _a2ui_surface("game-test", "testWidget", {})
        events = _parse_sse_events(result)
        br = events[1]["beginRendering"]
        assert br["surfaceId"] == "game-test"
        assert br["root"] == "root"

    # ------------------------------------------------------------------
    # npcGallery component
    # ------------------------------------------------------------------

    @pytest.mark.asyncio
    async def test_npc_gallery_component_type_name(self) -> None:
        """NpcGallery component must be registered under key 'npcGallery'."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Guard stands watch.",
            npc_dialogues=[
                NpcDialogue(npc_name="Guard", dialogue="Halt!", emotion="stern"),
            ],
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-npcs")
        assert "npcGallery" in comp, f"Expected 'npcGallery' key, got {list(comp)}"

    @pytest.mark.asyncio
    async def test_npc_gallery_npcs_camel_case_image_path(self) -> None:
        """npcs[].imagePath must be camelCase — NOT image_path (snake_case).

        The Dart catalog reads: n['imagePath']
        """
        svc = GenuiBridgeService()
        npc_images: NpcImageMap = {
            "Guard": ("guard/default.png", {"stern": "guard/stern.png"}),
        }
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Guard speaks.",
            npc_dialogues=[
                NpcDialogue(npc_name="Guard", dialogue="Halt!", emotion="stern"),
            ],
        )
        raw = await _collect_stream(svc, decision, npc_images=npc_images)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-npcs")
        npcs = comp["npcGallery"]["npcs"]
        assert len(npcs) == 1
        npc = npcs[0]
        # Catalog reads n['imagePath'] — key must be camelCase
        assert "imagePath" in npc, f"Expected 'imagePath' key, got {list(npc)}"
        assert "image_path" not in npc, (
            "'image_path' (snake_case) must NOT appear in npcGallery npcs"
        )

    @pytest.mark.asyncio
    async def test_npc_gallery_npcs_required_fields(self) -> None:
        """npcs[*] must contain name, emotion, imagePath."""
        svc = GenuiBridgeService()
        npc_images: NpcImageMap = {
            "Merchant": ("merchant/happy.png", {}),
        }
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Merchant offers wares.",
            npc_dialogues=[
                NpcDialogue(
                    npc_name="Merchant",
                    dialogue="Buy something?",
                    emotion="happy",
                ),
            ],
        )
        raw = await _collect_stream(svc, decision, npc_images=npc_images)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-npcs")
        props = comp["npcGallery"]
        assert "npcs" in props
        assert "speakers" in props
        npc = props["npcs"][0]
        assert npc["name"] == "Merchant"
        assert npc["emotion"] == "happy"
        # imagePath should include the storage bucket prefix
        assert npc["imagePath"] == "scenario-assets/merchant/happy.png"

    @pytest.mark.asyncio
    async def test_npc_gallery_no_image_is_null(self) -> None:
        """npcs[*].imagePath should be null when no image map provided."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Unknown NPC speaks.",
            npc_dialogues=[
                NpcDialogue(npc_name="Stranger", dialogue="..."),
            ],
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-npcs")
        npc = comp["npcGallery"]["npcs"][0]
        assert npc["imagePath"] is None

    @pytest.mark.asyncio
    async def test_npc_gallery_speakers_list(self) -> None:
        """Speakers must list NPC names that have dialogues."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Two NPCs speak.",
            npc_intents=[
                NpcIntent(npc_name="Silent", intended_action="wait", adopted=True),
            ],
            npc_dialogues=[
                NpcDialogue(npc_name="Hero", dialogue="Let's go!"),
            ],
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-npcs")
        speakers = comp["npcGallery"]["speakers"]
        # Only "Hero" has a dialogue; "Silent" has only an intent
        assert speakers == ["Hero"]

    # ------------------------------------------------------------------
    # narrativePanel component
    # ------------------------------------------------------------------

    @pytest.mark.asyncio
    async def test_narrative_panel_component_type_name(self) -> None:
        """game-narration surface must use 'narrativePanel' component."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="The wind howls.",
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-narration")
        assert "narrativePanel" in comp

    @pytest.mark.asyncio
    async def test_narrative_panel_sections_structure(self) -> None:
        """sections[*] must have type, text; dialogue sections also have speaker."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Rain falls.",
            npc_dialogues=[
                NpcDialogue(npc_name="Witch", dialogue="Beware the storm."),
            ],
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-narration")
        sections = comp["narrativePanel"]["sections"]
        assert len(sections) == 2

        dialogue_section = sections[0]
        assert dialogue_section["type"] == "dialogue"
        assert dialogue_section["speaker"] == "Witch"
        assert dialogue_section["text"] == "Beware the storm."

        narration_section = sections[1]
        assert narration_section["type"] == "narration"
        assert narration_section["text"] == "Rain falls."
        # narration sections must NOT have a speaker key
        assert "speaker" not in narration_section

    @pytest.mark.asyncio
    async def test_narrative_panel_narration_only(self) -> None:
        """Narration-only decision should produce a single narration section."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="You enter the dungeon.",
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-narration")
        sections = comp["narrativePanel"]["sections"]
        assert len(sections) == 1
        assert sections[0] == {"type": "narration", "text": "You enter the dungeon."}

    # ------------------------------------------------------------------
    # choiceGroup component
    # ------------------------------------------------------------------

    @pytest.mark.asyncio
    async def test_choice_group_component_type_name(self) -> None:
        """game-surface for choice decisions must use 'choiceGroup' component."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="Choose your path.",
            nodes=[
                SceneNode(
                    type="choice",
                    text="What do you do?",
                    choices=[
                        ChoiceOption(id="a", text="Fight"),
                        ChoiceOption(id="b", text="Flee"),
                    ],
                ),
            ],
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        assert "choiceGroup" in comp

    @pytest.mark.asyncio
    async def test_choice_group_choices_fields(self) -> None:
        """choices[*] must have id, text, hint (from ChoiceOption.model_dump())."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="The merchant waits.",
            nodes=[
                SceneNode(
                    type="choice",
                    text="Pick one.",
                    choices=[
                        ChoiceOption(id="buy", text="Buy the sword", hint="costs 50g"),
                        ChoiceOption(id="leave", text="Leave"),
                    ],
                ),
            ],
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        props = comp["choiceGroup"]
        choices = props["choices"]
        assert len(choices) == 2

        c0 = choices[0]
        assert c0["id"] == "buy"
        assert c0["text"] == "Buy the sword"
        assert c0["hint"] == "costs 50g"

        c1 = choices[1]
        assert c1["id"] == "leave"
        assert c1["text"] == "Leave"
        # hint is None when not set (from model_dump())
        assert c1["hint"] is None

    @pytest.mark.asyncio
    async def test_choice_group_allow_free_input_true(self) -> None:
        """ChoiceGroup must always include allowFreeInput=True.

        The Dart catalog reads: data['allowFreeInput']
        """
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="What next?",
            nodes=[
                SceneNode(
                    type="choice",
                    text="Choose.",
                    choices=[ChoiceOption(id="x", text="Do X")],
                ),
            ],
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        props = comp["choiceGroup"]
        assert "allowFreeInput" in props
        assert props["allowFreeInput"] is True

    @pytest.mark.asyncio
    async def test_choice_group_node_not_last_still_emits(self) -> None:
        """ChoiceGroup must be emitted even when choice node is not the last node."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="Battle begins.",
            nodes=[
                SceneNode(
                    type="choice",
                    text="What do you do?",
                    choices=[
                        ChoiceOption(id="atk", text="Attack"),
                        ChoiceOption(id="def", text="Defend"),
                    ],
                ),
                # narration node AFTER choice node
                SceneNode(type="narration", text="The enemy approaches."),
            ],
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        assert "choiceGroup" in comp
        assert len(comp["choiceGroup"]["choices"]) == 2

    # ------------------------------------------------------------------
    # clarifyQuestion component
    # ------------------------------------------------------------------

    @pytest.mark.asyncio
    async def test_clarify_question_component_type_name(self) -> None:
        """game-surface for clarify decisions must use 'clarifyQuestion'."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="clarify",
            narration_text="",
            clarify_question="Do you mean the red door or the blue door?",
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        assert "clarifyQuestion" in comp

    @pytest.mark.asyncio
    async def test_clarify_question_property_key(self) -> None:
        """ClarifyQuestion must have 'question' key — NOT 'clarify_question'.

        The Dart catalog reads: data['question']
        """
        svc = GenuiBridgeService()
        question_text = "Do you mean the red door or the blue door?"
        decision = GmDecisionResponse(
            decision_type="clarify",
            narration_text="",
            clarify_question=question_text,
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        props = comp["clarifyQuestion"]
        assert "question" in props, f"Expected 'question' key, got {list(props)}"
        assert "clarify_question" not in props
        assert props["question"] == question_text

    # ------------------------------------------------------------------
    # repairConfirm component
    # ------------------------------------------------------------------

    @pytest.mark.asyncio
    async def test_repair_confirm_component_type_name(self) -> None:
        """game-surface for repair decisions must use 'repairConfirm'."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="repair",
            narration_text="",
            repair=RepairData(
                contradiction="You said you don't have the key.",
                proposed_fix="Use the lockpick instead.",
            ),
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        assert "repairConfirm" in comp

    @pytest.mark.asyncio
    async def test_repair_confirm_proposed_fix_snake_case(self) -> None:
        """RepairConfirm must use 'proposed_fix' (snake_case) — NOT 'proposedFix'.

        Pydantic model_dump() emits snake_case field names.
        The Dart catalog reads: data['proposed_fix']
        """
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="repair",
            narration_text="",
            repair=RepairData(
                contradiction="You lack the key.",
                proposed_fix="Use brute force.",
            ),
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        props = comp["repairConfirm"]
        # Must be snake_case (Pydantic model_dump default)
        assert "proposed_fix" in props, (
            f"Expected 'proposed_fix' key (snake_case), got {list(props)}"
        )
        assert "proposedFix" not in props, (
            "'proposedFix' (camelCase) must NOT appear — Dart reads 'proposed_fix'"
        )
        assert props["proposed_fix"] == "Use brute force."
        assert props["contradiction"] == "You lack the key."

    # ------------------------------------------------------------------
    # continueButton component
    # ------------------------------------------------------------------

    @pytest.mark.asyncio
    async def test_continue_button_component_type_name(self) -> None:
        """game-surface for narrate decisions must use 'continueButton'."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="You rest for the night.",
        )
        raw = [
            event
            async for event in svc.stream_decision(
                decision,
                show_continue_button=True,
                show_continue_input_cta=False,
            )
        ]
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        assert "continueButton" in comp

    @pytest.mark.asyncio
    async def test_continue_button_empty_properties(self) -> None:
        """ContinueButton must have empty properties dict {}."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Journey continues.",
        )
        raw = [
            event
            async for event in svc.stream_decision(
                decision,
                show_continue_button=True,
                show_continue_input_cta=False,
            )
        ]
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        assert comp["continueButton"] == {}

    # ------------------------------------------------------------------
    # continueOrInput component
    # ------------------------------------------------------------------

    @pytest.mark.asyncio
    async def test_continue_or_input_component_type_name(self) -> None:
        """ContinueOrInput surface must use 'continueOrInput' component."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="What will you do next?",
        )
        raw = [
            event
            async for event in svc.stream_decision(
                decision,
                show_continue_button=True,
                show_continue_input_cta=True,
            )
        ]
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        assert "continueOrInput" in comp

    @pytest.mark.asyncio
    async def test_continue_or_input_empty_properties(self) -> None:
        """ContinueOrInput must have empty properties dict {}."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Your turn.",
        )
        raw = [
            event
            async for event in svc.stream_decision(
                decision,
                show_continue_button=True,
                show_continue_input_cta=True,
            )
        ]
        events = _parse_raw_events(raw)
        comp = _extract_surface_component(events, "game-surface")
        assert comp["continueOrInput"] == {}

    # ------------------------------------------------------------------
    # Stream event sequence
    # ------------------------------------------------------------------

    @pytest.mark.asyncio
    async def test_stream_event_sequence_nodes_path(self) -> None:
        """Event order for node-based (narrate) decision must match protocol.

        Expected sequence:
          delete(game-narration), delete(game-surface),
          nodesReady,
          stateUpdate (if any),
          surfaceUpdate(game-npcs), beginRendering(game-npcs),
          surfaceUpdate(game-narration), beginRendering(game-narration),
          [surfaceUpdate(game-surface), beginRendering(game-surface),] (optional)
          done
        """
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="The world is vast.",
            nodes=[SceneNode(type="narration", text="You stand at a crossroads.")],
        )
        raw = [
            event
            async for event in svc.stream_decision(
                decision,
                show_continue_button=False,
            )
        ]
        events = _parse_raw_events(raw)

        labels = [_classify_event(e) for e in events]
        # delete x2 must come first
        assert labels[0] == "delete"
        assert labels[1] == "delete"
        assert events[0]["deleteSurface"]["surfaceId"] == "game-narration"
        assert events[1]["deleteSurface"]["surfaceId"] == "game-surface"
        # nodesReady follows immediately after deletes
        assert labels[2] == "nodesReady"
        # done must be last
        assert labels[-1] == "done"
        # game-npcs surface must appear before game-narration surface
        npcs_idx = next(
            i
            for i, e in enumerate(events)
            if e.get("surfaceUpdate", {}).get("surfaceId") == "game-npcs"
        )
        narration_idx = next(
            i
            for i, e in enumerate(events)
            if e.get("surfaceUpdate", {}).get("surfaceId") == "game-narration"
        )
        assert npcs_idx < narration_idx

    @pytest.mark.asyncio
    async def test_stream_event_sequence_choice_path(self) -> None:
        """Event order for choice decision includes game-surface after narration."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="Pick one.",
            nodes=[
                SceneNode(
                    type="choice",
                    text="Choose.",
                    choices=[ChoiceOption(id="a", text="A")],
                ),
            ],
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)

        surface_updates = [
            e["surfaceUpdate"]["surfaceId"] for e in events if "surfaceUpdate" in e
        ]
        # Must have all three surface updates in correct order
        assert surface_updates.index("game-npcs") < surface_updates.index(
            "game-narration"
        )
        assert surface_updates.index("game-narration") < surface_updates.index(
            "game-surface"
        )
        # done is last event
        assert events[-1] == {"type": "done"}

    @pytest.mark.asyncio
    async def test_stream_nodes_ready_payload(self) -> None:
        """NodesReady event must contain type='nodesReady' and nodes list."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Summary.",
            nodes=[
                SceneNode(type="narration", text="Scene 1."),
                SceneNode(type="dialogue", text="Hello!", speaker="Npc"),
            ],
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)
        nodes_ready = next((e for e in events if e.get("type") == "nodesReady"), None)
        assert nodes_ready is not None
        assert "nodes" in nodes_ready
        assert len(nodes_ready["nodes"]) == 2
        assert nodes_ready["nodes"][0]["type"] == "narration"
        assert nodes_ready["nodes"][1]["type"] == "dialogue"

    @pytest.mark.asyncio
    async def test_begin_rendering_follows_surface_update(self) -> None:
        """BeginRendering for each surface must immediately follow its surfaceUpdate."""
        svc = GenuiBridgeService()
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Test.",
        )
        raw = await _collect_stream(svc, decision)
        events = _parse_raw_events(raw)

        for i, event in enumerate(events):
            if "surfaceUpdate" in event:
                surface_id = event["surfaceUpdate"]["surfaceId"]
                # Next event must be beginRendering for the same surfaceId
                assert i + 1 < len(events), (
                    f"surfaceUpdate({surface_id}) has no following event"
                )
                next_event = events[i + 1]
                assert "beginRendering" in next_event, (
                    f"Expected beginRendering after surfaceUpdate({surface_id}), "
                    f"got {next_event}"
                )
                assert next_event["beginRendering"]["surfaceId"] == surface_id
