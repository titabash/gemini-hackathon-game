"""Item data access gateway."""

from __future__ import annotations

from typing import TYPE_CHECKING

from sqlmodel import select

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session

from domain.entity.models import Items


class ItemGateway:
    """Gateway for item CRUD operations."""

    def get_by_session(
        self,
        session: Session,
        session_id: uuid.UUID,
    ) -> list[Items]:
        statement = select(Items).where(Items.session_id == session_id)
        return list(session.exec(statement).all())

    def create(self, session: Session, item: Items) -> Items:
        session.add(item)
        session.commit()
        session.refresh(item)
        return item

    def delete_by_name(
        self,
        session: Session,
        session_id: uuid.UUID,
        name: str,
    ) -> None:
        statement = select(Items).where(
            Items.session_id == session_id,
            Items.name == name,
        )
        item = session.exec(statement).first()
        if item:
            session.delete(item)
            session.commit()

    def update_quantity(
        self,
        session: Session,
        session_id: uuid.UUID,
        name: str,
        quantity_delta: int,
    ) -> None:
        statement = select(Items).where(
            Items.session_id == session_id,
            Items.name == name,
        )
        item = session.exec(statement).first()
        if item:
            item.quantity += quantity_delta
            session.add(item)
            session.commit()

    def update_equipped(
        self,
        session: Session,
        session_id: uuid.UUID,
        name: str,
        *,
        is_equipped: bool,
    ) -> None:
        """Update the equipped status of an item."""
        statement = select(Items).where(
            Items.session_id == session_id,
            Items.name == name,
        )
        item = session.exec(statement).first()
        if item:
            item.is_equipped = is_equipped
            session.add(item)
            session.commit()
