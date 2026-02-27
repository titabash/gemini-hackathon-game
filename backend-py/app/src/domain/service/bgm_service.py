"""BGM generation and cache orchestration service."""

from __future__ import annotations

import io
import os
import uuid
from datetime import UTC, datetime
from typing import TYPE_CHECKING, ClassVar

from pydub import AudioSegment
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from domain.entity.models import Bgm
from gateway.bgm_cache_gateway import BgmCacheGateway
from infra.fal_ace_step_client import FalAceStepClient, GeneratedAudioAsset
from infra.lyria_client import LyriaClient
from infra.storage_service import StorageService
from util.logging import get_logger

if TYPE_CHECKING:
    from collections.abc import AsyncIterator, Callable

    from sqlmodel import Session

logger = get_logger(__name__)


class BgmService:
    """Service that generates, streams, and caches BGM assets."""

    DEFAULT_DURATION_SECONDS = 60
    DEFAULT_MP3_BITRATE = "128k"
    INSTRUMENTAL_PROMPT_SUFFIX = (
        "instrumental only, no vocals, no lyrics, no singing, no spoken voice"
    )
    PENDING_AUDIO_PATH = "__pending__"
    _pending_prompts: ClassVar[dict[tuple[str, str], str]] = {}
    _generating: ClassVar[set[tuple[str, str]]] = set()

    def __init__(
        self,
        *,
        lyria_client: LyriaClient | None = None,
        fal_client: FalAceStepClient | None = None,
        storage_service: StorageService | None = None,
        bgm_cache_gateway: BgmCacheGateway | None = None,
    ) -> None:
        self._lyria = lyria_client
        self._fal = fal_client
        self._storage = storage_service
        self._bgm_cache_gw = bgm_cache_gateway or BgmCacheGateway()

    def register_pending_prompt(
        self,
        scenario_id: uuid.UUID,
        mood: str,
        music_prompt: str,
    ) -> None:
        """Register generation intent for polling fallback."""
        key = self._key(scenario_id, mood)
        self._pending_prompts[key] = self._enforce_instrumental_prompt(music_prompt)

    def consume_pending_prompt(
        self,
        scenario_id: uuid.UUID,
        mood: str,
    ) -> str | None:
        """Consume and return pending prompt for scenario+mood."""
        return self._pending_prompts.pop(self._key(scenario_id, mood), None)

    def peek_pending_prompt(
        self,
        scenario_id: uuid.UUID,
        mood: str,
    ) -> str | None:
        """Return pending prompt without consuming it."""
        return self._pending_prompts.get(self._key(scenario_id, mood))

    def is_generating(
        self,
        scenario_id: uuid.UUID,
        mood: str,
    ) -> bool:
        """Return whether scenario+mood is being generated."""
        return self._key(scenario_id, mood) in self._generating

    def get_cached_bgm_path(
        self,
        db: Session,
        scenario_id: uuid.UUID,
        mood: str,
    ) -> str | None:
        """Return cached storage path if present."""
        record = self._safe_find_record(
            db,
            scenario_id,
            self._normalize_mood(mood),
        )
        if not record:
            return None
        if record.audio_path == self.PENDING_AUDIO_PATH:
            return None
        return record.audio_path

    def is_pending(
        self,
        db: Session,
        scenario_id: uuid.UUID,
        mood: str,
    ) -> bool:
        """Return whether scenario+mood is currently pending generation."""
        record = self._safe_find_record(
            db,
            scenario_id,
            self._normalize_mood(mood),
        )
        if not record:
            return False
        return record.audio_path == self.PENDING_AUDIO_PATH

    def get_cached_bgm_url(
        self,
        db: Session,
        scenario_id: uuid.UUID,
        mood: str,
    ) -> str | None:
        """Return cached public URL if present."""
        path = self.get_cached_bgm_path(db, scenario_id, mood)
        if not path:
            return None
        return self._to_public_url(path)

    async def stream_and_cache(
        self,
        db: Session,
        scenario_id: uuid.UUID,
        mood: str,
        music_prompt: str,
    ) -> AsyncIterator[bytes]:
        """Yield PCM chunks while saving final MP3 cache."""
        normalized = self._normalize_mood(mood)
        instrumental_prompt = self._enforce_instrumental_prompt(music_prompt)
        cache_enabled = True
        try:
            if self.get_cached_bgm_path(db, scenario_id, normalized):
                return
        except Exception as exc:
            cache_enabled = False
            logger.warning(
                "BGM cache lookup failed; streaming without cache",
                scenario_id=str(scenario_id),
                mood=normalized,
                error=str(exc),
            )
        if self.is_generating(scenario_id, normalized):
            return

        key = self._key(scenario_id, normalized)
        self._generating.add(key)
        chunks: list[bytes] = []
        try:
            async for chunk in self._lyria_client.stream_music(instrumental_prompt):
                chunks.append(chunk)
                yield chunk
            if not chunks:
                return
            if not cache_enabled:
                return
            mp3_bytes = LyriaClient.pcm_to_mp3(b"".join(chunks))
            generated = GeneratedAudioAsset(
                audio_bytes=mp3_bytes,
                content_type="audio/mpeg",
                extension="mp3",
            )
            try:
                self._save_cache_record(
                    db,
                    scenario_id,
                    normalized,
                    instrumental_prompt,
                    generated,
                )
            except Exception as exc:
                logger.warning(
                    "BGM cache save failed after streaming",
                    scenario_id=str(scenario_id),
                    mood=normalized,
                    error=str(exc),
                )
        finally:
            self._generating.discard(key)
            self._pending_prompts.pop(key, None)

    async def generate_and_cache(
        self,
        db: Session,
        scenario_id: uuid.UUID,
        mood: str,
        music_prompt: str,
    ) -> str | None:
        """Generate full audio and cache it without streaming."""
        normalized = self._normalize_mood(mood)
        instrumental_prompt = self._enforce_instrumental_prompt(music_prompt)
        cache_enabled = True
        try:
            cached = self.get_cached_bgm_url(db, scenario_id, normalized)
            if cached:
                return cached
        except Exception as exc:
            cache_enabled = False
            logger.warning(
                "BGM cache lookup failed; generating without cache",
                scenario_id=str(scenario_id),
                mood=normalized,
                error=str(exc),
            )
        if self.is_generating(scenario_id, normalized):
            return None

        key = self._key(scenario_id, normalized)
        self._generating.add(key)
        try:
            generated = await self._fal_client.generate_music(
                instrumental_prompt,
                duration_seconds=self.DEFAULT_DURATION_SECONDS,
            )
            if not generated.audio_bytes:
                return None
            generated = self._compress_generated_audio_to_mp3(generated)
            if not cache_enabled:
                return None
            try:
                path = self._save_cache_record(
                    db,
                    scenario_id,
                    normalized,
                    instrumental_prompt,
                    generated,
                )
            except Exception as exc:
                logger.warning(
                    "BGM cache save failed after generate",
                    scenario_id=str(scenario_id),
                    mood=normalized,
                    error=str(exc),
                )
                return None
            return self._to_public_url(path)
        finally:
            self._generating.discard(key)
            self._pending_prompts.pop(key, None)

    async def stream_and_cache_detached(  # noqa: C901
        self,
        scenario_id: uuid.UUID,
        mood: str,
        music_prompt: str,
        *,
        session_factory: Callable[[], Session],
    ) -> AsyncIterator[bytes]:
        """Stream PCM chunks and cache final MP3 without holding DB connection."""
        normalized = self._normalize_mood(mood)
        instrumental_prompt = self._enforce_instrumental_prompt(music_prompt)
        if self.is_generating(scenario_id, normalized):
            return

        key = self._key(scenario_id, normalized)
        self._generating.add(key)
        chunks: list[bytes] = []
        completed = False
        slot_acquired = False
        cache_enabled = True
        try:
            try:
                with session_factory() as db:
                    if self.get_cached_bgm_path(db, scenario_id, normalized):
                        return
                    slot_acquired = self._try_begin_generation(
                        db,
                        scenario_id,
                        normalized,
                        instrumental_prompt,
                    )
                if not slot_acquired:
                    return
            except Exception as exc:
                cache_enabled = False
                logger.warning(
                    "BGM cache unavailable; streaming without cache",
                    scenario_id=str(scenario_id),
                    mood=normalized,
                    error=str(exc),
                )

            async for chunk in self._lyria_client.stream_music(instrumental_prompt):
                chunks.append(chunk)
                yield chunk

            if not chunks:
                return
            if not cache_enabled:
                return

            mp3_bytes = LyriaClient.pcm_to_mp3(b"".join(chunks))
            generated = GeneratedAudioAsset(
                audio_bytes=mp3_bytes,
                content_type="audio/mpeg",
                extension="mp3",
            )
            try:
                with session_factory() as db:
                    self._save_cache_record(
                        db,
                        scenario_id,
                        normalized,
                        instrumental_prompt,
                        generated,
                    )
                completed = True
            except Exception as exc:
                logger.warning(
                    "BGM cache save failed after detached stream",
                    scenario_id=str(scenario_id),
                    mood=normalized,
                    error=str(exc),
                )
        finally:
            if slot_acquired and cache_enabled and not completed:
                try:
                    with session_factory() as db:
                        self._clear_pending_record(db, scenario_id, normalized)
                except Exception as exc:
                    logger.warning(
                        "BGM pending slot cleanup failed",
                        scenario_id=str(scenario_id),
                        mood=normalized,
                        error=str(exc),
                    )
            self._generating.discard(key)
            self._pending_prompts.pop(key, None)

    async def generate_and_cache_detached(  # noqa: PLR0911
        self,
        scenario_id: uuid.UUID,
        mood: str,
        music_prompt: str,
        *,
        session_factory: Callable[[], Session],
    ) -> str | None:
        """Generate full audio and cache it without holding DB connection."""
        normalized = self._normalize_mood(mood)
        instrumental_prompt = self._enforce_instrumental_prompt(music_prompt)
        if self.is_generating(scenario_id, normalized):
            return None

        key = self._key(scenario_id, normalized)
        self._generating.add(key)
        completed = False
        slot_acquired = False
        cache_enabled = True
        try:
            try:
                with session_factory() as db:
                    cached = self.get_cached_bgm_url(db, scenario_id, normalized)
                    if cached:
                        return cached
                    slot_acquired = self._try_begin_generation(
                        db,
                        scenario_id,
                        normalized,
                        instrumental_prompt,
                    )
                if not slot_acquired:
                    with session_factory() as db:
                        return self.get_cached_bgm_url(db, scenario_id, normalized)
            except Exception as exc:
                cache_enabled = False
                logger.warning(
                    "BGM cache unavailable; generating without cache",
                    scenario_id=str(scenario_id),
                    mood=normalized,
                    error=str(exc),
                )

            generated = await self._fal_client.generate_music(
                instrumental_prompt,
                duration_seconds=self.DEFAULT_DURATION_SECONDS,
            )
            if not generated.audio_bytes:
                return None
            generated = self._compress_generated_audio_to_mp3(generated)
            if not cache_enabled:
                return None

            try:
                with session_factory() as db:
                    path = self._save_cache_record(
                        db,
                        scenario_id,
                        normalized,
                        instrumental_prompt,
                        generated,
                    )
                completed = True
                return self._to_public_url(path)
            except Exception as exc:
                logger.warning(
                    "BGM cache save failed after detached generate",
                    scenario_id=str(scenario_id),
                    mood=normalized,
                    error=str(exc),
                )
                return None
        finally:
            if slot_acquired and cache_enabled and not completed:
                try:
                    with session_factory() as db:
                        self._clear_pending_record(db, scenario_id, normalized)
                except Exception as exc:
                    logger.warning(
                        "BGM pending slot cleanup failed",
                        scenario_id=str(scenario_id),
                        mood=normalized,
                        error=str(exc),
                    )
            self._generating.discard(key)
            self._pending_prompts.pop(key, None)

    def _save_cache_record(
        self,
        db: Session,
        scenario_id: uuid.UUID,
        mood: str,
        music_prompt: str,
        generated: GeneratedAudioAsset,
    ) -> str:
        path = self._build_storage_path(
            scenario_id,
            mood,
            extension=generated.extension,
        )
        uploaded_path = self._storage_client.upload_audio(
            path=path,
            audio_bytes=generated.audio_bytes,
            content_type=generated.content_type,
        )
        existing = self._bgm_cache_gw.find_by_scenario_and_mood(
            db,
            scenario_id,
            mood,
        )
        if existing:
            existing.audio_path = uploaded_path
            existing.prompt_used = music_prompt
            existing.duration_seconds = self.DEFAULT_DURATION_SECONDS
            self._bgm_cache_gw.update(db, existing)
            return uploaded_path

        record = Bgm(
            id=uuid.uuid4(),
            scenario_id=scenario_id,
            mood=mood,
            audio_path=uploaded_path,
            prompt_used=music_prompt,
            duration_seconds=self.DEFAULT_DURATION_SECONDS,
            created_at=datetime.now(UTC),
        )
        self._bgm_cache_gw.create(db, record)
        return uploaded_path

    def _compress_generated_audio_to_mp3(
        self,
        generated: GeneratedAudioAsset,
    ) -> GeneratedAudioAsset:
        normalized_ext = generated.extension.strip().lower().lstrip(".")
        normalized_type = generated.content_type.strip().lower()

        if normalized_ext == "mp3" or normalized_type in {"audio/mpeg", "audio/mp3"}:
            return GeneratedAudioAsset(
                audio_bytes=generated.audio_bytes,
                content_type="audio/mpeg",
                extension="mp3",
            )

        input_format = self._guess_input_format(
            extension=normalized_ext,
            content_type=normalized_type,
        )
        segment = AudioSegment.from_file(
            io.BytesIO(generated.audio_bytes),
            format=input_format,
        )
        out = io.BytesIO()
        segment.export(
            out,
            format="mp3",
            bitrate=self.DEFAULT_MP3_BITRATE,
        )
        return GeneratedAudioAsset(
            audio_bytes=out.getvalue(),
            content_type="audio/mpeg",
            extension="mp3",
        )

    @staticmethod
    def _guess_input_format(
        *,
        extension: str,
        content_type: str,
    ) -> str:
        if extension:
            return "wav" if extension == "x-wav" else extension

        if "mpeg" in content_type or content_type == "audio/mp3":
            return "mp3"

        for token, fmt in (("ogg", "ogg"), ("flac", "flac"), ("wav", "wav")):
            if token in content_type:
                return fmt

        return "wav"

    @classmethod
    def _enforce_instrumental_prompt(cls, music_prompt: str) -> str:
        normalized_prompt = music_prompt.strip()
        if not normalized_prompt:
            return cls.INSTRUMENTAL_PROMPT_SUFFIX

        lowered_prompt = normalized_prompt.lower()
        required_tokens = ("instrumental", "no vocals", "no lyrics")
        if all(token in lowered_prompt for token in required_tokens):
            return normalized_prompt
        return f"{normalized_prompt}, {cls.INSTRUMENTAL_PROMPT_SUFFIX}"

    def _try_begin_generation(
        self,
        db: Session,
        scenario_id: uuid.UUID,
        mood: str,
        music_prompt: str,
    ) -> bool:
        existing = self._safe_find_record(
            db,
            scenario_id,
            mood,
        )
        if existing:
            return False

        pending = Bgm(
            id=uuid.uuid4(),
            scenario_id=scenario_id,
            mood=mood,
            audio_path=self.PENDING_AUDIO_PATH,
            prompt_used=music_prompt,
            duration_seconds=self.DEFAULT_DURATION_SECONDS,
            created_at=datetime.now(UTC),
        )
        try:
            self._bgm_cache_gw.create(db, pending)
        except IntegrityError:
            self._rollback_quietly(db)
            return False
        except SQLAlchemyError:
            self._rollback_quietly(db)
            return False
        return True

    def _clear_pending_record(
        self,
        db: Session,
        scenario_id: uuid.UUID,
        mood: str,
    ) -> None:
        record = self._safe_find_record(
            db,
            scenario_id,
            mood,
        )
        if not record:
            return
        if record.audio_path != self.PENDING_AUDIO_PATH:
            return
        try:
            self._bgm_cache_gw.delete(db, record)
        except SQLAlchemyError:
            self._rollback_quietly(db)

    @property
    def _lyria_client(self) -> LyriaClient:
        if self._lyria is None:
            self._lyria = LyriaClient()
        return self._lyria

    @property
    def _fal_client(self) -> FalAceStepClient:
        if self._fal is None:
            self._fal = FalAceStepClient()
        return self._fal

    @property
    def _storage_client(self) -> StorageService:
        if self._storage is None:
            self._storage = StorageService()
        return self._storage

    @staticmethod
    def _key(scenario_id: uuid.UUID, mood: str) -> tuple[str, str]:
        return str(scenario_id), BgmService._normalize_mood(mood)

    @staticmethod
    def _normalize_mood(mood: str) -> str:
        return mood.strip().lower()

    @staticmethod
    def _build_storage_path(
        scenario_id: uuid.UUID,
        mood: str,
        *,
        extension: str = "mp3",
    ) -> str:
        normalized_ext = extension.strip().lower().lstrip(".") or "wav"
        return f"scenarios/{scenario_id}/{mood}.{normalized_ext}"

    @staticmethod
    def _to_public_url(path: str) -> str:
        base = os.getenv("SUPABASE_URL")
        if not base:
            return f"generated-bgm/{path}"
        root = str(base).rstrip("/")
        return f"{root}/storage/v1/object/public/generated-bgm/{path}"

    def _safe_find_record(
        self,
        db: Session,
        scenario_id: uuid.UUID,
        mood: str,
    ) -> Bgm | None:
        """Return cache record, or None when cache table is unavailable."""
        try:
            return self._bgm_cache_gw.find_by_scenario_and_mood(
                db,
                scenario_id,
                mood,
            )
        except SQLAlchemyError as exc:
            self._rollback_quietly(db)
            logger.warning(
                "BGM cache table access failed",
                scenario_id=str(scenario_id),
                mood=mood,
                error=str(exc),
            )
            return None

    @staticmethod
    def _rollback_quietly(db: Session) -> None:
        try:
            db.rollback()
        except Exception:
            return
