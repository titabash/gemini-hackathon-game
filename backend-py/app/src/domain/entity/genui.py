"""GenUI request/response models for the SSE chat endpoint."""

from typing import Any

from pydantic import BaseModel


class GenuiHistoryItem(BaseModel):
    """A single message in the conversation history."""

    role: str
    text: str


class GenuiChatRequest(BaseModel):
    """Request body for POST /api/genui/chat."""

    message: str
    history: list[GenuiHistoryItem] | None = None
    system_instruction: str | None = None
    client_capabilities: dict[str, Any] | None = None


class GenuiErrorEvent(BaseModel):
    """Error event emitted via SSE."""

    type: str = "error"
    error: str
