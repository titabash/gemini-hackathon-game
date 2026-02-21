from fastapi import Depends, HTTPException, status
from fastapi.security import APIKeyHeader
from supabase_auth.types import User

from infra.supabase_client import SupabaseClient
from src.util.logging import get_logger

authorization_header = APIKeyHeader(name="Authorization", auto_error=True)

logger = get_logger(__name__)


async def verify_token(auth_header: str = Depends(authorization_header)) -> User:
    if not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="無効な認証トークンフォーマットです",
        )

    token = auth_header.split(" ")[1]

    try:
        supabase_client = SupabaseClient(access_token=token)
        user = supabase_client.get_user()
        logger.info("user authenticated", user_id=user.id if user else None)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_FORBIDDEN,
                detail="Unauthorized",
            )
        return user
    except Exception as e:
        logger.exception("authentication failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthorized",
        )
