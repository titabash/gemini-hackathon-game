"""Supabase Storage service for uploading generated images."""

from __future__ import annotations

import os
import uuid

from supabase import Client, create_client

from util.logging import get_logger

logger = get_logger(__name__)

_BUCKET = "generated-images"


class StorageService:
    """Upload files to Supabase Storage and return public URLs."""

    def __init__(self) -> None:
        url = os.getenv("SUPABASE_URL")
        key = (
            os.getenv("SUPABASE_SERVICE_ROLE_KEY")
            or os.getenv("SUPABASE_SECRET_KEY")
            or os.getenv("SUPABASE_SECRET")
        )
        if not url or not key:
            msg = (
                "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY "
                "(or SUPABASE_SECRET_KEY / SUPABASE_SECRET) must be set"
            )
            raise ValueError(msg)
        self._client: Client = create_client(url, key)

    def upload_image(
        self,
        session_id: str,
        image_bytes: bytes,
        content_type: str = "image/png",
    ) -> str:
        """Upload image bytes and return the storage path (not URL).

        Path: sessions/{session_id}/{uuid}.png
        """
        ext = "png"
        if "jpeg" in content_type or "jpg" in content_type:
            ext = "jpg"
        elif "webp" in content_type:
            ext = "webp"

        file_name = f"{uuid.uuid4()}.{ext}"
        path = f"sessions/{session_id}/{file_name}"

        self._client.storage.from_(_BUCKET).upload(
            path=path,
            file=image_bytes,
            file_options={"content-type": content_type},
        )

        logger.info(
            "Image uploaded to storage",
            bucket=_BUCKET,
            path=path,
        )
        return path

    def upload_audio(
        self,
        path: str,
        audio_bytes: bytes,
        content_type: str = "audio/mpeg",
        bucket: str = "generated-bgm",
    ) -> str:
        """Upload audio bytes and return storage path.

        Args:
            path: Destination object path in bucket.
            audio_bytes: Binary audio payload.
            content_type: MIME type.
            bucket: Storage bucket name.
        """
        self._client.storage.from_(bucket).upload(
            path=path,
            file=audio_bytes,
            file_options={"content-type": content_type},
        )
        logger.info("Audio uploaded to storage", bucket=bucket, path=path)
        return path

    def download_image(
        self,
        path: str,
        bucket: str = _BUCKET,
    ) -> bytes | None:
        """Download image bytes from Supabase Storage."""
        try:
            return self._client.storage.from_(bucket).download(path)
        except Exception:
            logger.warning(
                "Image download failed",
                bucket=bucket,
                path=path,
            )
            return None
