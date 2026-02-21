"""Base controller with health check endpoint."""

from fastapi import APIRouter

router = APIRouter()


@router.get("/healthcheck")
async def healthcheck() -> dict[str, str]:
    """Health check endpoint."""
    return {"message": "OK"}
