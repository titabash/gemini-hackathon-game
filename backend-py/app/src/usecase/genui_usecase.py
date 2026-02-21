"""GenUI use case for LLM chat with A2UI message generation."""

import json
from collections.abc import AsyncIterator

from langchain_core.messages import (
    AIMessage,
    AIMessageChunk,
    HumanMessage,
    SystemMessage,
)
from langchain_openai import ChatOpenAI

from src.domain.entity.genui import GenuiChatRequest
from src.util.logging import get_logger

logger = get_logger(__name__)


class GenuiUseCase:
    """Orchestrates LLM calls and streams A2UI-formatted SSE events."""

    def __init__(self) -> None:
        self.llm = ChatOpenAI(model="gpt-4o", streaming=True)

    async def execute(
        self,
        request: GenuiChatRequest,
    ) -> AsyncIterator[str]:
        """Execute LLM call and yield SSE data lines.

        Args:
            request: The genui chat request.

        Yields:
            SSE-formatted data strings.
        """
        messages = self._build_messages(request)

        logger.info(
            "Starting genui LLM stream",
            message_count=len(messages),
        )

        try:
            async for chunk in self.llm.astream(messages):
                content = self._extract_content(chunk)
                if content:
                    event = json.dumps(
                        {"type": "text", "content": content},
                        ensure_ascii=False,
                    )
                    yield f"data: {event}\n\n"

            yield 'data: {"type": "done"}\n\n'

        except Exception as e:
            logger.exception("GenUI LLM stream error", error=str(e))
            error_event = json.dumps(
                {"type": "error", "error": str(e)},
                ensure_ascii=False,
            )
            yield f"data: {error_event}\n\n"

    def _build_messages(
        self,
        request: GenuiChatRequest,
    ) -> list[SystemMessage | HumanMessage | AIMessage]:
        messages: list[SystemMessage | HumanMessage | AIMessage] = []

        system_text = (
            request.system_instruction
            or "You are a helpful AI assistant for a game application."
        )
        messages.append(SystemMessage(content=system_text))

        if request.history:
            for item in request.history:
                if item.role == "user":
                    messages.append(HumanMessage(content=item.text))
                else:
                    messages.append(AIMessage(content=item.text))

        messages.append(HumanMessage(content=request.message))
        return messages

    @staticmethod
    def _extract_content(chunk: AIMessageChunk) -> str:
        """Extract text content from a LangChain streaming chunk."""
        if isinstance(chunk.content, str):
            return chunk.content
        return ""
