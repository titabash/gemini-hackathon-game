"""AI GM Pydantic type definitions.

Gemini構造化出力スキーマおよびゲームコンテキスト構築用の型定義。
"""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel

# --- Player Input ---


class GmTurnRequest(BaseModel):
    """Player turn input request."""

    session_id: str
    input_type: Literal["start", "do", "say", "choice", "clarify_answer"]
    input_text: str


# --- GM Decision Sub-models ---


class ChoiceOption(BaseModel):
    """Single choice option presented to the player."""

    id: str
    text: str
    hint: str | None = None


class RepairData(BaseModel):
    """Contradiction repair info."""

    contradiction: str
    proposed_fix: str


class NpcDialogue(BaseModel):
    """NPC dialogue line."""

    npc_name: str
    dialogue: str
    emotion: str | None = None


class NpcIntent(BaseModel):
    """NPC intended action for the current turn."""

    npc_name: str
    intended_action: str
    adopted: bool


class NewItem(BaseModel):
    """Item to be added to inventory."""

    name: str
    description: str
    item_type: str = ""
    quantity: int = 1


class LocationChange(BaseModel):
    """Player location change."""

    location_name: str
    x: int = 0
    y: int = 0


class RelationshipChange(BaseModel):
    """NPC relationship delta."""

    npc_name: str
    affinity_delta: int = 0
    trust_delta: int = 0
    fear_delta: int = 0
    debt_delta: int = 0


class ObjectiveUpdate(BaseModel):
    """Objective status change."""

    title: str
    status: Literal["active", "completed", "failed"]
    description: str | None = None


class SessionEnd(BaseModel):
    """Game session ending info."""

    ending_type: str
    ending_summary: str


class FlagChange(BaseModel):
    """Flag mutation requested by GM decision."""

    flag_id: str
    value: bool


class NpcStateUpdate(BaseModel):
    """NPC internal state mutation requested by GM decision."""

    npc_name: str
    state: dict[str, object]


class ItemUpdate(BaseModel):
    """Existing item mutation requested by GM decision."""

    name: str
    quantity_delta: int | None = None
    is_equipped: bool | None = None


class NpcLocationChange(BaseModel):
    """NPC location change requested by GM decision."""

    npc_name: str
    x: int
    y: int


class StateChanges(BaseModel):
    """Aggregated state mutations from a GM decision."""

    stats_delta: dict[str, int] | None = None
    new_items: list[NewItem] | None = None
    removed_items: list[str] | None = None
    item_updates: list[ItemUpdate] | None = None
    location_change: LocationChange | None = None
    relationship_changes: list[RelationshipChange] | None = None
    npc_state_updates: list[NpcStateUpdate] | None = None
    npc_location_changes: list[NpcLocationChange] | None = None
    objective_updates: list[ObjectiveUpdate] | None = None
    status_effect_adds: list[str] | None = None
    status_effect_removes: list[str] | None = None
    flag_changes: list[FlagChange] | None = None
    session_end: SessionEnd | None = None


# --- Scene Node Types (Visual Novel node-based output) ---


class CharacterDisplay(BaseModel):
    """Character display specification for a scene node."""

    npc_name: str
    expression: str | None = None  # joy, anger, sadness, pleasure, surprise
    position: str = "center"  # left, center, right


class SceneNode(BaseModel):
    """Single visual novel page with complete visual state."""

    type: Literal["narration", "dialogue", "choice"]
    text: str
    speaker: str | None = None
    background: str | None = None
    characters: list[CharacterDisplay] | None = None
    choices: list[ChoiceOption] | None = None

    # Future extension fields (field-only, no processing yet)
    cg: str | None = None
    cg_clear: bool = False
    bgm: str | None = None
    bgm_stop: bool = False
    se: str | None = None
    voice_id: str | None = None


# --- GM Decision Response (Gemini structured output) ---


class GmDecisionResponse(BaseModel):
    """Gemini構造化出力スキーマ。1回の呼出で全情報を返す."""

    decision_type: Literal["narrate", "choice", "clarify", "repair"]
    narration_text: str

    nodes: list[SceneNode] | None = None

    scene_description: str | None = None
    selected_background_id: str | None = None

    choices: list[ChoiceOption] | None = None
    clarify_question: str | None = None
    repair: RepairData | None = None

    npc_dialogues: list[NpcDialogue] | None = None
    npc_intents: list[NpcIntent] | None = None

    state_changes: StateChanges | None = None


# --- Game Context (prompt construction) ---


class BackgroundResourceSummary(BaseModel):
    """Available scene background for LLM selection."""

    id: str
    location_name: str
    description: str


class TurnSummary(BaseModel):
    """Recent turn summary for context."""

    turn_number: int
    input_type: str
    input_text: str
    decision_type: str
    narration_summary: str


class PlayerSummary(BaseModel):
    """Player character summary for context."""

    name: str
    stats: dict[str, Any]
    status_effects: list[str]
    location_x: int
    location_y: int


class NpcSummary(BaseModel):
    """NPC summary for context."""

    name: str
    profile: dict[str, Any]
    goals: dict[str, Any]
    state: dict[str, Any]
    relationship: dict[str, Any]
    location_x: int = 0
    location_y: int = 0


class ObjectiveSummary(BaseModel):
    """Objective summary for context."""

    title: str
    status: str
    description: str | None = None


class ItemSummary(BaseModel):
    """Item summary for context."""

    name: str
    item_type: str
    quantity: int


class GameContext(BaseModel):
    """Integrated game context for prompt construction."""

    scenario_title: str
    scenario_setting: str
    system_prompt: str
    win_conditions: list[dict[str, Any]]
    fail_conditions: list[dict[str, Any]]
    plot_essentials: dict[str, Any]
    short_term_summary: str
    confirmed_facts: dict[str, Any]
    recent_turns: list[TurnSummary]
    player: PlayerSummary
    active_npcs: list[NpcSummary]
    active_objectives: list[ObjectiveSummary]
    player_items: list[ItemSummary]
    current_turn_number: int
    max_turns: int = 30
    current_state: dict[str, Any]
    available_backgrounds: list[BackgroundResourceSummary] = []
