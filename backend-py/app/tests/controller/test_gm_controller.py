"""Tests for GM controller endpoints."""

from __future__ import annotations

import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql://test:test@localhost:5432/test")

    from src.app import app

    return TestClient(app)


def _mock_use_case(return_value: object) -> MagicMock:
    """Return a MagicMock that replaces GmTurnUseCase class.

    When the controller calls ``GmTurnUseCase()``, the mock class is called and
    returns a mock instance whose ``get_latest_turn`` is pre-configured.
    """
    mock_instance = MagicMock()
    mock_instance.get_latest_turn.return_value = return_value
    return MagicMock(return_value=mock_instance)


class TestGetLatestTurn:
    """Tests for GET /api/gm/turn/latest."""

    def test_returns_404_when_no_turns(self, client: TestClient) -> None:
        """Returns 404 when no turns exist for the session."""
        session_id = str(uuid.uuid4())
        with patch(
            "controller.gm_controller.GmTurnUseCase",
            _mock_use_case(None),
        ):
            res = client.get(
                "/api/gm/turn/latest",
                params={"session_id": session_id},
            )

        assert res.status_code == 404

    def test_returns_latest_turn_with_nodes(self, client: TestClient) -> None:
        """Returns latest turn data including nodes when available."""
        from domain.entity.gm_types import LatestTurnResponse

        session_id = str(uuid.uuid4())
        fake_response = LatestTurnResponse(
            turn_number=7,
            decision_type="narrate",
            nodes=[
                {
                    "type": "narration",
                    "text": "The darkness closes in...",
                    "speaker": None,
                    "background": None,
                    "characters": None,
                    "choices": None,
                    "cg": None,
                    "cg_clear": False,
                    "bgm": None,
                    "bgm_stop": False,
                    "se": None,
                    "voice_id": None,
                }
            ],
            is_ending=True,
            requires_user_action=False,
        )
        with patch(
            "controller.gm_controller.GmTurnUseCase",
            _mock_use_case(fake_response),
        ):
            res = client.get(
                "/api/gm/turn/latest",
                params={"session_id": session_id},
            )

        assert res.status_code == 200
        data = res.json()
        assert data["turn_number"] == 7
        assert data["decision_type"] == "narrate"
        assert data["is_ending"] is True
        assert data["requires_user_action"] is False
        assert len(data["nodes"]) == 1
        assert data["nodes"][0]["text"] == "The darkness closes in..."

    def test_returns_latest_turn_without_nodes(self, client: TestClient) -> None:
        """Returns latest turn data with nodes=None for text-only turns."""
        from domain.entity.gm_types import LatestTurnResponse

        session_id = str(uuid.uuid4())
        fake_response = LatestTurnResponse(
            turn_number=3,
            decision_type="choice",
            nodes=None,
            is_ending=False,
            requires_user_action=True,
        )
        with patch(
            "controller.gm_controller.GmTurnUseCase",
            _mock_use_case(fake_response),
        ):
            res = client.get(
                "/api/gm/turn/latest",
                params={"session_id": session_id},
            )

        assert res.status_code == 200
        data = res.json()
        assert data["turn_number"] == 3
        assert data["nodes"] is None
        assert data["requires_user_action"] is True
