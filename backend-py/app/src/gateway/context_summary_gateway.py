from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from sqlmodel import select

from domain.entity.models import ContextSummaries

if TYPE_CHECKING:
    import uuid

    from sqlmodel import Session


@dataclass(frozen=True)
class ContextSummaryData:
    """Data transfer object for context summary fields."""

    plot_essentials: dict[str, object]
    short_term_summary: str
    confirmed_facts: dict[str, object]
    last_updated_turn: int


class ContextSummaryGateway:
    """Gateway for context summary database operations."""

    def get_by_session(
        self,
        session: Session,
        session_id: uuid.UUID,
    ) -> ContextSummaries | None:
        """Get the context summary for a session."""
        statement = select(ContextSummaries).where(
            ContextSummaries.session_id == session_id,
        )
        return session.exec(statement).first()

    def upsert(
        self,
        session: Session,
        session_id: uuid.UUID,
        data: ContextSummaryData,
    ) -> ContextSummaries:
        """Update if exists, create if not."""
        record = self.get_by_session(session, session_id)
        if record is not None:
            return self._update(session, record, data)
        return self._create(session, session_id, data)

    @staticmethod
    def _update(
        session: Session,
        record: ContextSummaries,
        data: ContextSummaryData,
    ) -> ContextSummaries:
        """Update an existing context summary record."""
        record.plot_essentials = data.plot_essentials
        record.short_term_summary = data.short_term_summary
        record.confirmed_facts = data.confirmed_facts
        record.last_updated_turn = data.last_updated_turn
        session.add(record)
        session.commit()
        session.refresh(record)
        return record

    @staticmethod
    def _create(
        session: Session,
        session_id: uuid.UUID,
        data: ContextSummaryData,
    ) -> ContextSummaries:
        """Create a new context summary record."""
        record = ContextSummaries(
            session_id=session_id,
            plot_essentials=data.plot_essentials,
            short_term_summary=data.short_term_summary,
            confirmed_facts=data.confirmed_facts,
            last_updated_turn=data.last_updated_turn,
        )
        session.add(record)
        session.commit()
        session.refresh(record)
        return record
