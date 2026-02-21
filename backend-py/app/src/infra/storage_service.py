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
        key = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv(
            "SUPABASE_ANON_KEY",
        )
        if not url or not key:
            msg = "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set"
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
