"""Tests for LyriaClient helper behavior."""

from __future__ import annotations

import shutil

import pytest

from src.infra.lyria_client import LyriaClient


class TestLyriaClientPcmToMp3:
    """PCM conversion tests."""

    @pytest.mark.skipif(
        shutil.which("ffmpeg") is None and shutil.which("avconv") is None,
        reason="ffmpeg/avconv is required for pydub mp3 export",
    )
    def test_pcm_to_mp3_from_silence(self) -> None:
        # 0.25 sec of stereo int16 silence @ 48kHz
        samples = 48_000 // 4
        pcm = b"\x00\x00\x00\x00" * samples

        mp3 = LyriaClient._pcm_to_mp3(pcm)

        assert isinstance(mp3, bytes)
        assert len(mp3) > 0
        # Most MP3s start with ID3 or MPEG frame sync bytes.
        assert mp3.startswith(b"ID3") or mp3[:1] == b"\xff"
