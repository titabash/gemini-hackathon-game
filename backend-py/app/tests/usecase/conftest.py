"""Fixtures shared by all tests in tests/usecase/.

Auto-patches AdkGmClient in gm_turn_usecase so that GmTurnUseCase()
can be instantiated without a real GEMINI_API_KEY.  The real
GmDecisionService code-path is preserved; individual tests replace
uc.decision_svc.decide with AsyncMock as needed.
"""

from __future__ import annotations

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
