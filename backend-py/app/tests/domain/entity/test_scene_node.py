"""Tests for SceneNode and CharacterDisplay types.

Validates the visual-novel node-based output types used by Gemini.
"""

from src.domain.entity.gm_types import (
    CharacterDisplay,
    ChoiceOption,
    SceneNode,
)


class TestCharacterDisplay:
    """Tests for CharacterDisplay model."""

    def test_minimal_creation(self) -> None:
        """CharacterDisplay with only npc_name should be valid."""
        cd = CharacterDisplay(npc_name="Guard")
        assert cd.npc_name == "Guard"
        assert cd.expression is None
        assert cd.position == "center"

    def test_full_creation(self) -> None:
        """CharacterDisplay with all fields should be valid."""
        cd = CharacterDisplay(
            npc_name="Merchant",
            expression="joy",
            position="left",
        )
        assert cd.npc_name == "Merchant"
        assert cd.expression == "joy"
        assert cd.position == "left"

    def test_json_roundtrip(self) -> None:
        """CharacterDisplay should serialize and deserialize."""
        cd = CharacterDisplay(
            npc_name="Wizard",
            expression="surprise",
            position="right",
        )
        data = cd.model_dump_json()
        restored = CharacterDisplay.model_validate_json(data)
        assert restored == cd


class TestSceneNode:
    """Tests for SceneNode model."""

    def test_narration_node(self) -> None:
        """Narration node should have type and text, no speaker."""
        node = SceneNode(
            type="narration",
            text="The forest grows quiet.",
        )
        assert node.type == "narration"
        assert node.text == "The forest grows quiet."
        assert node.speaker is None
        assert node.background is None
        assert node.characters is None
        assert node.choices is None

    def test_dialogue_node(self) -> None:
        """Dialogue node should have speaker and text."""
        node = SceneNode(
            type="dialogue",
            text="Welcome, traveler!",
            speaker="Innkeeper",
            characters=[
                CharacterDisplay(
                    npc_name="Innkeeper",
                    expression="joy",
                    position="center",
                ),
            ],
        )
        assert node.type == "dialogue"
        assert node.speaker == "Innkeeper"
        assert node.characters is not None
        assert len(node.characters) == 1
        assert node.characters[0].expression == "joy"

    def test_choice_node(self) -> None:
        """Choice node should have choices list."""
        node = SceneNode(
            type="choice",
            text="What will you do?",
            choices=[
                ChoiceOption(id="a", text="Fight"),
                ChoiceOption(id="b", text="Flee"),
            ],
        )
        assert node.type == "choice"
        assert node.choices is not None
        assert len(node.choices) == 2

    def test_node_with_background(self) -> None:
        """Node with background should store the value."""
        node = SceneNode(
            type="narration",
            text="You enter the tavern.",
            background="tavern_01",
        )
        assert node.background == "tavern_01"

    def test_node_with_background_description(self) -> None:
        """Node with background description (for generation)."""
        node = SceneNode(
            type="narration",
            text="A dark cave stretches before you.",
            background="A dimly lit cave with stalactites",
        )
        assert node.background == "A dimly lit cave with stalactites"

    def test_future_fields_default(self) -> None:
        """Future extension fields should default to None/False."""
        node = SceneNode(
            type="narration",
            text="Test.",
        )
        assert node.cg is None
        assert node.cg_clear is False
        assert node.bgm is None
        assert node.bgm_stop is False
        assert node.se is None
        assert node.voice_id is None

    def test_future_fields_explicit(self) -> None:
        """Future extension fields should accept explicit values."""
        node = SceneNode(
            type="narration",
            text="A dramatic scene.",
            cg="ending_cg_01",
            cg_clear=True,
            bgm="battle_theme",
            bgm_stop=False,
            se="sword_clash",
            voice_id="voice_001",
        )
        assert node.cg == "ending_cg_01"
        assert node.cg_clear is True
        assert node.bgm == "battle_theme"
        assert node.se == "sword_clash"
        assert node.voice_id == "voice_001"

    def test_multiple_characters(self) -> None:
        """Node should support multiple characters at different positions."""
        node = SceneNode(
            type="dialogue",
            text="The two guards exchange glances.",
            speaker="Guard A",
            characters=[
                CharacterDisplay(
                    npc_name="Guard A",
                    expression="anger",
                    position="left",
                ),
                CharacterDisplay(
                    npc_name="Guard B",
                    expression="surprise",
                    position="right",
                ),
            ],
        )
        assert node.characters is not None
        assert len(node.characters) == 2
        assert node.characters[0].position == "left"
        assert node.characters[1].position == "right"

    def test_json_roundtrip(self) -> None:
        """Full SceneNode should serialize and deserialize."""
        node = SceneNode(
            type="dialogue",
            text="Hello!",
            speaker="NPC",
            background="forest_01",
            characters=[
                CharacterDisplay(
                    npc_name="NPC",
                    expression="joy",
                    position="center",
                ),
            ],
            cg="test_cg",
            bgm="theme_01",
        )
        data = node.model_dump_json()
        restored = SceneNode.model_validate_json(data)
        assert restored == node
        assert restored.speaker == "NPC"
        assert restored.characters is not None
        assert restored.characters[0].expression == "joy"
