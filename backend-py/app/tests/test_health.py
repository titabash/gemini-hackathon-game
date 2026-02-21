"""Health check endpoint tests."""

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def client(monkeypatch):
    """Create a test client for the FastAPI application."""
    # Set mock DATABASE_URL for testing
    monkeypatch.setenv("DATABASE_URL", "postgresql://test:test@localhost:5432/test")

    # Import here to avoid circular imports
    from src.app import app

    return TestClient(app)


def test_health_check(client) -> None:
    """Test the health check endpoint returns 200 OK."""
    response = client.get("/healthcheck")
    assert response.status_code == 200
    assert response.json() == {"message": "OK"}
