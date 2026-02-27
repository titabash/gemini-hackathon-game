"""Tests for BgmService."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from unittest.mock import patch

import pytest
from sqlalchemy.exc import SQLAlchemyError

from domain.entity.models import Bgm
from domain.service.bgm_service import BgmService
from infra.fal_ace_step_client import GeneratedAudioAsset


class _FakeGateway:
    def __init__(self, cached: Bgm | None = None) -> None:
        self.cached = cached
        self.created: list[Bgm] = []

    def find_by_scenario_and_mood(
        self,
        _session: object,
        _scenario_id: uuid.UUID,
        _mood: str,
    ) -> Bgm | None:
        return self.cached

    def create(self, _session: object, record: Bgm) -> Bgm:
        self.created.append(record)
        self.cached = record
        return record

    def update(self, _session: object, record: Bgm) -> Bgm:
        self.cached = record
        return record

    def delete(self, _session: object, record: Bgm) -> None:
        if self.cached == record:
            self.cached = None


class _ErrorGateway(_FakeGateway):
    def find_by_scenario_and_mood(
        self,
        _session: object,
        _scenario_id: uuid.UUID,
        _mood: str,
    ) -> Bgm | None:
        raise SQLAlchemyError("relation missing")

    def create(self, _session: object, record: Bgm) -> Bgm:
        raise SQLAlchemyError("relation missing")

    def update(self, _session: object, record: Bgm) -> Bgm:
        raise SQLAlchemyError("relation missing")

    def delete(self, _session: object, record: Bgm) -> None:
        raise SQLAlchemyError("relation missing")


class _FakeStorage:
    def __init__(self) -> None:
        self.uploaded: list[tuple[str, bytes, str]] = []

    def upload_audio(
        self,
        path: str,
        audio_bytes: bytes,
        *,
        content_type: str = "audio/mpeg",
        **_: object,
    ) -> str:
        self.uploaded.append((path, audio_bytes, content_type))
        return path


class _FakeLyria:
    def __init__(self, chunks: list[bytes]) -> None:
        self._chunks = chunks

    async def stream_music(self, _prompt: str) -> object:
        for chunk in self._chunks:
            yield chunk

    async def generate_music(self, _prompt: str) -> bytes:
        return b"fake-mp3"


class _FakeFal:
    def __init__(self) -> None:
        self.prompts: list[str] = []

    async def generate_music(
        self,
        prompt: str,
        *,
        duration_seconds: int = 60,
    ) -> GeneratedAudioAsset:
        self.prompts.append(prompt)
        return GeneratedAudioAsset(
            audio_bytes=b"fake-audio",
            content_type="audio/mpeg",
            extension="mp3",
        )


class _SessionContext:
    def __init__(self, payload: object) -> None:
        self._payload = payload

    def __enter__(self) -> object:
        return self._payload

    def __exit__(self, *_args: object) -> None:
        return None


class TestBgmService:
    def test_enforce_instrumental_prompt_appends_constraints(self) -> None:
        prompt = BgmService._enforce_instrumental_prompt("dark strings, loopable")

        assert "instrumental only" in prompt
        assert "no vocals" in prompt
        assert "no lyrics" in prompt

    def test_get_cached_bgm_url_returns_public_url(self, monkeypatch) -> None:
        scenario_id = uuid.uuid4()
        gateway = _FakeGateway(
            cached=Bgm(
                id=uuid.uuid4(),
                scenario_id=scenario_id,
                mood="battle",
                audio_path="scenarios/abc/battle.mp3",
                prompt_used="epic",
                duration_seconds=60,
                created_at=datetime.now(UTC),
            )
        )
        monkeypatch.setenv("SUPABASE_URL", "https://demo.supabase.co")
        svc = BgmService(
            lyria_client=_FakeLyria([]),  # type: ignore[arg-type]
            fal_client=_FakeFal(),  # type: ignore[arg-type]
            storage_service=_FakeStorage(),  # type: ignore[arg-type]
            bgm_cache_gateway=gateway,  # type: ignore[arg-type]
        )

        result = svc.get_cached_bgm_url(object(), scenario_id, "battle")

        assert result is not None
        assert result.startswith("https://demo.supabase.co/storage/v1/object/public/")

    @pytest.mark.asyncio
    async def test_stream_and_cache(self) -> None:
        scenario_id = uuid.uuid4()
        pcm_chunks = [b"\x00\x00\x00\x00" * 10, b"\x00\x00\x00\x00" * 10]
        gateway = _FakeGateway()
        storage = _FakeStorage()
        svc = BgmService(
            lyria_client=_FakeLyria(pcm_chunks),  # type: ignore[arg-type]
            fal_client=_FakeFal(),  # type: ignore[arg-type]
            storage_service=storage,  # type: ignore[arg-type]
            bgm_cache_gateway=gateway,  # type: ignore[arg-type]
        )

        with patch(
            "domain.service.bgm_service.LyriaClient.pcm_to_mp3",
            return_value=b"fake-mp3",
        ):
            streamed = [
                chunk
                async for chunk in svc.stream_and_cache(
                    object(),
                    scenario_id,
                    "tension",
                    "dark strings, loopable",
                )
            ]

        assert streamed == pcm_chunks
        assert len(storage.uploaded) == 1
        assert gateway.created
        assert gateway.created[0].mood == "tension"

    @pytest.mark.asyncio
    async def test_generate_and_cache_returns_ready_url(self, monkeypatch) -> None:
        scenario_id = uuid.uuid4()
        gateway = _FakeGateway()
        storage = _FakeStorage()
        fal = _FakeFal()
        monkeypatch.setenv("SUPABASE_URL", "https://demo.supabase.co")
        svc = BgmService(
            lyria_client=_FakeLyria([]),  # type: ignore[arg-type]
            fal_client=fal,  # type: ignore[arg-type]
            storage_service=storage,  # type: ignore[arg-type]
            bgm_cache_gateway=gateway,  # type: ignore[arg-type]
        )

        url = await svc.generate_and_cache(
            object(),
            scenario_id,
            "peaceful",
            "gentle ambient, loopable",
        )

        assert url is not None
        assert "generated-bgm" in url
        assert len(storage.uploaded) == 1
        assert storage.uploaded[0][0].endswith(".mp3")
        assert storage.uploaded[0][2] == "audio/mpeg"
        assert fal.prompts
        assert "no vocals" in fal.prompts[0]
        assert "no lyrics" in fal.prompts[0]

    def test_compress_generated_audio_to_mp3_normalizes_mp3_asset(self) -> None:
        svc = BgmService(
            lyria_client=_FakeLyria([]),  # type: ignore[arg-type]
            fal_client=_FakeFal(),  # type: ignore[arg-type]
            storage_service=_FakeStorage(),  # type: ignore[arg-type]
            bgm_cache_gateway=_FakeGateway(),  # type: ignore[arg-type]
        )
        source = GeneratedAudioAsset(
            audio_bytes=b"already-mp3",
            content_type="audio/mp3",
            extension="mp3",
        )

        result = svc._compress_generated_audio_to_mp3(source)

        assert result.audio_bytes == b"already-mp3"
        assert result.content_type == "audio/mpeg"
        assert result.extension == "mp3"

    @pytest.mark.asyncio
    async def test_stream_and_cache_detached_updates_pending_record(self) -> None:
        scenario_id = uuid.uuid4()
        gateway = _FakeGateway()
        storage = _FakeStorage()
        svc = BgmService(
            lyria_client=_FakeLyria([b"\x00\x00\x00\x00" * 10]),  # type: ignore[arg-type]
            fal_client=_FakeFal(),  # type: ignore[arg-type]
            storage_service=storage,  # type: ignore[arg-type]
            bgm_cache_gateway=gateway,  # type: ignore[arg-type]
        )

        def _session_factory() -> _SessionContext:
            return _SessionContext(object())

        with patch(
            "domain.service.bgm_service.LyriaClient.pcm_to_mp3",
            return_value=b"fake-mp3",
        ):
            streamed = [
                chunk
                async for chunk in svc.stream_and_cache_detached(
                    scenario_id,
                    "mysterious",
                    "mysterious drones, loopable",
                    session_factory=_session_factory,  # type: ignore[arg-type]
                )
            ]

        assert streamed
        assert gateway.cached is not None
        assert gateway.cached.audio_path != BgmService.PENDING_AUDIO_PATH
        assert len(storage.uploaded) == 1

    def test_is_pending_true_for_pending_record(self) -> None:
        scenario_id = uuid.uuid4()
        gateway = _FakeGateway(
            cached=Bgm(
                id=uuid.uuid4(),
                scenario_id=scenario_id,
                mood="tension",
                audio_path=BgmService.PENDING_AUDIO_PATH,
                prompt_used="test",
                duration_seconds=60,
                created_at=datetime.now(UTC),
            ),
        )
        svc = BgmService(
            lyria_client=_FakeLyria([]),  # type: ignore[arg-type]
            fal_client=_FakeFal(),  # type: ignore[arg-type]
            storage_service=_FakeStorage(),  # type: ignore[arg-type]
            bgm_cache_gateway=gateway,  # type: ignore[arg-type]
        )

        assert svc.is_pending(object(), scenario_id, "tension") is True

    @pytest.mark.asyncio
    async def test_stream_and_cache_survives_cache_table_error(self) -> None:
        scenario_id = uuid.uuid4()
        svc = BgmService(
            lyria_client=_FakeLyria([b"\x00\x00\x00\x00" * 10]),  # type: ignore[arg-type]
            fal_client=_FakeFal(),  # type: ignore[arg-type]
            storage_service=_FakeStorage(),  # type: ignore[arg-type]
            bgm_cache_gateway=_ErrorGateway(),  # type: ignore[arg-type]
        )

        class _Db:
            def rollback(self) -> None:
                return None

        with patch(
            "domain.service.bgm_service.LyriaClient.pcm_to_mp3",
            return_value=b"fake-mp3",
        ):
            streamed = [
                chunk
                async for chunk in svc.stream_and_cache(
                    _Db(),
                    scenario_id,
                    "mysterious",
                    "mysterious drones, loopable",
                )
            ]

        assert streamed
