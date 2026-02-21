"""Convert GM decisions to SSE events with drip-feed streaming."""

from __future__ import annotations

import asyncio
import json
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import AsyncIterator

    from domain.entity.gm_types import GmDecisionResponse


class GenuiBridgeService:
    """GM decision -> SSE event stream with typewriter effect."""

    WORD_DELAY = 0.03

    async def stream_decision(
        self,
        decision: GmDecisionResponse,
    ) -> AsyncIterator[str]:
        """Yield SSE events with drip-feed for typewriter UX."""
        for dialogue in decision.npc_dialogues or []:
            prefix = f"[{dialogue.npc_name}] "
            for word in self._split_words(prefix + dialogue.dialogue):
                yield self._text_event(word)
                await asyncio.sleep(self.WORD_DELAY)

        for word in self._split_words(decision.narration_text):
            yield self._text_event(word)
            await asyncio.sleep(self.WORD_DELAY)

        state_data = self._build_state_data(decision)
        if state_data:
            yield f"data: {json.dumps({'type': 'stateUpdate', 'data': state_data})}\n\n"

        surface = self._build_surface(decision)
        if surface:
            yield f"data: {json.dumps(surface)}\n\n"

        yield 'data: {"type": "done"}\n\n'

    @staticmethod
    def _text_event(word: str) -> str:
        return f"data: {json.dumps({'type': 'text', 'content': word})}\n\n"

    @staticmethod
    def _split_words(text: str) -> list[str]:
        words = text.split(" ")
        if not words:
            return []
        return [w + " " for w in words[:-1]] + [words[-1]]

    @staticmethod
    def _build_state_data(decision: GmDecisionResponse) -> dict | None:
        """Extract game state changes for Flame canvas updates."""
        data: dict = {}
        if decision.scene_description:
            data["scene_description"] = decision.scene_description
        if decision.state_changes:
            sc = decision.state_changes
            if sc.location_change:
                data["location"] = sc.location_change.model_dump()
            if sc.hp_delta is not None:
                data["hp_delta"] = sc.hp_delta
        if decision.npc_dialogues:
            data["active_npcs"] = [
                {"name": d.npc_name, "emotion": d.emotion}
                for d in decision.npc_dialogues
            ]
        return data if data else None

    @staticmethod
    def _build_surface(
        decision: GmDecisionResponse,
    ) -> dict | None:
        dt = decision.decision_type
        if dt == "choice" and decision.choices:
            return {
                "type": "surfaceUpdate",
                "component": "choiceGroup",
                "data": {
                    "choices": [c.model_dump() for c in decision.choices],
                    "allowFreeInput": True,
                },
            }
        if dt == "roll" and decision.roll:
            return {
                "type": "surfaceUpdate",
                "component": "rollPanel",
                "data": decision.roll.model_dump(),
            }
        if dt == "clarify" and decision.clarify_question:
            return {
                "type": "surfaceUpdate",
                "component": "clarifyQuestion",
                "data": {"question": decision.clarify_question},
            }
        if dt == "repair" and decision.repair:
            return {
                "type": "surfaceUpdate",
                "component": "repairConfirm",
                "data": decision.repair.model_dump(),
            }
        if dt == "narrate":
            return {
                "type": "surfaceUpdate",
                "component": "continueButton",
                "data": {},
            }
        return None
