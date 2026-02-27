"""Lyria Music API client.

Provides realtime PCM streaming and in-memory PCM -> MP3 conversion.
"""

from __future__ import annotations

import io
import os
from typing import TYPE_CHECKING, Any

from google import genai
from google.genai import types
from pydub import AudioSegment

from util.logging import get_logger

logger = get_logger(__name__)

if TYPE_CHECKING:
    from collections.abc import AsyncIterator


class LyriaClient:
    """Lyria Music API client (streaming + batch generation)."""

    DEFAULT_MODEL = "models/lyria-realtime-exp"
    DEFAULT_API_VERSION = "v1alpha"
    DEFAULT_SAMPLE_RATE = 48_000
    DEFAULT_CHANNELS = 2
    DEFAULT_SAMPLE_WIDTH = 2  # int16 PCM
    DEFAULT_DURATION_SECONDS = 60

    def __init__(
        self,
        api_key: str | None = None,
        *,
        model: str = DEFAULT_MODEL,
        api_version: str = DEFAULT_API_VERSION,
    ) -> None:
        key = api_key or os.getenv("GEMINI_API_KEY")
        if not key:
            msg = "GEMINI_API_KEY environment variable is not set"
            raise ValueError(msg)
        self._client = genai.Client(
            api_key=key,
            http_options={"api_version": api_version},
        )
        self._model = model

    async def stream_music(
        self,
        prompt: str,
        *,
        config: dict[str, Any] | None = None,
        duration_seconds: int = DEFAULT_DURATION_SECONDS,
    ) -> AsyncIterator[bytes]:
        """Yield PCM chunks from Lyria realtime stream."""
        bytes_per_second = (
            self.DEFAULT_SAMPLE_RATE * self.DEFAULT_CHANNELS * self.DEFAULT_SAMPLE_WIDTH
        )
        max_bytes = max(1, duration_seconds) * bytes_per_second
        received = 0

        async with self._client.aio.live.music.connect(  # type: ignore[attr-defined]
            model=self._model,
        ) as session:
            await self._set_weighted_prompt(session, prompt)
            await self._set_generation_config(session, config)
            await session.play()

            async for message in session.receive():
                for chunk in self._extract_audio_chunks(message):
                    if not chunk:
                        continue
                    remaining = max_bytes - received
                    if remaining <= 0:
                        return
                    clipped = chunk[:remaining]
                    received += len(clipped)
                    yield clipped
                    if received >= max_bytes:
                        return

    async def generate_music(
        self,
        prompt: str,
        *,
        duration_seconds: int = DEFAULT_DURATION_SECONDS,
        config: dict[str, Any] | None = None,
    ) -> bytes:
        """Generate full music and return MP3 bytes."""
        chunks = [
            chunk
            async for chunk in self.stream_music(
                prompt,
                config=config,
                duration_seconds=duration_seconds,
            )
        ]
        pcm_data = b"".join(chunks)
        if not pcm_data:
            return b""
        return self.pcm_to_mp3(pcm_data)

    @staticmethod
    def pcm_to_mp3(
        pcm_data: bytes,
        *,
        sample_width: int = DEFAULT_SAMPLE_WIDTH,
        frame_rate: int = DEFAULT_SAMPLE_RATE,
        channels: int = DEFAULT_CHANNELS,
    ) -> bytes:
        """Public wrapper for PCM int16 -> MP3 conversion."""
        return LyriaClient._pcm_to_mp3(
            pcm_data,
            sample_width=sample_width,
            frame_rate=frame_rate,
            channels=channels,
        )

    @staticmethod
    def _pcm_to_mp3(
        pcm_data: bytes,
        *,
        sample_width: int = DEFAULT_SAMPLE_WIDTH,
        frame_rate: int = DEFAULT_SAMPLE_RATE,
        channels: int = DEFAULT_CHANNELS,
    ) -> bytes:
        """Convert raw PCM int16 bytes to MP3."""
        segment = AudioSegment(
            data=pcm_data,
            sample_width=sample_width,
            frame_rate=frame_rate,
            channels=channels,
        )
        out = io.BytesIO()
        segment.export(out, format="mp3", bitrate="192k")
        return out.getvalue()

    async def _set_weighted_prompt(self, session: object, prompt: str) -> None:
        weighted_prompt_cls = getattr(types, "WeightedPrompt", None)
        prompts = (
            [weighted_prompt_cls(text=prompt, weight=1.0)]
            if weighted_prompt_cls
            else [{"text": prompt, "weight": 1.0}]
        )
        await session.set_weighted_prompts(prompts=prompts)

    async def _set_generation_config(
        self,
        session: object,
        config: dict[str, Any] | None,
    ) -> None:
        if not config:
            return
        config_cls = getattr(types, "LiveMusicGenerationConfig", None)
        payload = config_cls(**config) if config_cls else config
        await session.set_music_generation_config(config=payload)

    @staticmethod
    def _extract_audio_chunks(message: object) -> list[bytes]:
        server_content = getattr(message, "server_content", None)
        if server_content is None:
            return []
        audio_chunks = getattr(server_content, "audio_chunks", None)
        if not isinstance(audio_chunks, list):
            return []

        result: list[bytes] = []
        for chunk in audio_chunks:
            data = getattr(chunk, "data", None)
            if isinstance(data, (bytes, bytearray)):
                result.append(bytes(data))
                continue
            inline_data = getattr(chunk, "inline_data", None)
            inline_bytes = getattr(inline_data, "data", None)
            if isinstance(inline_bytes, (bytes, bytearray)):
                result.append(bytes(inline_bytes))
        return result
