"""LLM / image generation クライアントの薄ラッパー.

LangChain例外: Gemini構造化出力(response_json_schema)が
langchain-google-genaiで未サポートのため直接SDK使用。
"""

from __future__ import annotations

import base64
import os
from dataclasses import dataclass

from google import genai
from google.genai import types
from openai import AsyncOpenAI
from pydantic import BaseModel

from util.logging import get_logger

logger = get_logger(__name__)


@dataclass(frozen=True)
class GeminiUsageMetadata:
    """Normalized usage metadata for logging/monitoring."""

    prompt_tokens: int | None = None
    output_tokens: int | None = None
    total_tokens: int | None = None
    cached_tokens: int | None = None


@dataclass(frozen=True)
class GeminiStructuredResult[T: BaseModel]:
    """Structured response + optional metadata from Gemini."""

    value: T
    interaction_id: str | None = None
    usage: GeminiUsageMetadata | None = None


class GeminiClient:
    """Gemini(構造化出力) + OpenAI(画像生成)クライアント."""

    def __init__(self) -> None:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            msg = "GEMINI_API_KEY environment variable is not set"
            raise ValueError(msg)
        self._client = genai.Client(api_key=api_key)
        self._openai_client: AsyncOpenAI | None = None

    def _get_openai_client(self) -> AsyncOpenAI:
        """OpenAI image client を遅延初期化して返す."""
        if self._openai_client is None:
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                msg = "OPENAI_API_KEY environment variable is not set"
                raise ValueError(msg)
            self._openai_client = AsyncOpenAI(api_key=api_key)
        return self._openai_client

    async def generate_structured[T: BaseModel](
        self,
        contents: str,
        system_instruction: str,
        response_type: type[T],
        model: str = "gemini-2.5-flash",
        temperature: float = 0.8,
    ) -> T:
        """構造化出力でPydanticモデルを返す."""
        result = await self.generate_structured_with_meta(
            contents=contents,
            system_instruction=system_instruction,
            response_type=response_type,
            model=model,
            temperature=temperature,
        )
        return result.value

    async def generate_structured_with_meta[T: BaseModel](  # noqa: PLR0913
        self,
        contents: str,
        system_instruction: str,
        response_type: type[T],
        model: str = "gemini-2.5-flash",
        temperature: float = 0.8,
        *,
        previous_interaction_id: str | None = None,
        use_interactions: bool = False,
        cached_content_name: str | None = None,
        store_interaction: bool = True,
    ) -> GeminiStructuredResult[T]:
        """Structured response with usage/interaction metadata."""
        if use_interactions:
            return await self._generate_structured_with_interactions(
                contents=contents,
                system_instruction=system_instruction,
                response_type=response_type,
                model=model,
                temperature=temperature,
                previous_interaction_id=previous_interaction_id,
                store_interaction=store_interaction,
            )
        return await self._generate_structured_with_generate_content(
            contents=contents,
            system_instruction=system_instruction,
            response_type=response_type,
            model=model,
            temperature=temperature,
            cached_content_name=cached_content_name,
        )

    async def _generate_structured_with_generate_content[T: BaseModel](  # noqa: PLR0913
        self,
        *,
        contents: str,
        system_instruction: str,
        response_type: type[T],
        model: str,
        temperature: float,
        cached_content_name: str | None,
    ) -> GeminiStructuredResult[T]:
        """Generate structured output via models.generate_content."""
        response = await self._client.aio.models.generate_content(
            model=model,
            contents=contents,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                response_mime_type="application/json",
                response_json_schema=response_type.model_json_schema(),
                temperature=temperature,
                cached_content=cached_content_name,
            ),
        )
        if not response.text:
            msg = "Gemini returned empty response"
            raise RuntimeError(msg)
        usage = self._extract_generate_usage(response.usage_metadata)
        return GeminiStructuredResult(
            value=response_type.model_validate_json(response.text),
            usage=usage,
        )

    async def _generate_structured_with_interactions[T: BaseModel](  # noqa: PLR0913
        self,
        *,
        contents: str,
        system_instruction: str,
        response_type: type[T],
        model: str,
        temperature: float,
        previous_interaction_id: str | None,
        store_interaction: bool,
    ) -> GeminiStructuredResult[T]:
        """Generate structured output via interactions API."""
        create_kwargs = {
            "model": model,
            "input": contents,
            "generation_config": {"temperature": temperature},
            "response_format": response_type.model_json_schema(),
            "response_mime_type": "application/json",
            "store": store_interaction,
            "system_instruction": system_instruction,
        }
        if previous_interaction_id:
            create_kwargs["previous_interaction_id"] = previous_interaction_id

        interaction = await self._client.aio.interactions.create(**create_kwargs)
        raw_text = self._extract_interaction_text(interaction)
        if not raw_text:
            msg = "Gemini interaction returned empty response"
            raise RuntimeError(msg)

        return GeminiStructuredResult(
            value=response_type.model_validate_json(raw_text),
            interaction_id=getattr(interaction, "id", None),
            usage=self._extract_interaction_usage(getattr(interaction, "usage", None)),
        )

    async def create_prompt_cache(
        self,
        *,
        model: str,
        contents: str,
        ttl: str = "3600s",
        display_name: str | None = None,
    ) -> str:
        """Create explicit cache for stable prompt prefix, return cache name."""
        cached = await self._client.aio.caches.create(
            model=model,
            config=types.CreateCachedContentConfig(
                contents=contents,
                ttl=ttl,
                display_name=display_name,
            ),
        )
        if not cached.name:
            msg = "Gemini cache creation returned empty cache name"
            raise RuntimeError(msg)
        return cached.name

    async def delete_prompt_cache(self, name: str) -> None:
        """Delete explicit cache (best-effort caller side)."""
        await self._client.aio.caches.delete(name=name)

    async def delete_interaction(self, interaction_id: str) -> None:
        """Delete interaction resource (best-effort caller side)."""
        await self._client.aio.interactions.delete(id=interaction_id)

    async def generate_image(
        self,
        prompt: str,
        model: str = "gpt-image-1.5",
        *,
        source_image: bytes | None = None,
        transparent_background: bool = False,
        size: str = "auto",
    ) -> bytes | None:
        """OpenAI画像生成/編集。画像が取得できなければNoneを返す."""
        background = "transparent" if transparent_background else "auto"
        client = self._get_openai_client()

        if source_image:
            response = await client.images.edit(
                image=("npc-base.png", source_image, "image/png"),
                prompt=prompt,
                model=model,
                input_fidelity="high",
                response_format="b64_json",
                output_format="png",
                size=size,
                background=background,
            )
        else:
            response = await client.images.generate(
                prompt=prompt,
                model=model,
                response_format="b64_json",
                output_format="png",
                size=size,
                background=background,
            )

        if not response.data:
            return None

        for item in response.data:
            if item.b64_json:
                try:
                    return base64.b64decode(item.b64_json)
                except Exception:
                    logger.warning("Failed to decode generated image payload")
                    return None

        return None

    @staticmethod
    def _extract_generate_usage(
        usage: types.GenerateContentResponseUsageMetadata | None,
    ) -> GeminiUsageMetadata | None:
        """Normalize usage metadata from generate_content response."""
        if usage is None:
            return None
        return GeminiUsageMetadata(
            prompt_tokens=usage.prompt_token_count,
            output_tokens=usage.candidates_token_count,
            total_tokens=usage.total_token_count,
            cached_tokens=usage.cached_content_token_count,
        )

    @staticmethod
    def _extract_interaction_usage(usage: object) -> GeminiUsageMetadata | None:
        """Normalize usage metadata from interactions response."""
        if usage is None:
            return None
        return GeminiUsageMetadata(
            prompt_tokens=getattr(usage, "total_input_tokens", None),
            output_tokens=getattr(usage, "total_output_tokens", None),
            total_tokens=getattr(usage, "total_tokens", None),
            cached_tokens=getattr(usage, "total_cached_tokens", None),
        )

    @staticmethod
    def _extract_interaction_text(interaction: object) -> str:
        """Extract text output from interactions response."""
        outputs = getattr(interaction, "outputs", None)
        if not outputs:
            return ""
        texts: list[str] = []
        for item in outputs:
            if getattr(item, "type", None) != "text":
                continue
            text = getattr(item, "text", None)
            if text:
                texts.append(str(text))
        return "\n".join(texts).strip()
