"""Tests for PlayerCharacterGateway."""

from __future__ import annotations

from typing import TYPE_CHECKING

from domain.entity.models import PlayerCharacters
from gateway.player_character_gateway import PlayerCharacterGateway

if TYPE_CHECKING:
    from sqlmodel import Session

    from domain.entity.models import Sessions


class TestPlayerCharacterGateway:
    """Tests for PlayerCharacterGateway operations."""

    def test_get_by_session_returns_pc(
        self,
        db_session: Session,
        seed_session: Sessions,
        seed_player_character: PlayerCharacters,
    ) -> None:
        """Verify get_by_session returns the player character."""
        gw = PlayerCharacterGateway()

        result = gw.get_by_session(db_session, seed_session.id)

        assert result is not None
        assert result.name == "Hero"

    def test_get_by_session_returns_none(
        self, db_session: Session, seed_session: Sessions
    ) -> None:
        """Verify get_by_session returns None when no PC exists."""
        gw = PlayerCharacterGateway()

        result = gw.get_by_session(db_session, seed_session.id)

        assert result is None

    def test_update_stats(
        self,
        db_session: Session,
        seed_player_character: PlayerCharacters,
    ) -> None:
        """Verify update_stats overwrites stats JSON."""
        gw = PlayerCharacterGateway()
        new_stats = {"str": 15, "dex": 12, "int": 14, "hp": 100}

        gw.update_stats(db_session, seed_player_character.id, new_stats)

        refreshed = db_session.get(PlayerCharacters, seed_player_character.id)
        assert refreshed is not None
        assert refreshed.stats == new_stats

    def test_update_location(
        self,
        db_session: Session,
        seed_player_character: PlayerCharacters,
    ) -> None:
        """Verify update_location sets x and y coordinates."""
        gw = PlayerCharacterGateway()

        gw.update_location(db_session, seed_player_character.id, x=10, y=20)

        refreshed = db_session.get(PlayerCharacters, seed_player_character.id)
        assert refreshed is not None
        assert refreshed.location_x == 10
        assert refreshed.location_y == 20

    def test_update_status_effects(
        self,
        db_session: Session,
        seed_player_character: PlayerCharacters,
    ) -> None:
        """Verify update_status_effects replaces the list."""
        gw = PlayerCharacterGateway()
        effects = ["poisoned", "stunned"]

        gw.update_status_effects(db_session, seed_player_character.id, effects)

        refreshed = db_session.get(PlayerCharacters, seed_player_character.id)
        assert refreshed is not None
        assert refreshed.status_effects == effects
