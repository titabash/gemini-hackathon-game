"""fal.ai ACE-Step client for non-realtime music generation."""

from __future__ import annotations

import asyncio
import os
from dataclasses import dataclass
from functools import partial
from pathlib import PurePosixPath
from typing import Any, ClassVar

import fal_client
import httpx

from util.logging import get_logger

logger = get_logger(__name__)


@dataclass(frozen=True)
class GeneratedAudioAsset:
    """Generated audio payload and metadata."""

    audio_bytes: bytes
    content_type: str
    extension: str


class FalAceStepClient:
    """ACE-Step music generation client (queue + result download)."""

    DEFAULT_APPLICATION = "fal-ai/ace-step/prompt-to-audio"
    DEFAULT_DURATION_SECONDS = 60

    _CONTENT_TYPE_EXTENSION_MAP: ClassVar[dict[str, str]] = {
        "audio/mpeg": "mp3",
        "audio/mp3": "mp3",
        "audio/wav": "wav",
        "audio/x-wav": "wav",
        "audio/wave": "wav",
        "audio/flac": "flac",
        "audio/ogg": "ogg",
    }
    _GENERIC_BINARY_CONTENT_TYPES: ClassVar[set[str]] = {
        "application/octet-stream",
        "binary/octet-stream",
        "application/binary",
    }
    _EXTENSION_NORMALIZATION_MAP: ClassVar[dict[str, str]] = {
        "mp3": "mp3",
        "wav": "wav",
        "wave": "wav",
        "x-wav": "wav",
        "ogg": "ogg",
        "flac": "flac",
    }

    def __init__(
        self,
        api_key: str | None = None,
        *,
        application: str = DEFAULT_APPLICATION,
        client: fal_client.SyncClient | None = None,
        timeout_seconds: float = 180.0,
    ) -> None:
        key = api_key or os.getenv("FAL_KEY") or os.getenv("FAL_API_KEY")
        if not key:
            msg = "FAL_KEY or FAL_API_KEY environment variable is not set"
            raise ValueError(msg)
        self._application = application
        self._client = client or fal_client.SyncClient(
            key=key,
            default_timeout=timeout_seconds,
        )
        self._timeout_seconds = timeout_seconds

    async def generate_music(
        self,
        prompt: str,
        *,
        duration_seconds: int = DEFAULT_DURATION_SECONDS,
    ) -> GeneratedAudioAsset:
        """Generate music and return downloadable audio bytes."""
        result = await self._subscribe(prompt, duration_seconds=duration_seconds)
        audio_desc = self._extract_audio_descriptor(result)
        audio_url = audio_desc["url"]

        downloaded_bytes, downloaded_content_type = await self._download_audio(
            audio_url,
        )

        result_content_type = (
            str(
                audio_desc.get("content_type") or audio_desc.get("mime_type") or "",
            )
            .strip()
            .lower()
        )
        content_type = self._resolve_content_type(
            preferred=result_content_type,
            fallback=downloaded_content_type,
            audio_url=audio_url,
            file_name=str(audio_desc.get("file_name", "")),
        )
        extension = self._resolve_extension(
            file_name=str(audio_desc.get("file_name", "")),
            content_type=content_type,
            audio_url=audio_url,
        )
        return GeneratedAudioAsset(
            audio_bytes=downloaded_bytes,
            content_type=content_type,
            extension=extension,
        )

    async def _subscribe(
        self,
        prompt: str,
        *,
        duration_seconds: int,
    ) -> dict[str, Any]:
        arguments_with_duration: dict[str, Any] = {"prompt": prompt}
        if duration_seconds > 0:
            arguments_with_duration["duration"] = duration_seconds

        try:
            return await asyncio.to_thread(
                partial(
                    self._client.subscribe,
                    self._application,
                    arguments_with_duration,
                ),
            )
        except Exception as exc:
            logger.warning(
                "ACE-Step request with duration failed; retrying without duration",
                error=str(exc),
            )
            return await asyncio.to_thread(
                partial(
                    self._client.subscribe,
                    self._application,
                    {"prompt": prompt},
                ),
            )

    async def _download_audio(self, audio_url: str) -> tuple[bytes, str]:
        async with httpx.AsyncClient(timeout=self._timeout_seconds) as client:
            response = await client.get(audio_url)
            response.raise_for_status()
            content_type = response.headers.get("content-type", "")
            return response.content, content_type

    @staticmethod
    def _extract_audio_descriptor(result: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(result, dict):
            msg = "ACE-Step result is not a JSON object"
            raise TypeError(msg)

        audio = result.get("audio")
        if isinstance(audio, dict):
            audio_url = audio.get("url")
            if isinstance(audio_url, str) and audio_url:
                return audio

        audio_url = result.get("audio_url")
        if isinstance(audio_url, str) and audio_url:
            return {"url": audio_url}

        msg = "ACE-Step result does not contain an audio URL"
        raise RuntimeError(msg)

    def _resolve_content_type(
        self,
        *,
        preferred: str,
        fallback: str,
        audio_url: str,
        file_name: str,
    ) -> str:
        for candidate in (preferred, fallback):
            normalized = self._normalize_content_type(candidate)
            if normalized:
                return normalized

        suffix_content_type_map = {
            "mp3": "audio/mpeg",
            "wav": "audio/wav",
            "ogg": "audio/ogg",
            "flac": "audio/flac",
        }

        file_suffix = (
            PurePosixPath(file_name).suffix.lower().lstrip(".") if file_name else ""
        )
        normalized_file_suffix = self._normalize_extension(file_suffix)
        by_file_suffix = suffix_content_type_map.get(normalized_file_suffix)
        if by_file_suffix:
            return by_file_suffix

        url_suffix = PurePosixPath(audio_url).suffix.lower().lstrip(".")
        normalized_url_suffix = self._normalize_extension(url_suffix)
        return suffix_content_type_map.get(normalized_url_suffix, "audio/wav")

    def _resolve_extension(
        self,
        *,
        file_name: str,
        content_type: str,
        audio_url: str,
    ) -> str:
        file_suffix = self._normalize_extension(
            PurePosixPath(file_name).suffix.lower().lstrip("."),
        )
        if file_suffix:
            return file_suffix

        by_content_type = self._CONTENT_TYPE_EXTENSION_MAP.get(content_type)
        if by_content_type:
            return by_content_type

        url_suffix = self._normalize_extension(
            PurePosixPath(audio_url).suffix.lower().lstrip("."),
        )
        if url_suffix:
            return url_suffix
        return "wav"

    def _normalize_content_type(self, content_type: str) -> str:
        normalized = content_type.split(";", 1)[0].strip().lower()
        if not normalized:
            return ""
        if normalized in self._GENERIC_BINARY_CONTENT_TYPES:
            return ""
        if normalized == "audio/x-wav":
            return "audio/wav"
        return normalized

    def _normalize_extension(self, extension: str) -> str:
        normalized = extension.strip().lower().lstrip(".")
        if not normalized:
            return ""
        return self._EXTENSION_NORMALIZATION_MAP.get(normalized, "")
