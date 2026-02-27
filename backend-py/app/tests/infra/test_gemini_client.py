"""Tests for GeminiClient.

GeminiClient is our thin adapter around google-genai SDK.
We mock _client.aio.models.generate_content with autospec=True
to preserve SDK signature checks (Pattern B from backend-py.md).
"""

import base64
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest
from google.genai import types
from pydantic import BaseModel

from src.infra.gemini_client import GeminiClient


class SampleResponse(BaseModel):
    """Sample Pydantic model for structured output tests."""

    answer: str
    confidence: float


def _make_text_response(text: str) -> types.GenerateContentResponse:
    """Build a GenerateContentResponse with a text part."""
    return types.GenerateContentResponse(
        candidates=[
            types.Candidate(
                content=types.Content(
                    parts=[types.Part(text=text)],
                    role="model",
                ),
                finish_reason="STOP",
            ),
        ],
    )


class TestGeminiClientGenerateStructured:
    """Tests for generate_structured method."""

    @pytest.mark.asyncio
    async def test_returns_parsed_pydantic_model(self, monkeypatch) -> None:
        """Structured output should return a validated Pydantic model."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        client = GeminiClient()
        mock_gen = AsyncMock(
            return_value=_make_text_response(
                '{"answer": "42", "confidence": 0.95}',
            ),
        )
        client._client.aio.models.generate_content = mock_gen

        result = await client.generate_structured(
            contents="What is the answer?",
            system_instruction="Answer questions.",
            response_type=SampleResponse,
            model="gemini-2.5-flash",
        )

        assert isinstance(result, SampleResponse)
        assert result.answer == "42"
        assert result.confidence == 0.95

        call_kwargs = mock_gen.call_args.kwargs
        assert call_kwargs["model"] == "gemini-2.5-flash"
        assert call_kwargs["contents"] == "What is the answer?"

    @pytest.mark.asyncio
    async def test_custom_temperature(self, monkeypatch) -> None:
        """Temperature parameter should be forwarded to config."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        client = GeminiClient()
        mock_gen = AsyncMock(
            return_value=_make_text_response(
                '{"answer": "ok", "confidence": 1.0}',
            ),
        )
        client._client.aio.models.generate_content = mock_gen

        await client.generate_structured(
            contents="test",
            system_instruction="test",
            response_type=SampleResponse,
            model="gemini-2.5-flash",
            temperature=0.0,
        )

        config = mock_gen.call_args.kwargs["config"]
        assert config.temperature == 0.0

    @pytest.mark.asyncio
    async def test_empty_response_raises(self, monkeypatch) -> None:
        """Empty response text should raise RuntimeError."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        empty_resp = types.GenerateContentResponse(
            candidates=[
                types.Candidate(
                    content=types.Content(parts=[], role="model"),
                    finish_reason="STOP",
                ),
            ],
        )

        client = GeminiClient()
        client._client.aio.models.generate_content = AsyncMock(
            return_value=empty_resp,
        )

        with pytest.raises(RuntimeError, match="empty response"):
            await client.generate_structured(
                contents="test",
                system_instruction="test",
                response_type=SampleResponse,
                model="gemini-2.5-flash",
            )

    @pytest.mark.asyncio
    async def test_cached_content_name_is_forwarded(self, monkeypatch) -> None:
        """cached_content should be forwarded to GenerateContentConfig."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")
        client = GeminiClient()
        mock_gen = AsyncMock(
            return_value=_make_text_response(
                '{"answer": "cached", "confidence": 1.0}',
            ),
        )
        client._client.aio.models.generate_content = mock_gen

        await client.generate_structured_with_meta(
            contents="test",
            system_instruction="test",
            response_type=SampleResponse,
            cached_content_name="cachedContents/abc",
        )
        config = mock_gen.call_args.kwargs["config"]
        assert config.cached_content == "cachedContents/abc"

    @pytest.mark.asyncio
    async def test_interactions_path_returns_metadata(self, monkeypatch) -> None:
        """Interactions path should return parsed value + interaction metadata."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")
        client = GeminiClient()
        interaction = SimpleNamespace(
            id="interaction_123",
            outputs=[
                SimpleNamespace(
                    type="text",
                    text='{"answer":"ok","confidence":0.5}',
                ),
            ],
            usage=SimpleNamespace(
                total_input_tokens=12,
                total_output_tokens=8,
                total_tokens=20,
                total_cached_tokens=4,
            ),
        )
        client._client.aio.interactions.create = AsyncMock(return_value=interaction)

        result = await client.generate_structured_with_meta(
            contents="turn prompt",
            system_instruction="system",
            response_type=SampleResponse,
            use_interactions=True,
            previous_interaction_id="prev_1",
            temperature=0.2,
        )

        assert result.value.answer == "ok"
        assert result.value.confidence == 0.5
        assert result.interaction_id == "interaction_123"
        assert result.usage is not None
        assert result.usage.total_tokens == 20
        assert result.usage.cached_tokens == 4

        call_kwargs = client._client.aio.interactions.create.call_args.kwargs
        assert call_kwargs["previous_interaction_id"] == "prev_1"
        assert call_kwargs["response_mime_type"] == "application/json"


class TestGeminiClientGenerateImage:
    """Tests for generate_image method."""

    @pytest.mark.asyncio
    async def test_returns_image_bytes(self, monkeypatch) -> None:
        """Image generation should decode b64 payload from OpenAI."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")
        monkeypatch.setenv("OPENAI_API_KEY", "test-openai-key")

        fake_image_data = b"fake-png-data"
        encoded = base64.b64encode(fake_image_data).decode("utf-8")

        client = GeminiClient()
        client._openai_client = MagicMock()
        client._openai_client.images.generate = AsyncMock(
            return_value=SimpleNamespace(
                data=[SimpleNamespace(b64_json=encoded)],
            ),
        )

        result = await client.generate_image(
            prompt="A fantasy tavern",
            model="gpt-image-1.5",
        )

        assert result is not None
        assert isinstance(result, bytes)
        assert result == fake_image_data
        client._openai_client.images.generate.assert_called_once()

    @pytest.mark.asyncio
    async def test_source_image_uses_edit_api(self, monkeypatch) -> None:
        """When source image exists, images.edit should be used."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")
        monkeypatch.setenv("OPENAI_API_KEY", "test-openai-key")

        source = b"base-image-bytes"
        encoded = base64.b64encode(b"out-image").decode("utf-8")
        client = GeminiClient()
        client._openai_client = MagicMock()
        client._openai_client.images.edit = AsyncMock(
            return_value=SimpleNamespace(
                data=[SimpleNamespace(b64_json=encoded)],
            ),
        )

        result = await client.generate_image(
            prompt="angry expression",
            source_image=source,
            transparent_background=True,
            size="1024x1536",
        )

        assert result == b"out-image"
        client._openai_client.images.edit.assert_called_once()
        kwargs = client._openai_client.images.edit.call_args.kwargs
        assert kwargs["image"][1] == source
        assert kwargs["background"] == "transparent"
        assert kwargs["size"] == "1024x1536"

    @pytest.mark.asyncio
    async def test_returns_none_on_empty_data(self, monkeypatch) -> None:
        """Returns None when OpenAI response has no image payload."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")
        monkeypatch.setenv("OPENAI_API_KEY", "test-openai-key")

        client = GeminiClient()
        client._openai_client = MagicMock()
        client._openai_client.images.generate = AsyncMock(
            return_value=SimpleNamespace(data=[]),
        )

        result = await client.generate_image(prompt="test")

        assert result is None


class TestGeminiClientInit:
    """Tests for GeminiClient initialization."""

    def test_raises_without_api_key(self, monkeypatch) -> None:
        """Should raise ValueError when GEMINI_API_KEY is not set."""
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        with pytest.raises(ValueError, match="GEMINI_API_KEY"):
            GeminiClient()

    def test_openai_client_raises_without_api_key(self, monkeypatch) -> None:
        """Image generation should require OPENAI_API_KEY."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")
        monkeypatch.delenv("OPENAI_API_KEY", raising=False)
        client = GeminiClient()
        with pytest.raises(ValueError, match="OPENAI_API_KEY"):
            client._get_openai_client()


class TestGeminiClientRuntimeResources:
    """Tests for cache/interaction resource helper methods."""

    @pytest.mark.asyncio
    async def test_create_prompt_cache_returns_name(self, monkeypatch) -> None:
        """create_prompt_cache should return cache name from SDK response."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")
        client = GeminiClient()
        client._client.aio.caches.create = AsyncMock(
            return_value=SimpleNamespace(name="cachedContents/game-1"),
        )

        name = await client.create_prompt_cache(
            model="gemini-2.5-flash",
            contents="seed",
            ttl="1200s",
            display_name="gm-seed",
        )

        assert name == "cachedContents/game-1"
        client._client.aio.caches.create.assert_called_once()

    @pytest.mark.asyncio
    async def test_delete_prompt_cache_forwards_name(self, monkeypatch) -> None:
        """delete_prompt_cache should forward cache name."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")
        client = GeminiClient()
        client._client.aio.caches.delete = AsyncMock()

        await client.delete_prompt_cache("cachedContents/game-1")

        client._client.aio.caches.delete.assert_awaited_once_with(
            name="cachedContents/game-1",
        )

    @pytest.mark.asyncio
    async def test_delete_interaction_forwards_id(self, monkeypatch) -> None:
        """delete_interaction should forward interaction id."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")
        client = GeminiClient()
        client._client.aio.interactions.delete = AsyncMock()

        await client.delete_interaction("interaction_1")

        client._client.aio.interactions.delete.assert_awaited_once_with(
            id="interaction_1",
        )
