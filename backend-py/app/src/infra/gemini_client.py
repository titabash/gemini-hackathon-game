"""google-genai SDK 薄ラッパー.

LangChain例外: Gemini構造化出力(response_json_schema)が
langchain-google-genaiで未サポートのため直接SDK使用。
"""

import os

from google import genai
from google.genai import types
from pydantic import BaseModel

from util.logging import get_logger

logger = get_logger(__name__)


class GeminiClient:
    """Gemini API クライアント(構造化出力・画像生成対応)."""

    def __init__(self) -> None:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            msg = "GEMINI_API_KEY environment variable is not set"
            raise ValueError(msg)
        self._client = genai.Client(api_key=api_key)

    async def generate_structured[T: BaseModel](
        self,
        contents: str,
        system_instruction: str,
        response_type: type[T],
        model: str = "gemini-2.5-flash",
        temperature: float = 0.8,
    ) -> T:
        """構造化出力でPydanticモデルを返す."""
        response = await self._client.aio.models.generate_content(
            model=model,
            contents=contents,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                response_mime_type="application/json",
                response_json_schema=response_type.model_json_schema(),
                temperature=temperature,
            ),
        )
        if not response.text:
            msg = "Gemini returned empty response"
            raise RuntimeError(msg)

        return response_type.model_validate_json(response.text)

    async def generate_image(
        self,
        prompt: str,
        model: str = "gemini-2.5-flash-image",
    ) -> bytes | None:
        """画像生成。画像パートがなければNoneを返す."""
        response = await self._client.aio.models.generate_content(
            model=model,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_modalities=["IMAGE", "TEXT"],
            ),
        )
        if not response.candidates:
            return None

        for part in response.candidates[0].content.parts:
            if part.inline_data is not None:
                return part.inline_data.data

        return None
