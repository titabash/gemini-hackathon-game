"""3-layer context management for the AI GM.

Builds GameContext from DB data, determines compression timing,
and compresses accumulated context via Gemini.
"""

from __future__ import annotations

import json
from typing import TYPE_CHECKING

from pydantic import BaseModel

from domain.entity.gm_prompts import (
    COMPRESSION_CONTEXT_TEMPLATE,
    COMPRESSION_SYSTEM_PROMPT,
    CONTEXT_TEMPLATE,
)
from domain.entity.gm_types import (
    GameContext,
    ItemSummary,
    NpcSummary,
    ObjectiveSummary,
    PlayerSummary,
    TurnSummary,
)
from gateway.context_summary_gateway import (
    ContextSummaryData,
    ContextSummaryGateway,
)
from gateway.item_gateway import ItemGateway
from gateway.npc_gateway import NpcGateway
from gateway.objective_gateway import ObjectiveGateway
from gateway.player_character_gateway import PlayerCharacterGateway
from gateway.scenario_gateway import ScenarioGateway
from gateway.session_gateway import SessionGateway
from gateway.turn_gateway import TurnGateway
from util.logging import get_logger

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session

    from infra.gemini_client import GeminiClient

logger = get_logger(__name__)

COMPRESSION_INTERVAL = 5

_DEFAULT_PLAYER = PlayerSummary(
    name="Adventurer",
    stats={},
    status_effects=[],
    location_x=0,
    location_y=0,
)


class _CompressionResult(BaseModel):
    """Structured output for context compression."""

    plot_essentials: dict[str, object]
    short_term_summary: str
    confirmed_facts: dict[str, object]


class ContextService:
    """Builds, formats, and compresses game context."""

    def __init__(self) -> None:
        self._session_gw = SessionGateway()
        self._turn_gw = TurnGateway()
        self._npc_gw = NpcGateway()
        self._pc_gw = PlayerCharacterGateway()
        self._context_gw = ContextSummaryGateway()
        self._objective_gw = ObjectiveGateway()
        self._item_gw = ItemGateway()
        self._scenario_gw = ScenarioGateway()

    def build_context(
        self,
        db: Session,
        session_id: uuid.UUID,
    ) -> GameContext:
        """Load all game state and build GameContext."""
        sess = self._session_gw.get_by_id(db, session_id)
        if sess is None:
            msg = f"Session {session_id} not found"
            raise ValueError(msg)

        scenario = self._scenario_gw.get_by_id(db, sess.scenario_id)
        if scenario is None:
            msg = f"Scenario {sess.scenario_id} not found"
            raise ValueError(msg)

        pc = self._pc_gw.get_by_session(db, session_id)

        return GameContext(
            scenario_title=scenario.title,
            scenario_setting=scenario.description,
            system_prompt="",
            win_conditions=scenario.win_conditions,
            fail_conditions=scenario.fail_conditions,
            plot_essentials=self._load_plot(db, session_id),
            short_term_summary=self._load_summary(db, session_id),
            confirmed_facts=self._load_facts(db, session_id),
            recent_turns=self._load_turns(db, session_id),
            player=self._build_player(pc) if pc else _DEFAULT_PLAYER,
            active_npcs=self._load_npcs(db, session_id),
            active_objectives=self._load_objectives(db, session_id),
            player_items=self._load_items(db, session_id),
            current_turn_number=int(sess.current_turn_number),
            current_state=sess.current_state,
        )

    def build_prompt(
        self,
        context: GameContext,
        input_type: str,
        input_text: str,
    ) -> str:
        """Format CONTEXT_TEMPLATE with GameContext fields."""
        return CONTEXT_TEMPLATE.format(
            scenario_title=context.scenario_title,
            scenario_setting=context.scenario_setting,
            system_prompt=context.system_prompt,
            win_conditions=json.dumps(context.win_conditions),
            fail_conditions=json.dumps(context.fail_conditions),
            plot_essentials=json.dumps(context.plot_essentials),
            short_term_summary=context.short_term_summary,
            confirmed_facts=json.dumps(context.confirmed_facts),
            recent_turns=self._format_turns(context.recent_turns),
            player_name=context.player.name,
            player_stats=json.dumps(context.player.stats),
            player_status_effects=", ".join(
                context.player.status_effects,
            ),
            player_x=context.player.location_x,
            player_y=context.player.location_y,
            active_npcs=self._format_npcs(context.active_npcs),
            active_objectives=self._format_objectives(
                context.active_objectives,
            ),
            player_items=self._format_items(context.player_items),
            current_turn_number=context.current_turn_number,
            current_state=json.dumps(context.current_state),
            input_type=input_type,
            input_text=input_text,
        )

    def should_compress(
        self,
        current_turn: int,
        last_updated_turn: int,
    ) -> bool:
        """Check if context compression is due."""
        return (current_turn - last_updated_turn) >= COMPRESSION_INTERVAL

    async def compress(
        self,
        db: Session,
        session_id: uuid.UUID,
        gemini: GeminiClient,
        current_turn: int,
    ) -> None:
        """Compress context via Gemini structured output."""
        ctx_rec = self._context_gw.get_by_session(db, session_id)
        prev_plot = json.dumps(
            ctx_rec.plot_essentials if ctx_rec else {},
        )
        prev_facts = json.dumps(
            ctx_rec.confirmed_facts if ctx_rec else {},
        )
        turns = self._turn_gw.get_recent(db, session_id, limit=10)
        turns_text = "\n".join(
            f"T{t.turn_number}: [{t.input_type}] {t.input_text} -> {t.gm_decision_type}"
            for t in reversed(turns)
        )

        prompt = COMPRESSION_CONTEXT_TEMPLATE.format(
            previous_plot_essentials=prev_plot,
            previous_confirmed_facts=prev_facts,
            turns_to_compress=turns_text,
        )

        result = await gemini.generate_structured(
            contents=prompt,
            system_instruction=COMPRESSION_SYSTEM_PROMPT,
            response_type=_CompressionResult,
            temperature=0.3,
        )

        self._context_gw.upsert(
            db,
            session_id,
            ContextSummaryData(
                plot_essentials=result.plot_essentials,
                short_term_summary=result.short_term_summary,
                confirmed_facts=result.confirmed_facts,
                last_updated_turn=current_turn,
            ),
        )
        logger.info(
            "Context compressed",
            session_id=str(session_id),
            turn=current_turn,
        )

    # --- private helpers ---

    def _load_plot(
        self,
        db: Session,
        session_id: uuid.UUID,
    ) -> dict:
        ctx = self._context_gw.get_by_session(db, session_id)
        return dict(ctx.plot_essentials) if ctx else {}

    def _load_summary(
        self,
        db: Session,
        session_id: uuid.UUID,
    ) -> str:
        ctx = self._context_gw.get_by_session(db, session_id)
        return str(ctx.short_term_summary) if ctx else ""

    def _load_facts(
        self,
        db: Session,
        session_id: uuid.UUID,
    ) -> dict:
        ctx = self._context_gw.get_by_session(db, session_id)
        return dict(ctx.confirmed_facts) if ctx else {}

    def _load_turns(
        self,
        db: Session,
        session_id: uuid.UUID,
    ) -> list[TurnSummary]:
        rows = self._turn_gw.get_recent(db, session_id, limit=5)
        return [
            TurnSummary(
                turn_number=int(t.turn_number),
                input_type=str(t.input_type),
                input_text=str(t.input_text),
                decision_type=str(t.gm_decision_type),
                narration_summary=str(
                    t.output.get("narration_text", ""),
                ),
            )
            for t in reversed(rows)
        ]

    @staticmethod
    def _build_player(pc: object) -> PlayerSummary:
        return PlayerSummary(
            name=pc.name,  # type: ignore[attr-defined]
            stats=pc.stats,  # type: ignore[attr-defined]
            status_effects=list(
                pc.status_effects,  # type: ignore[attr-defined]
            ),
            location_x=int(pc.location_x),  # type: ignore[attr-defined]
            location_y=int(pc.location_y),  # type: ignore[attr-defined]
        )

    def _load_npcs(
        self,
        db: Session,
        session_id: uuid.UUID,
    ) -> list[NpcSummary]:
        npcs = self._npc_gw.get_active_by_session(db, session_id)
        result: list[NpcSummary] = []
        for npc in npcs:
            pair = self._npc_gw.get_with_relationship(db, npc.id)
            rel_dict: dict = {}
            if pair and pair[1]:
                rel = pair[1]
                rel_dict = {
                    "affinity": int(rel.affinity),
                    "trust": int(rel.trust),
                    "fear": int(rel.fear),
                    "debt": int(rel.debt),
                }
            result.append(
                NpcSummary(
                    name=npc.name,
                    profile=npc.profile,
                    goals=npc.goals,
                    state=npc.state,
                    relationship=rel_dict,
                ),
            )
        return result

    def _load_objectives(
        self,
        db: Session,
        session_id: uuid.UUID,
    ) -> list[ObjectiveSummary]:
        rows = self._objective_gw.get_active_by_session(db, session_id)
        return [
            ObjectiveSummary(
                title=o.title,
                status=str(o.status),
                description=o.description or None,
            )
            for o in rows
        ]

    def _load_items(
        self,
        db: Session,
        session_id: uuid.UUID,
    ) -> list[ItemSummary]:
        rows = self._item_gw.get_by_session(db, session_id)
        return [
            ItemSummary(
                name=i.name,
                item_type=str(i.type),
                quantity=int(i.quantity),
            )
            for i in rows
        ]

    @staticmethod
    def _format_turns(turns: list[TurnSummary]) -> str:
        return "\n".join(
            f"T{t.turn_number} [{t.input_type}] {t.input_text}"
            f" -> {t.decision_type}: {t.narration_summary}"
            for t in turns
        )

    @staticmethod
    def _format_npcs(npcs: list[NpcSummary]) -> str:
        return "\n".join(
            f"- {n.name}: profile={json.dumps(n.profile)}"
            f" goals={json.dumps(n.goals)}"
            f" state={json.dumps(n.state)}"
            f" rel={json.dumps(n.relationship)}"
            for n in npcs
        )

    @staticmethod
    def _format_objectives(objs: list[ObjectiveSummary]) -> str:
        return "\n".join(
            f"- [{o.status}] {o.title}: {o.description or ''}" for o in objs
        )

    @staticmethod
    def _format_items(items: list[ItemSummary]) -> str:
        return "\n".join(f"- {i.name} ({i.item_type}) x{i.quantity}" for i in items)
