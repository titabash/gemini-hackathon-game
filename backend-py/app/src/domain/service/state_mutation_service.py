"""Apply GM decision state changes to database."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import TYPE_CHECKING

from domain.entity.models import Items, Objectives
from gateway.item_gateway import ItemGateway
from gateway.npc_gateway import NpcGateway, RelationshipDelta
from gateway.objective_gateway import ObjectiveGateway
from gateway.player_character_gateway import PlayerCharacterGateway
from gateway.session_gateway import SessionGateway
from util.logging import get_logger

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session

    from domain.entity.gm_types import SessionEnd, StateChanges

logger = get_logger(__name__)


class StateMutationService:
    """Apply StateChanges from GM decision to DB."""

    def __init__(self) -> None:
        self.pc_gw = PlayerCharacterGateway()
        self.item_gw = ItemGateway()
        self.npc_gw = NpcGateway()
        self.objective_gw = ObjectiveGateway()
        self.session_gw = SessionGateway()

    def apply(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        """Apply all state mutations atomically."""
        self._apply_stats(db, session_id, changes)
        self._apply_items(db, session_id, changes)
        self._apply_item_updates(db, session_id, changes)
        self._apply_location(db, session_id, changes)
        self._apply_relationships(db, session_id, changes)
        self._apply_npc_states(db, session_id, changes)
        self._apply_npc_locations(db, session_id, changes)
        self._apply_objectives(db, session_id, changes)
        self._apply_status_effects(db, session_id, changes)
        self._apply_flags(db, session_id, changes)
        self._apply_session_end(db, session_id, changes)

    def apply_session_end(
        self,
        db: Session,
        session_id: uuid.UUID,
        session_end: SessionEnd,
    ) -> None:
        """Apply session end independently (for condition-triggered ends)."""
        logger.info(
            "Applying session end (condition-triggered)",
            session_id=str(session_id),
            ending_type=session_end.ending_type,
            ending_summary=session_end.ending_summary,
        )
        self.session_gw.update_status(
            db,
            session_id,
            status="completed",
            ending_type=session_end.ending_type,
            ending_summary=session_end.ending_summary,
        )

    def _apply_stats(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        if not changes.stats_delta:
            return
        pc = self.pc_gw.get_by_session(db, session_id)
        if pc:
            stats = dict(pc.stats)
            for key, delta in changes.stats_delta.items():
                stats[key] = stats.get(key, 0) + delta
            self.pc_gw.update_stats(db, pc.id, stats)

    def _apply_items(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        now = datetime.now(UTC)
        for item in changes.new_items or []:
            self.item_gw.create(
                db,
                Items(
                    session_id=session_id,
                    name=item.name,
                    description=item.description,
                    type=item.item_type,
                    quantity=item.quantity,
                    is_equipped=False,
                    created_at=now,
                    updated_at=now,
                ),
            )
        for name in changes.removed_items or []:
            self.item_gw.delete_by_name(db, session_id, name)

    def _apply_item_updates(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        for iu in changes.item_updates or []:
            if iu.quantity_delta is not None:
                self.item_gw.update_quantity(
                    db,
                    session_id,
                    iu.name,
                    iu.quantity_delta,
                )
            if iu.is_equipped is not None:
                self.item_gw.update_equipped(
                    db,
                    session_id,
                    iu.name,
                    is_equipped=iu.is_equipped,
                )

    def _apply_location(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        if changes.location_change is None:
            return
        pc = self.pc_gw.get_by_session(db, session_id)
        if pc:
            self.pc_gw.update_location(
                db,
                pc.id,
                changes.location_change.x,
                changes.location_change.y,
            )

    def _apply_relationships(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        npcs = self.npc_gw.get_by_session(db, session_id)
        for rc in changes.relationship_changes or []:
            npc = next((n for n in npcs if n.name == rc.npc_name), None)
            if npc is None:
                continue
            self.npc_gw.update_relationship(
                db,
                npc.id,
                RelationshipDelta(
                    affinity=rc.affinity_delta,
                    trust=rc.trust_delta,
                    fear=rc.fear_delta,
                    debt=rc.debt_delta,
                ),
            )

    def _apply_npc_states(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        if not changes.npc_state_updates:
            return
        npcs = self.npc_gw.get_by_session(db, session_id)
        for nsu in changes.npc_state_updates:
            npc = next((n for n in npcs if n.name == nsu.npc_name), None)
            if npc is None:
                continue
            self.npc_gw.update_state(db, npc.id, nsu.state)

    def _apply_npc_locations(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        if not changes.npc_location_changes:
            return
        npcs = self.npc_gw.get_by_session(db, session_id)
        for nlc in changes.npc_location_changes:
            npc = next((n for n in npcs if n.name == nlc.npc_name), None)
            if npc is None:
                continue
            self.npc_gw.update_location(db, npc.id, nlc.x, nlc.y)

    def _apply_objectives(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        now = datetime.now(UTC)
        for ou in changes.objective_updates or []:
            existing = self.objective_gw.get_active_by_session(
                db,
                session_id,
            )
            found = next((o for o in existing if o.title == ou.title), None)
            if found:
                self.objective_gw.update_status(
                    db,
                    session_id,
                    ou.title,
                    ou.status,
                )
            elif ou.status == "active":
                self.objective_gw.create(
                    db,
                    Objectives(
                        session_id=session_id,
                        title=ou.title,
                        description=ou.description or "",
                        status="active",
                        sort_order=0,
                        created_at=now,
                        updated_at=now,
                    ),
                )

    def _apply_status_effects(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        adds = changes.status_effect_adds or []
        removes = changes.status_effect_removes or []
        if not adds and not removes:
            return
        pc = self.pc_gw.get_by_session(db, session_id)
        if not pc:
            return
        effects = list(pc.status_effects or [])
        effects.extend(adds)
        effects = [e for e in effects if e not in removes]
        self.pc_gw.update_status_effects(db, pc.id, effects)

    def _apply_flags(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        if not changes.flag_changes:
            return
        sess = self.session_gw.get_by_id(db, session_id)
        if sess is None:
            return
        state = dict(sess.current_state or {})
        flags: dict[str, bool] = dict(state.get("flags", {}))
        for fc in changes.flag_changes:
            if fc.value:
                flags[fc.flag_id] = True
            else:
                flags.pop(fc.flag_id, None)
        state["flags"] = flags
        self.session_gw.update_state(db, session_id, state)

    def _apply_session_end(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        if changes.session_end is None:
            return
        logger.info(
            "Applying session end (LLM state_changes)",
            session_id=str(session_id),
            ending_type=changes.session_end.ending_type,
            ending_summary=changes.session_end.ending_summary,
        )
        self.session_gw.update_status(
            db,
            session_id,
            status="completed",
            ending_type=changes.session_end.ending_type,
            ending_summary=changes.session_end.ending_summary,
        )
