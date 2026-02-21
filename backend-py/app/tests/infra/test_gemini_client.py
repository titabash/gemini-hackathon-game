"""Tests for GeminiClient.

GeminiClient is our thin adapter around google-genai SDK.
We mock _client.aio.models.generate_content with autospec=True
to preserve SDK signature checks (Pattern B from backend-py.md).
"""

from unittest.mock import AsyncMock

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


def _make_image_response(image_data: bytes) -> types.GenerateContentResponse:
    """Build a GenerateContentResponse with an inline_data part."""
    return types.GenerateContentResponse(
        candidates=[
            types.Candidate(
                content=types.Content(
                    parts=[
                        types.Part(
                            inline_data=types.Blob(
                                mime_type="image/png",
                                data=image_data,
                            ),
                        ),
                    ],
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


class TestGeminiClientGenerateImage:
    """Tests for generate_image method."""

    @pytest.mark.asyncio
    async def test_returns_image_bytes(self, monkeypatch) -> None:
        """Image generation should return bytes on success."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        fake_image_data = b"fake-png-data"
        client = GeminiClient()
        client._client.aio.models.generate_content = AsyncMock(
            return_value=_make_image_response(fake_image_data),
        )

        result = await client.generate_image(
            prompt="A fantasy tavern",
            model="gemini-2.5-flash-image",
        )

        assert result is not None
        assert isinstance(result, bytes)
        assert result == fake_image_data

    @pytest.mark.asyncio
    async def test_returns_none_on_no_image(self, monkeypatch) -> None:
        """Returns None when response contains no image data."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        client = GeminiClient()
        client._client.aio.models.generate_content = AsyncMock(
            return_value=_make_text_response("I cannot generate images."),
        )

        result = await client.generate_image(
            prompt="A fantasy tavern",
            model="gemini-2.5-flash-image",
        )

        assert result is None

    @pytest.mark.asyncio
    async def test_returns_none_on_no_candidates(self, monkeypatch) -> None:
        """Returns None when response has no candidates."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        empty_resp = types.GenerateContentResponse(candidates=[])

        client = GeminiClient()
        client._client.aio.models.generate_content = AsyncMock(
            return_value=empty_resp,
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
