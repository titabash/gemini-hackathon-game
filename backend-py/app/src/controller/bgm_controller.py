"""BGM endpoints for cache lookup and on-demand generation."""

from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import (
    APIRouter,
    HTTPException,
    Query,
    Request,
    WebSocket,
    WebSocketDisconnect,
)
from pydantic import BaseModel, ValidationError
from sqlmodel import Session

from domain.service.bgm_service import BgmService
from gateway.scenario_gateway import ScenarioGateway
from infra.db_client import engine
from infra.supabase_client import SupabaseClient
from util.logging import get_logger

router = APIRouter(prefix="/api/bgm", tags=["bgm"])
logger = get_logger(__name__)

_bgm_service = BgmService()
_scenario_gw = ScenarioGateway()


class BgmStreamRequest(BaseModel):
    """Incoming payload for /api/bgm/stream websocket."""

    scenario_id: str
    mood: str
    music_prompt: str
    auth_token: str | None = None


@router.websocket("/stream")
async def bgm_stream(websocket: WebSocket) -> None:
    """Generate-or-reuse BGM and return a cached URL over WebSocket."""
    await websocket.accept()
    request = await _receive_stream_request(websocket)
    if request is None:
        return

    scenario_id = await _parse_stream_scenario_id(
        websocket,
        request.scenario_id,
    )
    if scenario_id is None:
        return

    validated = await _validate_stream_fields(
        websocket,
        request.mood,
        request.music_prompt,
    )
    if validated is None:
        return
    mood, prompt = validated

    try:
        with Session(engine) as db:
            _authorize_scenario_access(
                db,
                scenario_id,
                auth_token=request.auth_token,
                authorization_header=websocket.headers.get("authorization"),
            )
    except HTTPException as exc:
        await websocket.send_json({"type": "error", "message": str(exc.detail)})
        await websocket.close(code=1008)
        return

    try:
        await _stream_and_cache_bgm(websocket, scenario_id, mood, prompt)
    except WebSocketDisconnect:
        logger.info(
            "BGM websocket disconnected",
            scenario_id=str(scenario_id),
            mood=mood,
        )
    except Exception as exc:
        logger.warning(
            "BGM websocket stream failed",
            scenario_id=str(scenario_id),
            mood=mood,
            error=str(exc),
        )
        try:
            await websocket.send_json({"type": "error", "message": "bgm stream failed"})
            await websocket.close(code=1011)
        except Exception:
            return


@router.get("/status")
async def bgm_status(
    request: Request,
    scenario_id: Annotated[str, Query(...)],
    mood: Annotated[str, Query(...)],
    auth_token: Annotated[str | None, Query()] = None,
) -> dict[str, str]:
    """Polling endpoint for non-web fallback clients."""
    sid = _parse_scenario_id_or_400(scenario_id)
    normalized_mood = mood.strip().lower()
    if not normalized_mood:
        raise HTTPException(status_code=400, detail="mood is required")

    with Session(engine) as db:
        _authorize_scenario_access(
            db,
            sid,
            auth_token=auth_token,
            authorization_header=request.headers.get("authorization"),
        )
        cached_path = _bgm_service.get_cached_bgm_path(db, sid, normalized_mood)
        if cached_path:
            return {
                "status": "ready",
                "path": f"generated-bgm/{cached_path}",
            }
        if _bgm_service.is_pending(db, sid, normalized_mood):
            return {"status": "generating"}

    return {"status": "not_found"}


def _parse_scenario_id_or_400(scenario_id: str) -> uuid.UUID:
    try:
        return uuid.UUID(scenario_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="invalid scenario_id") from exc


async def _receive_stream_request(websocket: WebSocket) -> BgmStreamRequest | None:
    try:
        raw = await websocket.receive_json()
        return BgmStreamRequest.model_validate(raw)
    except ValidationError:
        await websocket.send_json(
            {"type": "error", "message": "Invalid BGM stream payload"},
        )
        await websocket.close(code=1003)
    except WebSocketDisconnect:
        return None
    return None


async def _parse_stream_scenario_id(
    websocket: WebSocket,
    scenario_id: str,
) -> uuid.UUID | None:
    try:
        return uuid.UUID(scenario_id)
    except ValueError:
        await websocket.send_json({"type": "error", "message": "Invalid scenario_id"})
        await websocket.close(code=1003)
        return None


async def _validate_stream_fields(
    websocket: WebSocket,
    mood: str,
    prompt: str,
) -> tuple[str, str] | None:
    normalized_mood = mood.strip().lower()
    normalized_prompt = prompt.strip()
    if normalized_mood and normalized_prompt:
        return normalized_mood, normalized_prompt
    await websocket.send_json(
        {"type": "error", "message": "mood and music_prompt are required"},
    )
    await websocket.close(code=1003)
    return None


async def _stream_and_cache_bgm(
    websocket: WebSocket,
    scenario_id: uuid.UUID,
    mood: str,
    prompt: str,
) -> None:
    with Session(engine) as db:
        cached_path = _bgm_service.get_cached_bgm_path(db, scenario_id, mood)
        if cached_path:
            payload = {
                "type": "cached",
                "path": f"generated-bgm/{cached_path}",
                "mood": mood,
            }
            await websocket.send_json(payload)
            await websocket.close()
            return
        if _bgm_service.is_pending(db, scenario_id, mood):
            await websocket.send_json({"type": "generating", "mood": mood})
            await websocket.close()
            return

    _bgm_service.register_pending_prompt(scenario_id, mood, prompt)
    await _bgm_service.generate_and_cache_detached(
        scenario_id,
        mood,
        prompt,
        session_factory=_new_session,
    )

    with Session(engine) as db:
        cached_path = _bgm_service.get_cached_bgm_path(db, scenario_id, mood)
        is_pending = _bgm_service.is_pending(db, scenario_id, mood)
        if cached_path:
            payload = {
                "type": "cached",
                "path": f"generated-bgm/{cached_path}",
                "mood": mood,
            }
            await websocket.send_json(payload)
        elif is_pending:
            await websocket.send_json({"type": "generating", "mood": mood})
        await websocket.close()


def _new_session() -> Session:
    return Session(engine)


def _authorize_scenario_access(
    db: Session,
    scenario_id: uuid.UUID,
    *,
    auth_token: str | None,
    authorization_header: str | None,
) -> None:
    scenario = _scenario_gw.get_by_id(db, scenario_id)
    if scenario is None:
        raise HTTPException(status_code=404, detail="scenario not found")
    if scenario.is_public:
        return

    user_id = _resolve_user_id(
        auth_token=auth_token,
        authorization_header=authorization_header,
    )
    if user_id is None:
        raise HTTPException(status_code=401, detail="authentication required")
    if scenario.created_by != user_id:
        raise HTTPException(status_code=403, detail="forbidden")


def _resolve_user_id(
    *,
    auth_token: str | None,
    authorization_header: str | None,
) -> uuid.UUID | None:
    token = (auth_token or "").strip()
    if not token:
        token = _extract_bearer_token(authorization_header) or ""
    if not token:
        return None

    try:
        user = SupabaseClient(access_token=token).get_user()
    except Exception as exc:
        raise HTTPException(status_code=401, detail="invalid auth token") from exc
    if user is None:
        raise HTTPException(status_code=401, detail="invalid auth token")
    try:
        return uuid.UUID(str(user.id))
    except ValueError as exc:
        raise HTTPException(status_code=401, detail="invalid auth token") from exc


def _extract_bearer_token(authorization_header: str | None) -> str | None:
    if not authorization_header:
        return None
    if not authorization_header.startswith("Bearer "):
        return None
    token = authorization_header.split(" ", 1)[1].strip()
    return token or None
