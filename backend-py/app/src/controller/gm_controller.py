"""GM turn endpoint with SSE streaming."""

from __future__ import annotations

from typing import TYPE_CHECKING, Annotated

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse

from infra.db_client import get_session
from usecase.gm_turn_usecase import GmTurnUseCase

if TYPE_CHECKING:
    from sqlmodel import Session

    from domain.entity.gm_types import GmTurnRequest

router = APIRouter(prefix="/api/gm", tags=["gm"])


@router.post("/turn")
async def gm_turn(
    request: GmTurnRequest,
    db: Annotated[Session, Depends(get_session)],
) -> StreamingResponse:
    """Process a GM turn and stream the response via SSE."""
    use_case = GmTurnUseCase()
    return StreamingResponse(
        use_case.execute(request, db),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
