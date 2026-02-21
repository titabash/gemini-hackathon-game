"""Tests for ContextSummaryGateway."""

from __future__ import annotations

from typing import TYPE_CHECKING

from domain.entity.models import ContextSummaries
from gateway.context_summary_gateway import ContextSummaryGateway

if TYPE_CHECKING:
    from sqlmodel import Session

    from domain.entity.models import Sessions


class TestContextSummaryGateway:
    """Tests for ContextSummaryGateway operations."""

    def test_get_by_session_returns_summary(
        self,
        db_session: Session,
        seed_session: Sessions,
        seed_context_summary: ContextSummaries,
    ) -> None:
        """Verify get_by_session returns existing summary."""
        gw = ContextSummaryGateway()

        result = gw.get_by_session(db_session, seed_session.id)

        assert result is not None
        assert result.last_updated_turn == 3
        assert result.short_term_summary == "The hero entered the forest."

    def test_get_by_session_returns_none(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify get_by_session returns None when no summary exists."""
        gw = ContextSummaryGateway()

        result = gw.get_by_session(db_session, seed_session.id)

        assert result is None

    def test_upsert_creates_new_summary(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify upsert creates a summary when none exists."""
        gw = ContextSummaryGateway()

        result = gw.upsert(
            db_session,
            seed_session.id,
            plot_essentials={"event": "battle"},
            short_term_summary="A battle began.",
            confirmed_facts={"enemy": "goblin"},
            last_updated_turn=1,
        )

        assert result.session_id == seed_session.id
        assert result.plot_essentials == {"event": "battle"}
        assert result.last_updated_turn == 1

    def test_upsert_updates_existing_summary(
        self,
        db_session: Session,
        seed_session: Sessions,
        seed_context_summary: ContextSummaries,
    ) -> None:
        """Verify upsert updates an existing summary in place."""
        gw = ContextSummaryGateway()

        result = gw.upsert(
            db_session,
            seed_session.id,
            plot_essentials={"event": "victory"},
            short_term_summary="The hero won.",
            confirmed_facts={"outcome": "win"},
            last_updated_turn=5,
        )

        assert result.session_id == seed_session.id
        assert result.plot_essentials == {"event": "victory"}
        assert result.last_updated_turn == 5

        refreshed = db_session.get(ContextSummaries, seed_context_summary.id)
        assert refreshed is not None
        assert refreshed.last_updated_turn == 5
