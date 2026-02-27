"""Tests for BGM controller endpoints."""

from __future__ import annotations

import uuid
from types import SimpleNamespace
from unittest.mock import patch

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql://test:test@localhost:5432/test")

    from src.app import app

    return TestClient(app)


def test_status_returns_ready_when_cached(client: TestClient) -> None:
    scenario_id = str(uuid.uuid4())
    with (
        patch("controller.bgm_controller._authorize_scenario_access"),
        patch(
            "controller.bgm_controller._bgm_service.get_cached_bgm_path",
            return_value="scenarios/a/battle.mp3",
        ),
    ):
        res = client.get(
            "/api/bgm/status",
            params={"scenario_id": scenario_id, "mood": "battle"},
        )

    assert res.status_code == 200
    assert res.json() == {
        "status": "ready",
        "path": "generated-bgm/scenarios/a/battle.mp3",
    }


def test_status_returns_not_found(client: TestClient) -> None:
    scenario_id = str(uuid.uuid4())
    with (
        patch("controller.bgm_controller._authorize_scenario_access"),
        patch(
            "controller.bgm_controller._bgm_service.get_cached_bgm_path",
            return_value=None,
        ),
        patch("controller.bgm_controller._bgm_service.is_pending", return_value=False),
    ):
        res = client.get(
            "/api/bgm/status",
            params={"scenario_id": scenario_id, "mood": "battle"},
        )

    assert res.status_code == 200
    assert res.json() == {"status": "not_found"}


def test_websocket_returns_cached_when_available(client: TestClient) -> None:
    with (
        patch("controller.bgm_controller._authorize_scenario_access"),
        patch(
            "controller.bgm_controller._bgm_service.get_cached_bgm_path",
            return_value="scenarios/a/battle.mp3",
        ),
        client.websocket_connect("/api/bgm/stream") as ws,
    ):
        ws.send_json(
            {
                "scenario_id": str(uuid.uuid4()),
                "mood": "battle",
                "music_prompt": "epic battle, loopable",
            },
        )
        message = ws.receive_json()

    assert message["type"] == "cached"
    assert message["path"] == "generated-bgm/scenarios/a/battle.mp3"


def test_authorize_allows_public_scenario() -> None:
    from controller import bgm_controller as sut

    scenario_id = uuid.uuid4()
    scenario = SimpleNamespace(is_public=True, created_by=None)
    with patch.object(sut._scenario_gw, "get_by_id", return_value=scenario):
        sut._authorize_scenario_access(
            object(),  # type: ignore[arg-type]
            scenario_id,
            auth_token=None,
            authorization_header=None,
        )


def test_authorize_rejects_private_scenario_without_user() -> None:
    from controller import bgm_controller as sut

    scenario_id = uuid.uuid4()
    scenario = SimpleNamespace(is_public=False, created_by=uuid.uuid4())
    with (
        patch.object(sut._scenario_gw, "get_by_id", return_value=scenario),
        patch("controller.bgm_controller._resolve_user_id", return_value=None),
        pytest.raises(HTTPException) as excinfo,
    ):
        sut._authorize_scenario_access(
            object(),  # type: ignore[arg-type]
            scenario_id,
            auth_token=None,
            authorization_header=None,
        )

    assert excinfo.value.status_code == 401


class _FakeSessionCtx:
    def __init__(self, *_args: object, **_kwargs: object) -> None:
        return None

    def __enter__(self) -> object:
        return object()

    def __exit__(self, *_args: object) -> None:
        return None


class _DisconnectingWebSocket:
    def __init__(self) -> None:
        self.json_payloads: list[dict[str, str]] = []
        self.closed = False

    async def send_json(self, payload: dict[str, str]) -> None:
        self.json_payloads.append(payload)

    async def close(self, *_args: object, **_kwargs: object) -> None:
        self.closed = True


class _FakeBgmService:
    def __init__(self) -> None:
        self.registered: list[tuple[uuid.UUID, str, str]] = []
        self.generated_calls = 0
        self._cached_path: str | None = None

    def get_cached_bgm_path(self, *_args: object, **_kwargs: object) -> str | None:
        return self._cached_path

    def is_pending(self, *_args: object, **_kwargs: object) -> bool:
        return False

    def register_pending_prompt(
        self,
        scenario_id: uuid.UUID,
        mood: str,
        prompt: str,
    ) -> None:
        self.registered.append((scenario_id, mood, prompt))

    async def generate_and_cache_detached(
        self,
        *_args: object,
        **_kwargs: object,
    ) -> str | None:
        self.generated_calls += 1
        self._cached_path = "scenarios/generated/battle.mp3"
        return "ignored"


@pytest.mark.asyncio
async def test_stream_and_cache_returns_cached_after_generation() -> None:
    from controller import bgm_controller as sut

    scenario_id = uuid.uuid4()
    fake_service = _FakeBgmService()
    ws = _DisconnectingWebSocket()

    with (
        patch.object(sut, "_bgm_service", fake_service),
        patch.object(sut, "Session", _FakeSessionCtx),
    ):
        await sut._stream_and_cache_bgm(
            ws,  # type: ignore[arg-type]
            scenario_id,
            "battle",
            "epic battle, loopable",
        )

    assert fake_service.generated_calls == 1
    assert fake_service.registered == [
        (scenario_id, "battle", "epic battle, loopable"),
    ]
    assert ws.json_payloads == [
        {
            "type": "cached",
            "path": "generated-bgm/scenarios/generated/battle.mp3",
            "mood": "battle",
        },
    ]
