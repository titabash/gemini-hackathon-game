"""Fixtures shared by all tests in tests/usecase/.

Auto-patches AdkGmClient in gm_turn_usecase so that GmTurnUseCase()
can be instantiated without a real GEMINI_API_KEY.  The real
GmDecisionService code-path is preserved; individual tests replace
uc.decision_svc.decide with AsyncMock as needed.
"""

from __future__ import annotations

import os

# gm_turn_usecase imports GameMemoryService which imports db_client.engine at
# module level; db_client raises ValueError when DATABASE_URL is not set.
# Set a placeholder URL before any module import so the engine can be created.
# The actual DB is never connected to in these unit tests (all DB ops are
# mocked), so a syntactically-valid but unreachable URL is sufficient.
os.environ.setdefault(
    "DATABASE_URL",
    "postgresql://test:test@localhost:5432/test_usecase",
)

from typing import TYPE_CHECKING
from unittest.mock import patch

import pytest

if TYPE_CHECKING:
    from collections.abc import Generator


@pytest.fixture(autouse=True)
def _patch_adk_client() -> Generator[None]:
    """Patch AdkGmClient and reset the module-level singleton per test.

    Without this fixture, GmTurnUseCase.__init__ calls AdkGmClient() which
    raises ValueError when GEMINI_API_KEY is not set in the test environment.

    The singleton _adk_client is reset to None before each test so the
    patched class (not a stale real instance) is used for initialisation.
    """
    import src.usecase.gm_turn_usecase as _uc_module

    with patch("src.usecase.gm_turn_usecase.AdkGmClient", autospec=True):
        original = _uc_module._adk_client
        _uc_module._adk_client = None
        yield
        _uc_module._adk_client = original
