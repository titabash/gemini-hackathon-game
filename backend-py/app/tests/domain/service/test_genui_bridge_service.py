"""Tests for GenuiBridgeService.

Validates SSE event generation, A2UI protocol formatting,
helper functions (_split_words, _collect_npcs), and edge cases.
"""

from __future__ import annotations

import json
from typing import Any

import pytest

from src.domain.entity.gm_types import (
    ChoiceOption,
    GmDecisionResponse,
    LocationChange,
    NpcDialogue,
    NpcIntent,
    RepairData,
    RollData,
    StateChanges,
)
from src.domain.service.genui_bridge_service import (
    GenuiBridgeService,
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
    return payload.get("type", "unknown")


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
    npc_images: dict[str, str | None] | None = None,
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
        images = {"Wizard": "npcs/wizard.png"}
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
        images = {"Other": "other.png"}
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

    def test_hp_delta(self) -> None:
        """HP delta should be included."""
        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="Ouch!",
            state_changes=StateChanges(hp_delta=-5),
        )
        result = GenuiBridgeService._build_state_data(decision)
        assert result is not None
        assert result["hp_delta"] == -5

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
        images = {"Elf": "npcs/elf.png"}
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
        """Choice decision should return choiceGroup surface."""
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="Choose.",
            choices=[
                ChoiceOption(id="a", text="Fight"),
                ChoiceOption(id="b", text="Run"),
            ],
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "choiceGroup"
        assert len(result["properties"]["choices"]) == 2
        assert result["properties"]["allowFreeInput"] is True

    def test_roll_surface(self) -> None:
        """Roll decision should return rollPanel surface."""
        decision = GmDecisionResponse(
            decision_type="roll",
            narration_text="Roll!",
            roll=RollData(
                skill_name="strength",
                difficulty=12,
                stakes_success="You break the door.",
                stakes_failure="You hurt your shoulder.",
            ),
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is not None
        assert result["type"] == "rollPanel"
        assert result["properties"]["skill_name"] == "strength"

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

    def test_choice_without_choices_returns_none(self) -> None:
        """Choice decision without choices list should return None."""
        decision = GmDecisionResponse(
            decision_type="choice",
            narration_text="Choose.",
            choices=None,
        )
        result = GenuiBridgeService._build_surface_properties(decision)
        assert result is None


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
            choices=[ChoiceOption(id="a", text="Option A")],
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
        images: dict[str, str | None] = {"Wizard": "npcs/wizard.png"}
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
        images: dict[str, str | None] = {"Elf": "npcs/elf.png"}
        svc = GenuiBridgeService()
        svc.WORD_DELAY = 0

        raw_events = await _collect_stream(svc, decision, npc_images=images)
        parsed = _parse_raw_events(raw_events)

        state_events = [p for p in parsed if p.get("type") == "stateUpdate"]
        assert len(state_events) == 1
        npcs = state_events[0]["data"]["active_npcs"]
        # stateUpdate should keep raw bucket-prefixed path (no full URL)
        assert npcs[0]["image_path"] == "scenario-assets/npcs/elf.png"
