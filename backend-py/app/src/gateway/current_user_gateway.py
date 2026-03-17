from sqlmodel import Session, select

from domain.entity.models import Users
from src.infra.supabase_client import SupabaseClient


class CurrentUserGateway:
    def __init__(self, access_token: str | None = None) -> None:
        """Initialize the gateway with the Supabase client."""
        self.supabase_client = SupabaseClient(access_token)

    def get_current_user(self, session: Session) -> Users | None:
        """Get the current user from the database."""
        user = self.supabase_client.get_user()
        if user is None:
            msg = "User not found"
            raise Exception(msg)

        statement = select(Users).where(Users.id == user.id)
        return session.exec(statement).first()
