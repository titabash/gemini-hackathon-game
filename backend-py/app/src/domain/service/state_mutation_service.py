"""Apply GM decision state changes to database."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import TYPE_CHECKING

from domain.entity.models import Items, Objectives
from gateway.item_gateway import ItemGateway
from gateway.npc_gateway import NpcGateway
from gateway.objective_gateway import ObjectiveGateway
from gateway.player_character_gateway import PlayerCharacterGateway
from gateway.session_gateway import SessionGateway

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session

    from domain.entity.gm_types import StateChanges


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
        self._apply_hp(db, session_id, changes)
        self._apply_items(db, session_id, changes)
        self._apply_location(db, session_id, changes)
        self._apply_relationships(db, changes)
        self._apply_objectives(db, session_id, changes)
        self._apply_status_effects(db, session_id, changes)
        self._apply_session_end(db, session_id, changes)

    def _apply_hp(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        if changes.hp_delta is None:
            return
        pc = self.pc_gw.get_by_session(db, session_id)
        if pc:
            stats = dict(pc.stats)
            stats["hp"] = stats.get("hp", 100) + changes.hp_delta
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
        changes: StateChanges,
    ) -> None:
        for rc in changes.relationship_changes or []:
            npcs = self.npc_gw.get_active_by_session(db, rc.npc_name)  # type: ignore[arg-type]
            # Find NPC by name across all active NPCs
            # This is a simplification; in practice we'd search by session
            self.npc_gw.update_relationship(
                db,
                npcs[0].id if npcs else None,  # type: ignore[arg-type]
                affinity_delta=rc.affinity_delta,
                trust_delta=rc.trust_delta,
                fear_delta=rc.fear_delta,
                debt_delta=rc.debt_delta,
            )

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

    def _apply_session_end(
        self,
        db: Session,
        session_id: uuid.UUID,
        changes: StateChanges,
    ) -> None:
        if changes.session_end is None:
            return
        self.session_gw.update_status(
            db,
            session_id,
            status="completed",
            ending_type=changes.session_end.ending_type,
            ending_summary=changes.session_end.ending_summary,
        )
