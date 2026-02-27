"""Tests for FalAceStepClient."""

from __future__ import annotations

from typing import Any

import pytest

from src.infra.fal_ace_step_client import FalAceStepClient


class _FakeFalSyncClient:
    def __init__(self) -> None:
        self.calls: list[tuple[str, dict[str, Any]]] = []

    def subscribe(self, application: str, arguments: dict[str, Any]) -> dict[str, Any]:
        self.calls.append((application, arguments))
        return {
            "audio": {
                "url": "https://cdn.example.com/generated.wav",
                "content_type": "audio/wav",
                "file_name": "generated.wav",
            },
        }


class _RetryFalSyncClient:
    def __init__(self) -> None:
        self.calls: list[tuple[str, dict[str, Any]]] = []

    def subscribe(self, application: str, arguments: dict[str, Any]) -> dict[str, Any]:
        self.calls.append((application, arguments))
        if len(self.calls) == 1:
            raise RuntimeError("duration not accepted")
        return {
            "audio": {
                "url": "https://cdn.example.com/generated.wav",
                "content_type": "audio/wav",
                "file_name": "generated.wav",
            },
        }


@pytest.mark.asyncio
async def test_generate_music_returns_audio_asset(monkeypatch) -> None:
    monkeypatch.setenv("FAL_API_KEY", "test-key")
    fake_client = _FakeFalSyncClient()
    client = FalAceStepClient(client=fake_client)  # type: ignore[arg-type]

    async def _fake_download(_audio_url: str) -> tuple[bytes, str]:
        return b"wav-bytes", "audio/wav"

    monkeypatch.setattr(client, "_download_audio", _fake_download)

    generated = await client.generate_music(
        "dark ambient detective soundtrack, loopable",
        duration_seconds=60,
    )

    assert generated.audio_bytes == b"wav-bytes"
    assert generated.content_type == "audio/wav"
    assert generated.extension == "wav"
    assert fake_client.calls[0][0] == "fal-ai/ace-step/prompt-to-audio"
    assert fake_client.calls[0][1]["prompt"].startswith("dark ambient")
    assert fake_client.calls[0][1]["duration"] == 60


@pytest.mark.asyncio
async def test_generate_music_retries_without_duration(monkeypatch) -> None:
    monkeypatch.setenv("FAL_API_KEY", "test-key")
    fake_client = _RetryFalSyncClient()
    client = FalAceStepClient(client=fake_client)  # type: ignore[arg-type]

    async def _fake_download(_audio_url: str) -> tuple[bytes, str]:
        return b"wav-bytes", "audio/wav"

    monkeypatch.setattr(client, "_download_audio", _fake_download)

    generated = await client.generate_music(
        "tense dungeon exploration soundtrack, loopable",
        duration_seconds=60,
    )

    assert generated.audio_bytes == b"wav-bytes"
    assert len(fake_client.calls) == 2
    assert "duration" in fake_client.calls[0][1]
    assert fake_client.calls[1][1] == {
        "prompt": "tense dungeon exploration soundtrack, loopable",
    }


@pytest.mark.asyncio
async def test_generate_music_ignores_octet_stream_header(monkeypatch) -> None:
    monkeypatch.setenv("FAL_API_KEY", "test-key")
    fake_client = _FakeFalSyncClient()
    client = FalAceStepClient(client=fake_client)  # type: ignore[arg-type]

    async def _fake_download(_audio_url: str) -> tuple[bytes, str]:
        return b"wav-bytes", "application/octet-stream"

    monkeypatch.setattr(client, "_download_audio", _fake_download)

    generated = await client.generate_music(
        "mysterious noir soundtrack, loopable",
        duration_seconds=60,
    )

    assert generated.audio_bytes == b"wav-bytes"
    assert generated.content_type == "audio/wav"
    assert generated.extension == "wav"


def test_init_raises_without_fal_key(monkeypatch) -> None:
    monkeypatch.delenv("FAL_KEY", raising=False)
    monkeypatch.delenv("FAL_API_KEY", raising=False)

    with pytest.raises(ValueError, match="FAL_KEY or FAL_API_KEY"):
        FalAceStepClient()
