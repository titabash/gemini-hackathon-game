"""GenUI SSE chat endpoint."""

from typing import Annotated

from fastapi import APIRouter, Depends
from starlette.responses import StreamingResponse
from supabase_auth.types import User

from middleware.auth_middleware import verify_token
from src.domain.entity.genui import GenuiChatRequest
from src.usecase.genui_usecase import GenuiUseCase

router = APIRouter()


@router.post("/api/genui/chat")
async def genui_chat(
    request: GenuiChatRequest,
    _current_user: Annotated[User, Depends(verify_token)],
) -> StreamingResponse:
    """SSE endpoint for GenUI chat conversations.

    Streams A2UI protocol messages from the LLM back to the Flutter client.
    """
    use_case = GenuiUseCase()
    return StreamingResponse(
        use_case.execute(request),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
