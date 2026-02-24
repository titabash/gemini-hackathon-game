"""Convert GM decisions to SSE events with drip-feed streaming.

Emits A2UI protocol messages (surfaceUpdate + beginRendering) for genui SDK
integration, alongside game-specific events (text, stateUpdate, imageUpdate).
"""

from __future__ import annotations

import asyncio
import json
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from collections.abc import AsyncIterator

    from domain.entity.gm_types import GmDecisionResponse

from domain.service.storage_constants import SCENARIO_ASSETS_BUCKET
from util.logging import get_logger

logger = get_logger(__name__)

# Type alias for NPC images: name -> (default_path, emotion_images_map)
NpcImageMap = dict[str, tuple[str | None, dict[str, str]]]


def _sse(payload: dict[str, Any]) -> str:
    """Format a dict as an SSE data line."""
    return f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"


def _a2ui_delete(surface_id: str) -> str:
    """Emit a deleteSurface A2UI event."""
    return _sse({"deleteSurface": {"surfaceId": surface_id}})


def _a2ui_surface(
    surface_id: str,
    component_type: str,
    properties: dict[str, Any],
) -> str:
    """Emit surfaceUpdate + beginRendering for a single-component surface.

    Component format follows A2UI spec:
    ``{"id": "root", "component": {"typeName": {properties}}}``
    """
    update = _sse(
        {
            "surfaceUpdate": {
                "surfaceId": surface_id,
                "components": [
                    {
                        "id": "root",
                        "component": {component_type: properties},
                    },
                ],
            },
        }
    )
    begin = _sse(
        {
            "beginRendering": {"surfaceId": surface_id, "root": "root"},
        }
    )
    return update + begin


class GenuiBridgeService:
    """GM decision -> SSE event stream with typewriter effect."""

    WORD_DELAY = 0.03

    async def stream_decision(
        self,
        decision: GmDecisionResponse,
        *,
        npc_images: NpcImageMap | None = None,
    ) -> AsyncIterator[str]:
        """Yield SSE events with drip-feed for typewriter UX.

        Args:
            decision: The structured GM decision.
            npc_images: Mapping of NPC name -> (default_path, emotion_map).
        """
        has_nodes = bool(decision.nodes)

        # 1. Clear previous surfaces
        yield _a2ui_delete("game-narration")
        yield _a2ui_delete("game-surface")

        if has_nodes:
            # Node-based path: emit all nodes at once for frontend NodePlayer
            yield _sse(
                {
                    "type": "nodesReady",
                    "nodes": [n.model_dump() for n in decision.nodes or []],
                }
            )
        else:
            # Legacy flat-text path: typewriter streaming
            for dialogue in decision.npc_dialogues or []:
                prefix = f"[{dialogue.npc_name}] "
                for word in self._split_words(prefix + dialogue.dialogue):
                    yield self._text_event(word)
                    await asyncio.sleep(self.WORD_DELAY)
                yield self._text_event("\n")

            for word in self._split_words(decision.narration_text):
                yield self._text_event(word)
                await asyncio.sleep(self.WORD_DELAY)

        # 3. Game state update (location, HP, scene, NPC visual data)
        state_data = self._build_state_data(
            decision,
            npc_images=npc_images,
        )
        if state_data:
            yield _sse({"type": "stateUpdate", "data": state_data})

        # 3.5. NPC gallery surface (A2UI) — raw storage paths
        npc_list = _collect_npcs(
            decision,
            npc_images,
            image_key="imagePath",
            max_npcs=MAX_DISPLAY_NPCS,
        )
        speakers = [d.npc_name for d in decision.npc_dialogues or []]
        logger.info(
            "NPC gallery surface",
            npc_count=len(npc_list),
            npc_names=[n["name"] for n in npc_list],
            image_paths=[n.get("imagePath") for n in npc_list],
            speakers=speakers,
        )
        yield _a2ui_surface(
            "game-npcs",
            "npcGallery",
            {"npcs": npc_list, "speakers": speakers},
        )

        # 4. Narration surface (A2UI) — structured sections
        sections = self._build_narration_sections(decision)
        yield _a2ui_surface(
            "game-narration",
            "narrativePanel",
            {"sections": sections},
        )

        # 5. Action surface (A2UI)
        surface_props = self._build_surface_properties(decision)
        if surface_props:
            yield _a2ui_surface(
                "game-surface",
                surface_props["type"],
                surface_props["properties"],
            )

        # 6. Done
        yield _sse({"type": "done"})

    @staticmethod
    def _text_event(word: str) -> str:
        return _sse({"type": "text", "content": word})

    @staticmethod
    def _split_words(text: str) -> list[str]:
        if not text:
            return []
        words = text.split(" ")
        if not words:
            return []
        return [w + " " for w in words[:-1]] + [words[-1]]

    @staticmethod
    def _build_narration_sections(
        decision: GmDecisionResponse,
    ) -> list[dict[str, Any]]:
        """Build typed narration sections for narrativePanel."""
        sections: list[dict[str, Any]] = [
            {
                "type": "dialogue",
                "speaker": d.npc_name,
                "text": d.dialogue,
            }
            for d in decision.npc_dialogues or []
        ]
        if decision.narration_text:
            sections.append(
                {
                    "type": "narration",
                    "text": decision.narration_text,
                }
            )
        return sections

    @staticmethod
    def _build_state_data(
        decision: GmDecisionResponse,
        *,
        npc_images: NpcImageMap | None = None,
    ) -> dict[str, Any] | None:
        """Extract game state changes for Flame canvas updates."""
        data: dict[str, Any] = {}
        if decision.scene_description:
            data["scene_description"] = decision.scene_description
        if decision.state_changes:
            sc = decision.state_changes
            if sc.location_change:
                data["location"] = sc.location_change.model_dump()
            if sc.stats_delta:
                data["stats_delta"] = sc.stats_delta

        # NPC visual data for Flame canvas (TrpgVisualState.activeNpcs)
        npc_list = _collect_npcs(
            decision,
            npc_images,
            image_key="image_path",
        )
        if npc_list:
            data["active_npcs"] = npc_list

        return data if data else None

    @staticmethod
    def _build_surface_properties(
        decision: GmDecisionResponse,
    ) -> dict[str, Any] | None:
        """Build surface component type and properties for A2UI."""
        dt = decision.decision_type
        if dt == "choice" and decision.choices:
            return {
                "type": "choiceGroup",
                "properties": {
                    "choices": [c.model_dump() for c in decision.choices],
                    "allowFreeInput": True,
                },
            }
        if dt == "clarify" and decision.clarify_question:
            return {
                "type": "clarifyQuestion",
                "properties": {"question": decision.clarify_question},
            }
        if dt == "repair" and decision.repair:
            return {
                "type": "repairConfirm",
                "properties": decision.repair.model_dump(),
            }
        if dt == "narrate":
            return {
                "type": "continueButton",
                "properties": {},
            }
        return None


MAX_DISPLAY_NPCS = 3


def _collect_npcs(
    decision: GmDecisionResponse,
    npc_images: NpcImageMap | None,
    *,
    image_key: str,
    max_npcs: int | None = None,
) -> list[dict[str, Any]]:
    """Collect NPC entries from intents and dialogues.

    Args:
        decision: The GM decision containing NPC data.
        npc_images: Mapping of NPC name -> (default_path, emotion_map).
        image_key: Key name for the image path field
            (``"imagePath"`` for A2UI, ``"image_path"`` for Flame state).
        max_npcs: Maximum number of NPCs to return.  Dialogue NPCs
            are prioritised when truncating.  ``None`` means no limit.
    """
    npc_map: dict[str, dict[str, Any]] = {}
    images = npc_images or {}

    for intent in decision.npc_intents or []:
        default_path, _emotion_map = images.get(intent.npc_name, (None, {}))
        npc_map[intent.npc_name] = {
            "name": intent.npc_name,
            "emotion": None,
            image_key: (
                f"{SCENARIO_ASSETS_BUCKET}/{default_path}" if default_path else None
            ),
        }
    for dialogue in decision.npc_dialogues or []:
        default_path, emotion_map = images.get(dialogue.npc_name, (None, {}))
        resolved = default_path
        if dialogue.emotion and dialogue.emotion in emotion_map:
            resolved = emotion_map[dialogue.emotion]
        npc_map[dialogue.npc_name] = {
            "name": dialogue.npc_name,
            "emotion": dialogue.emotion,
            image_key: (f"{SCENARIO_ASSETS_BUCKET}/{resolved}" if resolved else None),
        }

    all_npcs = list(npc_map.values())
    if max_npcs is not None and len(all_npcs) > max_npcs:
        return _truncate_npcs(all_npcs, decision, max_npcs)
    return all_npcs


def _truncate_npcs(
    npcs: list[dict[str, Any]],
    decision: GmDecisionResponse,
    limit: int,
) -> list[dict[str, Any]]:
    """Keep *limit* NPCs, prioritising those with dialogue."""
    dialogue_names = {d.npc_name for d in decision.npc_dialogues or []}
    speakers = [n for n in npcs if n["name"] in dialogue_names]
    others = [n for n in npcs if n["name"] not in dialogue_names]
    return (speakers + others)[:limit]
