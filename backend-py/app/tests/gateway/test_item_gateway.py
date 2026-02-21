"""Tests for ItemGateway."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from gateway.item_gateway import ItemGateway

from domain.entity.models import Items
from tests.gateway.conftest import _now

if TYPE_CHECKING:
    from sqlmodel import Session

    from domain.entity.models import Sessions


class TestItemGateway:
    """Tests for ItemGateway operations."""

    def test_get_by_session(
        self,
        db_session: Session,
        seed_session: Sessions,
        seed_item: Items,
    ) -> None:
        """Verify get_by_session returns all items for the session."""
        gw = ItemGateway()

        result = gw.get_by_session(db_session, seed_session.id)

        assert len(result) == 1
        assert result[0].name == "Health Potion"
        assert result[0].quantity == 3

    def test_create_persists_item(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify create persists a new item."""
        gw = ItemGateway()
        item = Items(
            id=uuid.uuid4(),
            session_id=seed_session.id,
            name="Iron Sword",
            description="A sturdy blade.",
            type="weapon",
            quantity=1,
            is_equipped=False,
            created_at=_now(),
            updated_at=_now(),
        )

        result = gw.create(db_session, item)

        assert result.name == "Iron Sword"
        assert result.type == "weapon"

    def test_delete_by_name(
        self,
        db_session: Session,
        seed_session: Sessions,
        seed_item: Items,
    ) -> None:
        """Verify delete_by_name removes the matching item."""
        gw = ItemGateway()

        gw.delete_by_name(db_session, seed_session.id, "Health Potion")

        remaining = gw.get_by_session(db_session, seed_session.id)
        assert remaining == []

    def test_update_quantity(
        self,
        db_session: Session,
        seed_session: Sessions,
        seed_item: Items,
    ) -> None:
        """Verify update_quantity applies a delta to the item quantity."""
        gw = ItemGateway()

        gw.update_quantity(
            db_session, seed_session.id, "Health Potion", quantity_delta=-1
        )

        refreshed = db_session.get(Items, seed_item.id)
        assert refreshed is not None
        assert refreshed.quantity == 2
