"""GM turn endpoint with SSE streaming."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlmodel import Session

from domain.entity.gm_types import GmTurnRequest, LatestTurnResponse
from infra.db_client import get_session
from usecase.gm_turn_usecase import GmTurnUseCase

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


@router.get("/turn/latest")
async def get_latest_turn(
    session_id: str,
    db: Annotated[Session, Depends(get_session)],
) -> LatestTurnResponse:
    """Return the latest persisted turn for SSE error recovery.

    Called by the frontend when the SSE stream ends without a done event.
    Nodes are always persisted before streaming starts, so this endpoint
    reliably returns the current turn's nodes for seamless UI recovery.
    """
    use_case = GmTurnUseCase()
    result = use_case.get_latest_turn(session_id, db)
    if result is None:
        raise HTTPException(status_code=404, detail="No turns found for session")
    return result
