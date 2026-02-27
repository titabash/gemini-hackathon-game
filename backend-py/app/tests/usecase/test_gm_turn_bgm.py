"""Tests for BGM event integration in GmTurnUseCase."""

from __future__ import annotations

import uuid
from types import SimpleNamespace
from unittest.mock import ANY, AsyncMock, MagicMock, patch

import pytest

from src.domain.entity.gm_types import GmDecisionResponse, GmTurnRequest


async def _aiter(events: list[str]) -> object:
    for event in events:
        yield event


async def _collect(it: object) -> list[str]:
    return [e async for e in it]


async def _empty_stream(*_args: object, **_kwargs: object) -> object:
    if False:
        yield ""


def _request() -> GmTurnRequest:
    return GmTurnRequest(
        session_id="00000000-0000-0000-0000-000000000001",
        input_type="do",
        input_text="advance",
    )


def _session(scenario_id: uuid.UUID) -> SimpleNamespace:
    return SimpleNamespace(
        id=uuid.uuid4(),
        status="active",
        scenario_id=scenario_id,
        current_state={},
    )


def _mock_context() -> SimpleNamespace:
    return SimpleNamespace(
        current_turn_number=1,
        previous_bgm_mood=None,
    )


@pytest.mark.asyncio
async def test_emits_bgm_update_when_cached() -> None:
    with (
        patch("src.usecase.gm_turn_usecase.GeminiClient", autospec=True),
        patch("src.usecase.gm_turn_usecase.StorageService", autospec=True),
    ):
        from src.usecase.gm_turn_usecase import GmTurnUseCase

        scenario_id = uuid.uuid4()
        uc = GmTurnUseCase()
        uc.session_gw.get_by_id = MagicMock(return_value=_session(scenario_id))
        uc.context_svc.build_context = MagicMock(
            return_value=_mock_context(),
        )
        uc._resolve_decision = AsyncMock(
            return_value=GmDecisionResponse(
                decision_type="narrate",
                narration_text="ok",
                bgm_mood="battle",
                bgm_music_prompt="epic orchestral, loopable",
            ),
        )
        uc._persist_turn = MagicMock(return_value=1)
        uc._evaluate_and_apply = MagicMock(return_value=False)
        uc.bridge_svc.stream_decision = _empty_stream
        uc._resolve_backgrounds = _empty_stream
        uc._resolve_npc_emotion_assets = _empty_stream
        uc._resolve_npc_images = MagicMock(return_value={})
        uc.context_gw.get_by_session = MagicMock(return_value=None)
        uc.context_svc.should_compress = MagicMock(return_value=False)
        uc.bgm_svc.get_cached_bgm_path = MagicMock(
            return_value="scenarios/a/battle.mp3"
        )
        uc.bgm_svc.generate_and_cache = AsyncMock()

        events = await _collect(uc.execute(_request(), MagicMock()))

        assert any('"type": "bgmUpdate"' in e for e in events)
        uc.bgm_svc.generate_and_cache.assert_not_called()


@pytest.mark.asyncio
async def test_emits_bgm_update_when_generated_on_cache_miss() -> None:
    with (
        patch("src.usecase.gm_turn_usecase.GeminiClient", autospec=True),
        patch("src.usecase.gm_turn_usecase.StorageService", autospec=True),
    ):
        from src.usecase.gm_turn_usecase import GmTurnUseCase

        scenario_id = uuid.uuid4()
        uc = GmTurnUseCase()
        uc.session_gw.get_by_id = MagicMock(return_value=_session(scenario_id))
        uc.context_svc.build_context = MagicMock(
            return_value=_mock_context(),
        )
        uc._resolve_decision = AsyncMock(
            return_value=GmDecisionResponse(
                decision_type="narrate",
                narration_text="ok",
                bgm_mood="mysterious",
                bgm_music_prompt="deep drones and bells, loopable",
            ),
        )
        uc._persist_turn = MagicMock(return_value=1)
        uc._evaluate_and_apply = MagicMock(return_value=False)
        uc.bridge_svc.stream_decision = _empty_stream
        uc._resolve_backgrounds = _empty_stream
        uc._resolve_npc_emotion_assets = _empty_stream
        uc._resolve_npc_images = MagicMock(return_value={})
        uc.context_gw.get_by_session = MagicMock(return_value=None)
        uc.context_svc.should_compress = MagicMock(return_value=False)
        uc.bgm_svc.get_cached_bgm_path = MagicMock(
            side_effect=[
                None,
                "scenarios/11111111-1111-1111-1111-111111111111/mysterious.mp3",
            ]
        )
        uc.bgm_svc.generate_and_cache = AsyncMock(
            return_value="https://cdn.example.com/generated.mp3",
        )

        events = await _collect(uc.execute(_request(), MagicMock()))

        assert any('"type": "bgmGenerating"' in e for e in events)
        assert any('"type": "bgmUpdate"' in e for e in events)
        uc.bgm_svc.generate_and_cache.assert_called_once_with(
            db=ANY,
            scenario_id=scenario_id,
            mood="mysterious",
            music_prompt="deep drones and bells, loopable",
        )


@pytest.mark.asyncio
async def test_skips_bgm_when_cache_lookup_raises() -> None:
    with (
        patch("src.usecase.gm_turn_usecase.GeminiClient", autospec=True),
        patch("src.usecase.gm_turn_usecase.StorageService", autospec=True),
    ):
        from src.usecase.gm_turn_usecase import GmTurnUseCase

        scenario_id = uuid.uuid4()
        uc = GmTurnUseCase()
        uc.session_gw.get_by_id = MagicMock(return_value=_session(scenario_id))
        uc.context_svc.build_context = MagicMock(
            return_value=_mock_context(),
        )
        uc._resolve_decision = AsyncMock(
            return_value=GmDecisionResponse(
                decision_type="narrate",
                narration_text="ok",
                bgm_mood="mysterious",
                bgm_music_prompt="deep drones and bells, loopable",
            ),
        )
        uc._persist_turn = MagicMock(return_value=1)
        uc._evaluate_and_apply = MagicMock(return_value=False)
        uc.bridge_svc.stream_decision = _empty_stream
        uc._resolve_backgrounds = _empty_stream
        uc._resolve_npc_emotion_assets = _empty_stream
        uc._resolve_npc_images = MagicMock(return_value={})
        uc.context_gw.get_by_session = MagicMock(return_value=None)
        uc.context_svc.should_compress = MagicMock(return_value=False)
        uc.bgm_svc.get_cached_bgm_path = MagicMock(side_effect=RuntimeError("boom"))
        uc.bgm_svc.generate_and_cache = AsyncMock()

        events = await _collect(uc.execute(_request(), MagicMock()))

        assert not any('"type": "bgmUpdate"' in e for e in events)
        assert not any('"type": "bgmGenerating"' in e for e in events)
        uc.bgm_svc.generate_and_cache.assert_not_called()


@pytest.mark.asyncio
async def test_bgm_update_is_emitted_before_done_event() -> None:
    with (
        patch("src.usecase.gm_turn_usecase.GeminiClient", autospec=True),
        patch("src.usecase.gm_turn_usecase.StorageService", autospec=True),
    ):
        from src.usecase.gm_turn_usecase import GmTurnUseCase

        scenario_id = uuid.uuid4()
        uc = GmTurnUseCase()
        uc.session_gw.get_by_id = MagicMock(return_value=_session(scenario_id))
        uc.context_svc.build_context = MagicMock(
            return_value=_mock_context(),
        )
        uc._resolve_decision = AsyncMock(
            return_value=GmDecisionResponse(
                decision_type="narrate",
                narration_text="ok",
                bgm_mood="mysterious",
                bgm_music_prompt="deep drones and bells, loopable",
            ),
        )
        uc._persist_turn = MagicMock(return_value=1)
        uc._evaluate_and_apply = MagicMock(return_value=False)

        async def _bridge_with_done(*_args: object, **_kwargs: object) -> object:
            yield 'data: {"type":"nodesReady","nodes":[]}\n\n'
            yield 'data: {"type": "done"}\n\n'

        uc.bridge_svc.stream_decision = _bridge_with_done
        uc._resolve_backgrounds = _empty_stream
        uc._resolve_npc_emotion_assets = _empty_stream
        uc._resolve_npc_images = MagicMock(return_value={})
        uc.context_gw.get_by_session = MagicMock(return_value=None)
        uc.context_svc.should_compress = MagicMock(return_value=False)
        uc.bgm_svc.get_cached_bgm_path = MagicMock(
            side_effect=[None, "scenarios/any/mysterious.mp3"]
        )
        uc.bgm_svc.generate_and_cache = AsyncMock(
            return_value="https://cdn.example.com/generated.mp3",
        )

        events = await _collect(uc.execute(_request(), MagicMock()))
        bgm_idx = next(
            i for i, event in enumerate(events) if '"type": "bgmUpdate"' in event
        )
        done_idx = next(
            i for i, event in enumerate(events) if '"type": "done"' in event
        )

        assert bgm_idx < done_idx


def test_fallback_bgm_prompt_is_instrumental_only() -> None:
    with (
        patch("src.usecase.gm_turn_usecase.GeminiClient", autospec=True),
        patch("src.usecase.gm_turn_usecase.StorageService", autospec=True),
    ):
        from src.usecase.gm_turn_usecase import GmTurnUseCase

        prompt = GmTurnUseCase._fallback_bgm_prompt(
            GmDecisionResponse(
                decision_type="narrate",
                narration_text="ok",
                scene_description="Ancient ruins at dusk",
            ),
            "mysterious",
        )

    assert "instrumental only" in prompt
    assert "no vocals" in prompt
    assert "no lyrics" in prompt
