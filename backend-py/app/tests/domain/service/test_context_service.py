"""Tests for ContextService formatting and background loading."""

from __future__ import annotations

import uuid
from unittest.mock import MagicMock

from domain.entity.gm_types import NpcSummary
from domain.service.context_service import ContextService


class TestFormatNpcs:
    """Tests for _format_npcs including location data."""

    def test_format_includes_location(self) -> None:
        """NPC location should appear in formatted output."""
        npcs = [
            NpcSummary(
                name="Guard",
                profile={"role": "guard"},
                goals={"primary": "Protect"},
                state={"mood": "alert"},
                relationship={"affinity": 5},
                location_x=5,
                location_y=3,
            ),
        ]

        result = ContextService._format_npcs(npcs)

        assert "location=(5, 3)" in result

    def test_format_multiple_npcs(self) -> None:
        """Multiple NPCs should all include location."""
        npcs = [
            NpcSummary(
                name="Guard",
                profile={},
                goals={},
                state={},
                relationship={},
                location_x=5,
                location_y=3,
            ),
            NpcSummary(
                name="Merchant",
                profile={},
                goals={},
                state={},
                relationship={},
                location_x=10,
                location_y=7,
            ),
        ]

        result = ContextService._format_npcs(npcs)

        assert "location=(5, 3)" in result
        assert "location=(10, 7)" in result
        assert "Guard" in result
        assert "Merchant" in result


def _fake_bg(
    *,
    bg_id: str | None = None,
    location: str = "Cave",
    description: str = "A dark cave",
    scenario_id: str | None = None,
    session_id: str | None = None,
) -> MagicMock:
    rec = MagicMock()
    rec.id = uuid.UUID(bg_id) if bg_id else uuid.uuid4()
    rec.location_name = location
    rec.description = description
    rec.scenario_id = uuid.UUID(scenario_id) if scenario_id else None
    rec.session_id = uuid.UUID(session_id) if session_id else None
    return rec


_SCENARIO_ID = "11111111-1111-1111-1111-111111111111"
_SESSION_ID = "22222222-2222-2222-2222-222222222222"


class TestLoadBackgrounds:
    """Tests for _load_backgrounds including session-generated assets."""

    def test_includes_scenario_backgrounds(self) -> None:
        """Scenario backgrounds should be included."""
        svc = ContextService()
        svc._bg_gw.find_all_by_scenario = MagicMock(
            return_value=[
                _fake_bg(
                    location="Castle",
                    description="Grand castle",
                    scenario_id=_SCENARIO_ID,
                ),
            ],
        )
        svc._bg_gw.find_all_by_session = MagicMock(return_value=[])

        result = svc._load_backgrounds(
            MagicMock(),
            uuid.UUID(_SCENARIO_ID),
            uuid.UUID(_SESSION_ID),
        )
        assert len(result) == 1
        assert result[0].location_name == "Castle"

    def test_includes_session_backgrounds(self) -> None:
        """Session-generated backgrounds should also be included."""
        svc = ContextService()
        svc._bg_gw.find_all_by_scenario = MagicMock(return_value=[])
        svc._bg_gw.find_all_by_session = MagicMock(
            return_value=[
                _fake_bg(
                    location="Forest",
                    description="A misty forest",
                    session_id=_SESSION_ID,
                ),
            ],
        )

        result = svc._load_backgrounds(
            MagicMock(),
            uuid.UUID(_SCENARIO_ID),
            uuid.UUID(_SESSION_ID),
        )
        assert len(result) == 1
        assert result[0].location_name == "Forest"

    def test_deduplicates_by_id(self) -> None:
        """Same background ID from both queries → single entry."""
        shared_id = "33333333-3333-3333-3333-333333333333"
        bg = _fake_bg(bg_id=shared_id, location="Cave")
        svc = ContextService()
        svc._bg_gw.find_all_by_scenario = MagicMock(return_value=[bg])
        svc._bg_gw.find_all_by_session = MagicMock(return_value=[bg])

        result = svc._load_backgrounds(
            MagicMock(),
            uuid.UUID(_SCENARIO_ID),
            uuid.UUID(_SESSION_ID),
        )
        assert len(result) == 1
