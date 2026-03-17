"""Tests for AdkGmClient (ADK-backed GM LLM client).

AdkGmClient wraps google-adk Runner + DatabaseSessionService as a thin adapter.
Only the I/O boundary (runner.run_async -> Gemini API) is replaced in tests.
create_async_engine is lazy, so DatabaseSessionService can be instantiated with
a PostgreSQL URL without a running server as long as no session methods are called.
"""

from __future__ import annotations

import os
from unittest.mock import AsyncMock, MagicMock

import pytest
from google.adk.memory.base_memory_service import SearchMemoryResponse

from src.domain.entity.gm_types import GmDecisionResponse


def _make_memory_service_mock() -> MagicMock:
    """Build a mock for GameMemoryService.

    GameMemoryService はモジュールレベルで DATABASE_URL を必須とするため、
    create_autospec は使用できない (テスト収集時にインポートが失敗する)。
    代わりに AsyncMock を手動で設定し、呼び出し検証を可能にする。
    """
    mock = MagicMock()
    mock.trigger_compression_if_due = AsyncMock()
    mock.add_session_to_memory = AsyncMock()
    mock.search_memory = AsyncMock(return_value=SearchMemoryResponse())
    return mock


def _make_final_event(json_text: str) -> object:
    """Build a MagicMock mimicking an ADK final response event.

    part.thought is set to None so that the `if part.text and not part.thought`
    filter used inside AdkGmClient.decide() does not exclude it.
    """
    event = MagicMock()
    event.is_final_response.return_value = True
    part = MagicMock()
    part.text = json_text
    part.thought = None
    event.content = MagicMock()
    event.content.parts = [part]
    return event


def _make_empty_final_event() -> object:
    """Build a final response event with no content."""
    event = MagicMock()
    event.is_final_response.return_value = True
    event.content = None
    return event


class TestAdkSessionService:
    """Tests for _adk_session_service() factory function."""

    def test_url_converted_to_asyncpg(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """postgresql:// URL must be converted to postgresql+asyncpg://."""
        monkeypatch.setenv(
            "DATABASE_URL", "postgresql://postgres:postgres@db:5432/test"
        )

        from src.infra.adk_gm_client import _adk_session_service

        service = _adk_session_service()

        assert service.db_engine.url.drivername == "postgresql+asyncpg"

    def test_already_asyncpg_url_preserved(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """postgresql+asyncpg:// URL must not be double-converted."""
        monkeypatch.setenv(
            "DATABASE_URL",
            "postgresql+asyncpg://postgres:postgres@db:5432/test",
        )

        from src.infra.adk_gm_client import _adk_session_service

        service = _adk_session_service()

        assert service.db_engine.url.drivername == "postgresql+asyncpg"
        assert service.db_engine.url.host == "db"

    def test_database_url_env_var_used(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """DATABASE_URL env var must override the built-in default."""
        monkeypatch.setenv(
            "DATABASE_URL",
            "postgresql://postgres:postgres@custom-host:5432/mydb",
        )

        from src.infra.adk_gm_client import _adk_session_service

        service = _adk_session_service()

        assert service.db_engine.url.host == "custom-host"
        assert service.db_engine.url.database == "mydb"

    def test_connect_args_use_adk_schema(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """connect_args must set search_path=adk to isolate ADK tables."""
        monkeypatch.setenv(
            "DATABASE_URL", "postgresql://postgres:postgres@db:5432/test"
        )

        from google.adk.sessions import DatabaseSessionService

        from src.infra.adk_gm_client import _adk_session_service

        captured: dict[str, object] = {}
        original_init = DatabaseSessionService.__init__

        def _capture_init(self: object, db_url: str, **kwargs: object) -> None:
            captured.update(kwargs)
            original_init(self, db_url, **kwargs)  # type: ignore[arg-type]

        monkeypatch.setattr(DatabaseSessionService, "__init__", _capture_init)

        _adk_session_service()

        assert captured.get("connect_args") == {
            "server_settings": {"search_path": "adk"}
        }

    def test_sslmode_require_converted_to_connect_args(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """sslmode=require in URL must be stripped and ssl=True added to connect_args.

        asyncpg does not interpret the sslmode query parameter in the URL.
        Ref: https://github.com/MagicStack/asyncpg/issues/737
        """
        monkeypatch.setenv(
            "DATABASE_URL",
            "postgresql://postgres:postgres@db:5432/test?sslmode=require",
        )

        from google.adk.sessions import DatabaseSessionService

        from src.infra.adk_gm_client import _adk_session_service

        captured: dict[str, object] = {}
        original_init = DatabaseSessionService.__init__

        def _capture_init(self: object, db_url: str, **kwargs: object) -> None:
            captured["db_url"] = db_url
            captured.update(kwargs)
            original_init(self, db_url, **kwargs)  # type: ignore[arg-type]

        monkeypatch.setattr(DatabaseSessionService, "__init__", _capture_init)

        _adk_session_service()

        # sslmode=require must be removed from the URL
        assert "sslmode" not in str(captured.get("db_url", ""))
        # ssl=True must be present in connect_args
        connect_args = captured.get("connect_args", {})
        assert isinstance(connect_args, dict)
        assert connect_args.get("ssl") is True
        assert connect_args.get("server_settings") == {"search_path": "adk"}

    def test_no_ssl_without_sslmode(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """connect_args must NOT include ssl when sslmode is absent (local env)."""
        monkeypatch.setenv(
            "DATABASE_URL",
            "postgresql://postgres:postgres@localhost:5432/test",
        )

        from google.adk.sessions import DatabaseSessionService

        from src.infra.adk_gm_client import _adk_session_service

        captured: dict[str, object] = {}
        original_init = DatabaseSessionService.__init__

        def _capture_init(self: object, db_url: str, **kwargs: object) -> None:
            captured.update(kwargs)
            original_init(self, db_url, **kwargs)  # type: ignore[arg-type]

        monkeypatch.setattr(DatabaseSessionService, "__init__", _capture_init)

        _adk_session_service()

        connect_args = captured.get("connect_args", {})
        assert isinstance(connect_args, dict)
        assert "ssl" not in connect_args


class TestAdkGmClientDecide:
    """Tests for AdkGmClient.decide()."""

    @pytest.mark.asyncio
    async def test_decide_returns_gm_decision_response(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """decide() should return GmDecisionResponse parsed from ADK output."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())

        decision = GmDecisionResponse(
            decision_type="narrate",
            narration_text="You step into the dimly lit tavern.",
        )
        fake_event = _make_final_event(decision.model_dump_json())

        async def fake_run_async(**_: object) -> object:
            yield fake_event

        client._runner.run_async = fake_run_async  # type: ignore[assignment]

        result = await client.decide(
            prompt="I enter the tavern.",
            session_id="test-session-1",
            game_session_id="test-game-session",
        )

        assert result.decision_type == "narrate"
        assert result.narration_text == "You step into the dimly lit tavern."

    @pytest.mark.asyncio
    async def test_decide_reuses_session_for_auto_advance(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Same session_id across calls should reuse the same ADK session."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())

        turn1 = GmDecisionResponse(decision_type="narrate", narration_text="Turn 1.")
        turn2 = GmDecisionResponse(decision_type="choice", narration_text="Turn 2.")

        call_count = 0
        received_session_ids: list[str] = []

        async def fake_run_async(**kwargs: object) -> object:
            nonlocal call_count
            call_count += 1
            received_session_ids.append(str(kwargs.get("session_id", "")))
            if call_count == 1:
                yield _make_final_event(turn1.model_dump_json())
            else:
                yield _make_final_event(turn2.model_dump_json())

        client._runner.run_async = fake_run_async  # type: ignore[assignment]

        result1 = await client.decide(
            prompt="Turn 1",
            session_id="same-session",
            game_session_id="test-game-session",
        )
        result2 = await client.decide(
            prompt="Turn 2",
            session_id="same-session",
            game_session_id="test-game-session",
        )

        assert result1.decision_type == "narrate"
        assert result2.decision_type == "choice"
        assert received_session_ids[0] == "same-session"
        assert received_session_ids[1] == "same-session"

    @pytest.mark.asyncio
    async def test_decide_skips_non_final_events(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Non-final response events must be skipped; only the final event is used."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())

        decision = GmDecisionResponse(
            decision_type="choice", narration_text="Make a choice."
        )

        non_final = MagicMock()
        non_final.is_final_response.return_value = False
        final = _make_final_event(decision.model_dump_json())

        async def fake_run_async(**_: object) -> object:
            yield non_final
            yield final

        client._runner.run_async = fake_run_async  # type: ignore[assignment]

        result = await client.decide(
            prompt="test",
            session_id="test-session",
            game_session_id="test-game-session",
        )

        assert result.decision_type == "choice"

    @pytest.mark.asyncio
    async def test_decide_filters_thought_parts(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Parts with thought=True must be excluded before JSON parsing."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())

        decision = GmDecisionResponse(
            decision_type="narrate", narration_text="Valid response."
        )

        event = MagicMock()
        event.is_final_response.return_value = True
        thought_part = MagicMock()
        thought_part.text = "Internal reasoning text that is not valid JSON"
        thought_part.thought = True  # must be excluded
        normal_part = MagicMock()
        normal_part.text = decision.model_dump_json()
        normal_part.thought = None
        event.content = MagicMock()
        event.content.parts = [thought_part, normal_part]

        async def fake_run_async(**_: object) -> object:
            yield event

        client._runner.run_async = fake_run_async  # type: ignore[assignment]

        result = await client.decide(
            prompt="test",
            session_id="test-session",
            game_session_id="test-game-session",
        )

        # If thought_part were NOT filtered, JSON parsing would fail because
        # the combined text would be invalid JSON.
        assert result.decision_type == "narrate"

    @pytest.mark.asyncio
    async def test_decide_raises_on_whitespace_only_text(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """decide() should raise RuntimeError when all parts contain only whitespace."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())

        event = MagicMock()
        event.is_final_response.return_value = True
        part = MagicMock()
        part.text = "   "  # whitespace only — text.strip() is empty
        part.thought = None
        event.content = MagicMock()
        event.content.parts = [part]

        async def fake_run_async(**_: object) -> object:
            yield event

        client._runner.run_async = fake_run_async  # type: ignore[assignment]

        with pytest.raises(RuntimeError, match="no structured output"):
            await client.decide(
                prompt="test",
                session_id="test-session",
                game_session_id="test-game-session",
            )

    @pytest.mark.asyncio
    async def test_decide_raises_on_empty_output(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """decide() should raise RuntimeError when ADK returns no content."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())

        async def fake_run_async(**_: object) -> object:
            yield _make_empty_final_event()

        client._runner.run_async = fake_run_async  # type: ignore[assignment]

        with pytest.raises(RuntimeError, match="no structured output"):
            await client.decide(
                prompt="test",
                session_id="test-session",
                game_session_id="test-game-session",
            )

    @pytest.mark.asyncio
    async def test_decide_raises_when_run_async_fails(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """decide() should propagate exceptions from run_async."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())

        async def fake_run_async_error(**_: object) -> object:
            raise RuntimeError("ADK API error")
            yield  # pragma: no cover

        client._runner.run_async = fake_run_async_error  # type: ignore[assignment]

        with pytest.raises(RuntimeError, match="ADK API error"):
            await client.decide(
                prompt="test",
                session_id="test-session",
                game_session_id="test-game-session",
            )

    @pytest.mark.asyncio
    async def test_decide_injects_memory_context_into_prompt(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Memory context must be prepended to the prompt as <PAST_CONVERSATIONS>."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from google.adk.memory.memory_entry import MemoryEntry
        from google.genai import types as genai_types

        from src.infra.adk_gm_client import AdkGmClient

        memory_mock = _make_memory_service_mock()
        memory_mock.search_memory = AsyncMock(
            return_value=SearchMemoryResponse(
                memories=[
                    MemoryEntry(
                        content=genai_types.Content(
                            parts=[genai_types.Part(text="# Story So Far\nTest ctx.")],
                            role="user",
                        )
                    )
                ]
            )
        )
        client = AdkGmClient(memory_service=memory_mock)

        received_prompt: list[str] = []

        async def fake_run_async(**kwargs: object) -> object:
            msg = kwargs.get("new_message")
            if msg and hasattr(msg, "parts"):
                received_prompt.extend(p.text for p in msg.parts if p.text)
            decision = GmDecisionResponse(
                decision_type="narrate", narration_text="Test."
            )
            yield _make_final_event(decision.model_dump_json())

        client._runner.run_async = fake_run_async  # type: ignore[assignment]

        await client.decide(
            prompt="Player action.",
            session_id="test-session",
            game_session_id="11111111-1111-1111-1111-111111111111",
        )

        assert len(received_prompt) == 1
        assert "<PAST_CONVERSATIONS>" in received_prompt[0]
        assert "# Story So Far" in received_prompt[0]
        assert "Player action." in received_prompt[0]

    @pytest.mark.asyncio
    async def test_decide_skips_memory_prefix_when_no_context(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Prompt must be passed as-is when search_memory returns no memories."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())

        received_prompt: list[str] = []

        async def fake_run_async(**kwargs: object) -> object:
            msg = kwargs.get("new_message")
            if msg and hasattr(msg, "parts"):
                received_prompt.extend(p.text for p in msg.parts if p.text)
            decision = GmDecisionResponse(
                decision_type="narrate", narration_text="Test."
            )
            yield _make_final_event(decision.model_dump_json())

        client._runner.run_async = fake_run_async  # type: ignore[assignment]

        await client.decide(
            prompt="Player action.",
            session_id="test-session",
            game_session_id="11111111-1111-1111-1111-111111111111",
        )

        assert len(received_prompt) == 1
        assert received_prompt[0] == "Player action."
        assert "<PAST_CONVERSATIONS>" not in received_prompt[0]

    @pytest.mark.asyncio
    async def test_decide_calls_trigger_compression_after_decision(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """trigger_compression_if_due() must be called after decide()."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        memory_mock = _make_memory_service_mock()
        client = AdkGmClient(memory_service=memory_mock)

        decision = GmDecisionResponse(decision_type="narrate", narration_text="Test.")

        async def fake_run_async(**_: object) -> object:
            yield _make_final_event(decision.model_dump_json())

        client._runner.run_async = fake_run_async  # type: ignore[assignment]

        await client.decide(
            prompt="test",
            session_id="test-session",
            game_session_id="11111111-1111-1111-1111-111111111111",
        )

        memory_mock.trigger_compression_if_due.assert_awaited_once_with(
            "11111111-1111-1111-1111-111111111111"
        )

    @pytest.mark.asyncio
    async def test_cleanup_session_deletes_adk_session(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """cleanup_session() should call add_session_to_memory then delete_session."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        memory_mock = _make_memory_service_mock()
        client = AdkGmClient(memory_service=memory_mock)

        fake_session = MagicMock()
        fake_session.user_id = "test-game-session"
        get_mock = AsyncMock(return_value=fake_session)
        delete_mock = AsyncMock()
        client._runner.session_service.get_session = get_mock  # type: ignore[method-assign]
        client._runner.session_service.delete_session = delete_mock  # type: ignore[method-assign]

        await client.cleanup_session(
            "session-to-delete", game_session_id="test-game-session"
        )

        get_mock.assert_awaited_once_with(
            app_name="gm",
            user_id="test-game-session",
            session_id="session-to-delete",
        )
        memory_mock.add_session_to_memory.assert_awaited_once_with(fake_session)
        delete_mock.assert_awaited_once_with(
            app_name="gm",
            user_id="test-game-session",
            session_id="session-to-delete",
        )

    @pytest.mark.asyncio
    async def test_cleanup_session_swallows_delete_error(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """cleanup_session() must not propagate errors on session deletion failure."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())
        client._runner.session_service.delete_session = AsyncMock(  # type: ignore[method-assign]
            side_effect=RuntimeError("session not found"),
        )

        # No exception should be raised
        await client.cleanup_session(
            "nonexistent-session", game_session_id="test-game-session"
        )

    @pytest.mark.asyncio
    async def test_cleanup_session_swallows_get_session_error(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """cleanup_session() must not propagate get_session errors.

        delete_session must still be attempted even when get_session fails.
        """
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        memory_mock = _make_memory_service_mock()
        client = AdkGmClient(memory_service=memory_mock)
        client._runner.session_service.get_session = AsyncMock(  # type: ignore[method-assign]
            side_effect=RuntimeError("connection error"),
        )
        delete_mock = AsyncMock()
        client._runner.session_service.delete_session = delete_mock  # type: ignore[method-assign]

        # No exception should be raised
        await client.cleanup_session("session-id", game_session_id="test-game-session")

        # add_session_to_memory must NOT be called when get_session fails
        memory_mock.add_session_to_memory.assert_not_awaited()
        # delete_session must still be attempted
        delete_mock.assert_awaited_once()


class TestAdkGmClientInit:
    """Tests for AdkGmClient initialization."""

    def test_raises_without_api_key(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """Should raise ValueError when no API key env var is set."""
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        monkeypatch.delenv("GOOGLE_API_KEY", raising=False)

        from src.infra.adk_gm_client import AdkGmClient

        with pytest.raises(ValueError, match="API_KEY"):
            AdkGmClient(memory_service=_make_memory_service_mock())

    def test_gemini_api_key_accepted(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """GEMINI_API_KEY alone must be sufficient to initialize AdkGmClient."""
        monkeypatch.setenv("GEMINI_API_KEY", "gemini-only-key")
        monkeypatch.delenv("GOOGLE_API_KEY", raising=False)

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())

        assert client._runner is not None

    def test_google_api_key_accepted(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """GOOGLE_API_KEY alone must be sufficient to initialize AdkGmClient."""
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        monkeypatch.setenv("GOOGLE_API_KEY", "google-only-key")

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())

        assert client._runner is not None

    def test_gemini_api_key_maps_to_google_api_key(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """GEMINI_API_KEY must be mapped to GOOGLE_API_KEY via os.environ.setdefault."""
        monkeypatch.setenv("GEMINI_API_KEY", "gemini-key-value")
        monkeypatch.delenv("GOOGLE_API_KEY", raising=False)

        from src.infra.adk_gm_client import AdkGmClient

        AdkGmClient(memory_service=_make_memory_service_mock())

        assert os.environ.get("GOOGLE_API_KEY") == "gemini-key-value"

    def test_auto_create_session_is_enabled(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Runner must be constructed with auto_create_session=True."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-key")

        from src.infra.adk_gm_client import AdkGmClient

        client = AdkGmClient(memory_service=_make_memory_service_mock())

        assert client._runner.auto_create_session is True
