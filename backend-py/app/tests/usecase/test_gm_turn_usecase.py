"""Tests for GmTurnUseCase turn-limit and condition evaluation integration.

Verifies hard-limit bypass, soft-limit prompt injection,
normal-turn passthrough, condition-triggered session endings,
and assetReady pipeline for node-based backgrounds.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.domain.entity.gm_types import (
    CharacterDisplay,
    FlagChange,
    GmDecisionResponse,
    GmTurnRequest,
    SceneNode,
    SessionEnd,
    StateChanges,
)

if TYPE_CHECKING:
    from collections.abc import AsyncIterator


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_request(
    *,
    session_id: str = "00000000-0000-0000-0000-000000000001",
    input_type: str = "do",
    input_text: str = "look around",
    auto_advance_until_user_action: bool = False,
    max_auto_turns: int = 5,
) -> GmTurnRequest:
    return GmTurnRequest(
        session_id=session_id,
        input_type=input_type,  # type: ignore[arg-type]
        input_text=input_text,
        auto_advance_until_user_action=auto_advance_until_user_action,
        max_auto_turns=max_auto_turns,
    )


def _fake_session(
    *,
    status: str = "active",
    turn: int = 5,
    scenario_id: str = "11111111-1111-1111-1111-111111111111",
    current_state: dict[str, Any] | None = None,
) -> MagicMock:
    sess = MagicMock()
    sess.status = status
    sess.current_turn_number = turn
    sess.id = "00000000-0000-0000-0000-000000000001"
    sess.scenario_id = scenario_id
    sess.current_state = current_state or {}
    return sess


def _fake_decision(
    *,
    state_changes: StateChanges | None = None,
    nodes: list[SceneNode] | None = None,
) -> GmDecisionResponse:
    return GmDecisionResponse(
        decision_type="narrate",
        narration_text="You see a dark room.",
        state_changes=state_changes,
        nodes=nodes,
    )


def _fake_nodes_decision() -> GmDecisionResponse:
    """Build a decision with SceneNode list for node-based tests."""
    return GmDecisionResponse(
        decision_type="narrate",
        narration_text="Summary.",
        nodes=[
            SceneNode(
                type="narration",
                text="A dark cave.",
                background="cave_01",
            ),
            SceneNode(
                type="dialogue",
                text="Hello!",
                speaker="Guard",
                background="A misty forest clearing",
                characters=[
                    CharacterDisplay(
                        npc_name="Guard",
                        expression="anger",
                        position="left",
                    ),
                ],
            ),
            SceneNode(
                type="narration",
                text="Another cave scene.",
                background="cave_01",
            ),
        ],
    )


async def _collect(it: AsyncIterator[str]) -> list[str]:
    return [e async for e in it]


async def _async_iter(items: list[str]) -> AsyncIterator[str]:
    for item in items:
        yield item


def _stub_common(uc: object, *, turn_return: int) -> None:
    """Wire up mutation / persist / compress stubs."""
    uc.mutation_svc.apply = MagicMock()  # type: ignore[attr-defined]
    uc.mutation_svc.apply_session_end = MagicMock()  # type: ignore[attr-defined]
    uc.session_gw.increment_turn = MagicMock(  # type: ignore[attr-defined]
        return_value=turn_return,
    )
    uc.turn_gw.create = MagicMock()  # type: ignore[attr-defined]
    uc.context_gw.get_by_session = MagicMock(  # type: ignore[attr-defined]
        return_value=None,
    )
    uc.npc_gw.get_by_session = MagicMock(  # type: ignore[attr-defined]
        return_value=[],
    )
    uc.npc_gw.get_by_scenario = MagicMock(  # type: ignore[attr-defined]
        return_value=[],
    )


async def _empty_stream(
    *_args: object,
    **_: object,
) -> AsyncIterator[str]:
    return
    yield  # pragma: no cover


class _CtxBuilder:
    """Fluent builder for fake GameContext mocks."""

    def __init__(self) -> None:
        self._attrs: dict[str, object] = {
            "current_turn_number": 5,
            "max_turns": 30,
            "win_conditions": [],
            "fail_conditions": [],
            "current_state": {},
        }
        self._stats: dict[str, object] = {"hp": 100}

    def conditions(
        self,
        *,
        win: list[dict[str, object]] | None = None,
        fail: list[dict[str, object]] | None = None,
    ) -> _CtxBuilder:
        if win is not None:
            self._attrs["win_conditions"] = win
        if fail is not None:
            self._attrs["fail_conditions"] = fail
        return self

    def state(
        self,
        *,
        stats: dict[str, object] | None = None,
        current: dict[str, object] | None = None,
    ) -> _CtxBuilder:
        if stats is not None:
            self._stats = stats
        if current is not None:
            self._attrs["current_state"] = current
        return self

    def build(self) -> MagicMock:
        ctx = MagicMock()
        for k, v in self._attrs.items():
            setattr(ctx, k, v)
        ctx.player = MagicMock()
        ctx.player.stats = self._stats
        return ctx


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


class TestHardLimit:
    """When turn >= max_turns, Gemini must NOT be called."""

    @pytest.mark.asyncio
    async def test_hard_limit_skips_gemini(self) -> None:
        """At hard limit, decision_svc.decide must not be called."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=30),
            )
            uc.context_svc.build_context = MagicMock()
            ctx = uc.context_svc.build_context.return_value
            ctx.current_turn_number = 30
            ctx.max_turns = 30

            uc.decision_svc.decide = AsyncMock(
                return_value=_fake_decision(),
            )
            _stub_common(uc, turn_return=31)

            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))
            uc.decision_svc.decide.assert_not_called()

    @pytest.mark.asyncio
    async def test_hard_limit_yields_bad_end(self) -> None:
        """At hard limit, SSE stream must contain bad_end content."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=30),
            )
            uc.context_svc.build_context = MagicMock()
            ctx = uc.context_svc.build_context.return_value
            ctx.current_turn_number = 30
            ctx.max_turns = 30

            uc.decision_svc.decide = AsyncMock(
                return_value=_fake_decision(),
            )
            _stub_common(uc, turn_return=31)

            captured: list[GmDecisionResponse] = []

            async def _capture_stream(
                decision: GmDecisionResponse,
                **_: object,
            ) -> AsyncIterator[str]:
                captured.append(decision)
                return
                yield  # pragma: no cover

            uc.bridge_svc.stream_decision = _capture_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            assert len(captured) == 1
            d = captured[0]
            assert d.state_changes is not None
            assert d.state_changes.session_end is not None
            assert d.state_changes.session_end.ending_type == "bad_end"


class TestSoftLimit:
    """When close to max_turns, prompt must include convergence instructions."""

    @pytest.mark.asyncio
    async def test_soft_limit_adds_convergence_prompt(self) -> None:
        """Within soft-limit window, prompt must contain turn-limit addition."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=27),
            )
            uc.context_svc.build_context = MagicMock()
            ctx = uc.context_svc.build_context.return_value
            ctx.current_turn_number = 27
            ctx.max_turns = 30

            captured_kw: list[dict[str, object]] = []

            def _spy(
                *_args: object,
                **kwargs: object,
            ) -> str:
                captured_kw.append(kwargs)
                return "mocked prompt"

            uc.context_svc.build_prompt = _spy

            uc.decision_svc.decide = AsyncMock(
                return_value=_fake_decision(),
            )
            _stub_common(uc, turn_return=28)

            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            assert len(captured_kw) == 1
            raw_sections: Any = captured_kw[0].get("extra_sections", [])
            full = "\n".join(str(s) for s in raw_sections if s)
            assert full != ""
            assert "3" in full


class TestNormalTurn:
    """When far from limit, no turn-limit additions should be present."""

    @pytest.mark.asyncio
    async def test_no_convergence_on_early_turn(self) -> None:
        """Early turns must NOT inject convergence prompt."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=5),
            )
            uc.context_svc.build_context = MagicMock()
            ctx = uc.context_svc.build_context.return_value
            ctx.current_turn_number = 5
            ctx.max_turns = 30

            captured_kw: list[dict[str, object]] = []

            def _spy(
                *_args: object,
                **kwargs: object,
            ) -> str:
                captured_kw.append(kwargs)
                return "mocked prompt"

            uc.context_svc.build_prompt = _spy

            uc.decision_svc.decide = AsyncMock(
                return_value=_fake_decision(),
            )
            _stub_common(uc, turn_return=6)

            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            assert len(captured_kw) == 1
            raw_sections: Any = captured_kw[0].get("extra_sections", [])
            soft_parts = [
                str(s) for s in raw_sections if s and "remaining" in str(s).lower()
            ]
            assert soft_parts == []


class TestConditionEvaluation:
    """Condition evaluation integration in the turn pipeline."""

    @pytest.mark.asyncio
    async def test_flags_achieved_triggers_victory(self) -> None:
        """All required flags achieved → session_end(victory) applied."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(
                    turn=10,
                    current_state={"flags": {"clue_a": True}},
                ),
            )
            ctx = (
                _CtxBuilder()
                .conditions(
                    win=[
                        {
                            "id": "w1",
                            "description": "Find clues",
                            "requiredFlags": ["clue_a", "clue_b"],
                        },
                    ],
                    fail=[
                        {
                            "id": "f1",
                            "description": "HP zero",
                            "condition": "pc.stats.hp <= 0",
                        },
                    ],
                )
                .state(
                    stats={"hp": 50},
                    current={"flags": {"clue_a": True}},
                )
                .build()
            )
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")

            # Decision sets clue_b flag → all flags achieved
            decision = _fake_decision(
                state_changes=StateChanges(
                    flag_changes=[
                        FlagChange(flag_id="clue_b", value=True),
                    ],
                ),
            )
            uc.decision_svc.decide = AsyncMock(return_value=decision)
            _stub_common(uc, turn_return=11)
            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            uc.mutation_svc.apply_session_end.assert_called_once()
            call_args = uc.mutation_svc.apply_session_end.call_args
            end: SessionEnd = call_args[0][2]
            assert end.ending_type == "victory"

    @pytest.mark.asyncio
    async def test_hp_zero_triggers_bad_end(self) -> None:
        """HP reaching 0 → session_end(bad_end) applied."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=10),
            )
            ctx = (
                _CtxBuilder()
                .conditions(
                    win=[
                        {
                            "id": "w1",
                            "description": "Find clues",
                            "requiredFlags": ["clue_a"],
                        },
                    ],
                    fail=[
                        {
                            "id": "f1",
                            "description": "HP zero",
                            "condition": "pc.stats.hp <= 0",
                        },
                    ],
                )
                .state(stats={"hp": 10})
                .build()
            )
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")

            # stats_delta makes HP go to 0
            decision = _fake_decision(
                state_changes=StateChanges(stats_delta={"hp": -10}),
            )
            uc.decision_svc.decide = AsyncMock(return_value=decision)
            _stub_common(uc, turn_return=11)
            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            uc.mutation_svc.apply_session_end.assert_called_once()
            call_args = uc.mutation_svc.apply_session_end.call_args
            end: SessionEnd = call_args[0][2]
            assert end.ending_type == "bad_end"

    @pytest.mark.asyncio
    async def test_llm_session_end_skips_evaluation(self) -> None:
        """LLM already set session_end → condition evaluation skipped."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=10),
            )
            ctx = (
                _CtxBuilder()
                .conditions(
                    win=[
                        {
                            "id": "w1",
                            "description": "Win",
                            "requiredFlags": ["a"],
                        },
                    ],
                )
                .state(
                    stats={"hp": 100},
                    current={"flags": {"a": True}},
                )
                .build()
            )
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")

            # LLM already ends session
            decision = _fake_decision(
                state_changes=StateChanges(
                    session_end=SessionEnd(
                        ending_type="custom_end",
                        ending_summary="LLM ended it",
                    ),
                ),
            )
            uc.decision_svc.decide = AsyncMock(return_value=decision)
            _stub_common(uc, turn_return=11)
            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            # apply_session_end should NOT be called (LLM end handled by apply)
            uc.mutation_svc.apply_session_end.assert_not_called()

    @pytest.mark.asyncio
    async def test_normal_turn_no_condition_end(self) -> None:
        """Normal turn without conditions met → no session end."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=5),
            )
            ctx = (
                _CtxBuilder()
                .conditions(
                    win=[
                        {
                            "id": "w1",
                            "description": "Win",
                            "requiredFlags": ["a", "b"],
                        },
                    ],
                    fail=[
                        {
                            "id": "f1",
                            "description": "Fail",
                            "condition": "pc.stats.hp <= 0",
                        },
                    ],
                )
                .build()
            )
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")

            decision = _fake_decision()
            uc.decision_svc.decide = AsyncMock(return_value=decision)
            _stub_common(uc, turn_return=6)
            uc.bridge_svc.stream_decision = _empty_stream

            await _collect(uc.execute(_make_request(), MagicMock()))

            uc.mutation_svc.apply_session_end.assert_not_called()


class TestCollectRequiredAssets:
    """Tests for _collect_required_assets node background collection."""

    def test_collect_deduplicates_backgrounds(self) -> None:
        """Same background ID appearing in multiple nodes → single entry."""
        from src.usecase.gm_turn_usecase import _collect_required_assets

        nodes = [
            SceneNode(type="narration", text="A.", background="cave_01"),
            SceneNode(type="narration", text="B.", background="cave_01"),
            SceneNode(type="dialogue", text="C.", speaker="X"),
        ]
        result = _collect_required_assets(nodes)
        assert len(result) == 1
        assert result[0] == "cave_01"

    def test_collect_multiple_unique_backgrounds(self) -> None:
        """Different backgrounds should all be collected."""
        from src.usecase.gm_turn_usecase import _collect_required_assets

        nodes = [
            SceneNode(type="narration", text="A.", background="cave_01"),
            SceneNode(type="narration", text="B.", background="forest_02"),
            SceneNode(
                type="narration",
                text="C.",
                background="A misty forest",
            ),
        ]
        result = _collect_required_assets(nodes)
        assert len(result) == 3

    def test_collect_skips_none_backgrounds(self) -> None:
        """Nodes without background should not produce entries."""
        from src.usecase.gm_turn_usecase import _collect_required_assets

        nodes = [
            SceneNode(type="narration", text="A."),
            SceneNode(type="dialogue", text="B.", speaker="X"),
        ]
        result = _collect_required_assets(nodes)
        assert result == []

    def test_collect_empty_nodes(self) -> None:
        """Empty node list should return empty list."""
        from src.usecase.gm_turn_usecase import _collect_required_assets

        result = _collect_required_assets([])
        assert result == []


class TestNpcImagePathResolution:
    """Tests for NPC image bucket/path resolution helpers."""

    def test_sessions_path_maps_to_generated_images_bucket(self) -> None:
        """Session-generated NPC image should resolve to generated-images."""
        from src.usecase.gm_turn_usecase import _to_bucketed_npc_path

        result = _to_bucketed_npc_path("sessions/abc123.png")
        assert result == "generated-images/sessions/abc123.png"

    def test_plain_path_maps_to_scenario_assets_bucket(self) -> None:
        """Seed/default NPC image path should resolve to scenario-assets."""
        from src.usecase.gm_turn_usecase import _to_bucketed_npc_path

        result = _to_bucketed_npc_path("npcs/guard.png")
        assert result == "scenario-assets/npcs/guard.png"


# ---------------------------------------------------------------------------
# Helpers for assetReady tests
# ---------------------------------------------------------------------------

_UUID_BG = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"


def _parse_sse_events(raw_events: list[str]) -> list[dict[str, Any]]:
    """Parse SSE event strings into dicts."""
    results: list[dict[str, Any]] = []
    import json

    for raw in raw_events:
        if raw.startswith("data: "):
            payload = json.loads(raw[len("data: ") :].strip())
            results.append(payload)
    return results


def _fake_bg_record(
    *,
    bg_id: str = _UUID_BG,
    image_path: str = "backgrounds/cave.png",
    scenario_id: str | None = "11111111-1111-1111-1111-111111111111",
) -> MagicMock:
    """Create a fake SceneBackgrounds row."""
    import uuid as _uuid

    rec = MagicMock()
    rec.id = _uuid.UUID(bg_id)
    rec.image_path = image_path
    rec.scenario_id = _uuid.UUID(scenario_id) if scenario_id else None
    return rec


def _setup_uc_for_asset_test(
    uc: object,
    *,
    decision: GmDecisionResponse,
) -> None:
    """Common setup for asset resolution tests."""
    uc.session_gw.get_by_id = MagicMock(  # type: ignore[attr-defined]
        return_value=_fake_session(turn=5),
    )
    ctx = _CtxBuilder().build()
    uc.context_svc.build_context = MagicMock(  # type: ignore[attr-defined]
        return_value=ctx,
    )
    uc.context_svc.build_prompt = MagicMock(  # type: ignore[attr-defined]
        return_value="prompt",
    )
    uc.decision_svc.decide = AsyncMock(  # type: ignore[attr-defined]
        return_value=decision,
    )
    _stub_common(uc, turn_return=6)
    uc.bridge_svc.stream_decision = _empty_stream  # type: ignore[attr-defined]
    uc.storage_svc = MagicMock()  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# assetReady pipeline tests
# ---------------------------------------------------------------------------


class TestResolveNodeAssets:
    """Tests for _resolve_node_assets and execute() branching."""

    @pytest.mark.asyncio
    async def test_uuid_background_resolved_from_db(self) -> None:
        """Node background that is a UUID → DB lookup → assetReady."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            decision = _fake_decision(
                nodes=[
                    SceneNode(
                        type="narration",
                        text="A cave.",
                        background=_UUID_BG,
                    ),
                ],
            )
            _setup_uc_for_asset_test(uc, decision=decision)

            uc.bg_gw.find_by_id = MagicMock(
                return_value=_fake_bg_record(),
            )

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            asset_events = [e for e in parsed if e.get("type") == "assetReady"]

            assert len(asset_events) == 1
            assert asset_events[0]["key"] == _UUID_BG
            assert "scenario-assets/" in asset_events[0]["path"]

    @pytest.mark.asyncio
    async def test_text_background_triggers_generation(self) -> None:
        """Node background that is free text → image generation → assetReady."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            desc = "A misty forest clearing"
            decision = _fake_decision(
                nodes=[
                    SceneNode(
                        type="narration",
                        text="Trees.",
                        background=desc,
                    ),
                ],
            )
            _setup_uc_for_asset_test(uc, decision=decision)

            uc.bg_gw.find_by_id = MagicMock(return_value=None)
            uc.bg_gw.find_by_description = MagicMock(return_value=None)
            uc.gemini.generate_image = AsyncMock(return_value=b"fake-png")
            uc.storage_svc.upload_image = MagicMock(
                return_value="sessions/img.png",
            )
            uc.bg_gw.create = MagicMock()

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            asset_events = [e for e in parsed if e.get("type") == "assetReady"]

            assert len(asset_events) == 1
            assert asset_events[0]["key"] == desc
            assert "generated-images/" in asset_events[0]["path"]
            uc.gemini.generate_image.assert_called_once()

    @pytest.mark.asyncio
    async def test_mixed_uuid_and_text_backgrounds(self) -> None:
        """UUID + text backgrounds in one decision → both resolved."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            decision = _fake_decision(
                nodes=[
                    SceneNode(
                        type="narration",
                        text="A.",
                        background=_UUID_BG,
                    ),
                    SceneNode(
                        type="narration",
                        text="B.",
                        background="Dark dungeon",
                    ),
                ],
            )
            _setup_uc_for_asset_test(uc, decision=decision)

            uc.bg_gw.find_by_id = MagicMock(
                return_value=_fake_bg_record(),
            )
            uc.bg_gw.find_by_description = MagicMock(return_value=None)
            uc.gemini.generate_image = AsyncMock(return_value=b"fake-png")
            uc.storage_svc.upload_image = MagicMock(
                return_value="sessions/dungeon.png",
            )
            uc.bg_gw.create = MagicMock()

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            asset_events = [e for e in parsed if e.get("type") == "assetReady"]

            assert len(asset_events) == 2

    @pytest.mark.asyncio
    async def test_duplicate_backgrounds_resolved_once(self) -> None:
        """Same background on multiple nodes → resolved only once."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            decision = _fake_decision(
                nodes=[
                    SceneNode(
                        type="narration",
                        text="A.",
                        background=_UUID_BG,
                    ),
                    SceneNode(
                        type="narration",
                        text="B.",
                        background=_UUID_BG,
                    ),
                ],
            )
            _setup_uc_for_asset_test(uc, decision=decision)

            uc.bg_gw.find_by_id = MagicMock(
                return_value=_fake_bg_record(),
            )

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            asset_events = [e for e in parsed if e.get("type") == "assetReady"]

            assert len(asset_events) == 1
            uc.bg_gw.find_by_id.assert_called_once()

    @pytest.mark.asyncio
    async def test_nodes_path_skips_legacy_image_update(self) -> None:
        """Decision with nodes → no imageUpdate event (assetReady only)."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            decision = GmDecisionResponse(
                decision_type="narrate",
                narration_text="Summary.",
                scene_description="A forest scene",
                selected_background_id=_UUID_BG,
                nodes=[
                    SceneNode(
                        type="narration",
                        text="Trees.",
                        background=_UUID_BG,
                    ),
                ],
            )
            _setup_uc_for_asset_test(uc, decision=decision)

            uc.bg_gw.find_by_id = MagicMock(
                return_value=_fake_bg_record(),
            )

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            image_events = [e for e in parsed if e.get("type") == "imageUpdate"]

            assert image_events == []

    @pytest.mark.asyncio
    async def test_no_nodes_uses_legacy_image_update(self) -> None:
        """Decision without nodes → legacy imageUpdate path."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            decision = GmDecisionResponse(
                decision_type="narrate",
                narration_text="Summary.",
                selected_background_id=_UUID_BG,
            )
            _setup_uc_for_asset_test(uc, decision=decision)

            uc.bg_gw.find_by_id = MagicMock(
                return_value=_fake_bg_record(),
            )

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            image_events = [e for e in parsed if e.get("type") == "imageUpdate"]

            assert len(image_events) == 1
            assert "scenario-assets/" in image_events[0]["path"]

    @pytest.mark.asyncio
    async def test_text_description_reuses_cached_image(self) -> None:
        """Text background that was previously generated → cache hit, no gen."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            desc = "A misty forest clearing"
            decision = _fake_decision(
                nodes=[
                    SceneNode(
                        type="narration",
                        text="Trees.",
                        background=desc,
                    ),
                ],
            )
            _setup_uc_for_asset_test(uc, decision=decision)

            # bg_gw.find_by_description returns a cached record
            uc.bg_gw.find_by_description = MagicMock(
                return_value=_fake_bg_record(
                    image_path="sessions/cached.png",
                    scenario_id=None,
                ),
            )
            uc.gemini.generate_image = AsyncMock(return_value=b"fake-png")

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            asset_events = [e for e in parsed if e.get("type") == "assetReady"]

            assert len(asset_events) == 1
            assert "generated-images/" in asset_events[0]["path"]
            # Gemini should NOT be called (cache hit)
            uc.gemini.generate_image.assert_not_called()


# ---------------------------------------------------------------------------
# Helpers for NPC emotion asset tests
# ---------------------------------------------------------------------------


def _fake_npc_record(
    *,
    name: str = "Guard",
    image_path: str | None = "npcs/guard_default.png",
    emotion_images: dict[str, str] | None = None,
    session_id: str = "00000000-0000-0000-0000-000000000001",
) -> MagicMock:
    """Create a fake Npcs row."""
    import uuid as _uuid

    rec = MagicMock()
    rec.id = _uuid.uuid4()
    rec.name = name
    rec.image_path = image_path
    rec.emotion_images = emotion_images
    rec.session_id = _uuid.UUID(session_id)
    rec.profile = {"description": "A sturdy guard"}
    return rec


def _setup_npc_emotion_test(
    uc: object,
    *,
    nodes: list[SceneNode],
    npc_records: list[MagicMock] | None = None,
) -> None:
    """Common setup for NPC emotion asset tests."""
    decision = _fake_decision(nodes=nodes)
    _setup_uc_for_asset_test(uc, decision=decision)
    # Background resolution stubs (no BG assets in these tests)
    uc.bg_gw.find_by_id = MagicMock(return_value=None)  # type: ignore[attr-defined]
    uc.bg_gw.find_by_description = MagicMock(  # type: ignore[attr-defined]
        return_value=None,
    )
    # NPC records for npc_images resolution
    records = npc_records or []
    uc.npc_gw.get_by_session = MagicMock(  # type: ignore[attr-defined]
        return_value=records,
    )
    if records:
        uc.npc_gw.get_by_scenario = MagicMock(  # type: ignore[attr-defined]
            return_value=records,
        )


def _npc_asset_events(parsed: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Filter assetReady events with NPC keys."""
    return [
        e
        for e in parsed
        if e.get("type") == "assetReady" and str(e.get("key", "")).startswith("npc:")
    ]


# ---------------------------------------------------------------------------
# NPC emotion asset pipeline tests
# ---------------------------------------------------------------------------


class TestResolveNpcEmotionAssets:
    """Tests for NPC emotion image resolution in node-based mode."""

    @pytest.mark.asyncio
    async def test_emotion_image_exists_yields_asset_ready(self) -> None:
        """NPC has emotion image in DB → assetReady with emotion key."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            nodes = [
                SceneNode(
                    type="dialogue",
                    text="Halt!",
                    speaker="Guard",
                    characters=[
                        CharacterDisplay(
                            npc_name="Guard",
                            expression="anger",
                        ),
                    ],
                ),
            ]
            guard = _fake_npc_record(
                name="Guard",
                image_path="npcs/guard_default.png",
                emotion_images={"anger": "npcs/guard_anger.png"},
            )
            _setup_npc_emotion_test(uc, nodes=nodes, npc_records=[guard])

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            npc_events = _npc_asset_events(parsed)

            # Expect emotion-specific + default
            keys = {e["key"] for e in npc_events}
            assert "npc:Guard:anger" in keys
            assert "npc:Guard:default" in keys
            anger_ev = next(e for e in npc_events if e["key"] == "npc:Guard:anger")
            assert "guard_anger.png" in anger_ev["path"]

    @pytest.mark.asyncio
    async def test_default_image_sent_for_npc(self) -> None:
        """NPC with default image → assetReady with 'npc:{name}:default'."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            nodes = [
                SceneNode(
                    type="dialogue",
                    text="Hello.",
                    speaker="Merchant",
                    characters=[
                        CharacterDisplay(
                            npc_name="Merchant",
                            expression=None,
                        ),
                    ],
                ),
            ]
            merchant = _fake_npc_record(
                name="Merchant",
                image_path="npcs/merchant_default.png",
                emotion_images=None,
            )
            _setup_npc_emotion_test(uc, nodes=nodes, npc_records=[merchant])

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            npc_events = _npc_asset_events(parsed)

            keys = {e["key"] for e in npc_events}
            assert "npc:Merchant:default" in keys

    @pytest.mark.asyncio
    async def test_missing_emotion_triggers_generation(self) -> None:
        """NPC has default but no emotion variant → generate → assetReady."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            nodes = [
                SceneNode(
                    type="dialogue",
                    text="Hmm?",
                    speaker="Guard",
                    characters=[
                        CharacterDisplay(
                            npc_name="Guard",
                            expression="surprise",
                        ),
                    ],
                ),
            ]
            guard = _fake_npc_record(
                name="Guard",
                image_path="npcs/guard_default.png",
                emotion_images={"anger": "npcs/guard_anger.png"},
            )
            _setup_npc_emotion_test(uc, nodes=nodes, npc_records=[guard])
            uc.gemini.generate_image = AsyncMock(return_value=b"fake-png")
            uc.storage_svc.download_image = MagicMock(return_value=b"base-image")
            uc.storage_svc.upload_image = MagicMock(
                return_value="sessions/guard_surprise.png",
            )
            uc.npc_gw.update_emotion_image = MagicMock()

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            npc_events = _npc_asset_events(parsed)

            keys = {e["key"] for e in npc_events}
            assert "npc:Guard:surprise" in keys
            assert "npc:Guard:default" in keys
            uc.gemini.generate_image.assert_called_once()
            kwargs = uc.gemini.generate_image.call_args.kwargs
            assert kwargs["source_image"] == b"base-image"
            assert kwargs["transparent_background"] is True
            assert kwargs["size"] == "1024x1536"
            uc.storage_svc.download_image.assert_called_once_with(
                "npcs/guard_default.png",
                "scenario-assets",
            )
            uc.npc_gw.update_emotion_image.assert_called_once()

    @pytest.mark.asyncio
    async def test_no_image_npc_generates_default(self) -> None:
        """NPC without any images → generate portrait → assetReady."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            nodes = [
                SceneNode(
                    type="dialogue",
                    text="Hey!",
                    speaker="Bandit",
                    characters=[
                        CharacterDisplay(
                            npc_name="Bandit",
                            expression="anger",
                        ),
                    ],
                ),
            ]
            # NPC exists in DB but has no images
            bandit = _fake_npc_record(
                name="Bandit",
                image_path=None,
                emotion_images=None,
            )
            _setup_npc_emotion_test(uc, nodes=nodes, npc_records=[bandit])
            uc.npc_gw.find_by_name_and_session = MagicMock(
                return_value=bandit,
            )
            uc.gemini.generate_image = AsyncMock(return_value=b"fake-png")
            uc.storage_svc.upload_image = MagicMock(
                return_value="sessions/bandit_anger.png",
            )
            uc.npc_gw.update_image_path = MagicMock()
            uc.npc_gw.update_emotion_image = MagicMock()

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            npc_events = _npc_asset_events(parsed)

            assert len(npc_events) >= 1
            keys = {e["key"] for e in npc_events}
            assert "npc:Bandit:anger" in keys
            uc.gemini.generate_image.assert_called()

    @pytest.mark.asyncio
    async def test_dedup_same_npc_expression(self) -> None:
        """Same (npc, expression) in multiple nodes → only 1 assetReady."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            nodes = [
                SceneNode(
                    type="dialogue",
                    text="Stop!",
                    speaker="Guard",
                    characters=[
                        CharacterDisplay(
                            npc_name="Guard",
                            expression="anger",
                        ),
                    ],
                ),
                SceneNode(
                    type="dialogue",
                    text="I said stop!",
                    speaker="Guard",
                    characters=[
                        CharacterDisplay(
                            npc_name="Guard",
                            expression="anger",
                        ),
                    ],
                ),
            ]
            guard = _fake_npc_record(
                name="Guard",
                image_path="npcs/guard_default.png",
                emotion_images={"anger": "npcs/guard_anger.png"},
            )
            _setup_npc_emotion_test(uc, nodes=nodes, npc_records=[guard])

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            npc_events = _npc_asset_events(parsed)

            # "npc:Guard:anger" should appear exactly once
            anger_events = [e for e in npc_events if e["key"] == "npc:Guard:anger"]
            assert len(anger_events) == 1

    @pytest.mark.asyncio
    async def test_no_characters_no_npc_events(self) -> None:
        """Nodes without characters → no NPC assetReady events."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()

            nodes = [
                SceneNode(
                    type="narration",
                    text="Empty room.",
                ),
            ]
            _setup_npc_emotion_test(uc, nodes=nodes)

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            npc_events = _npc_asset_events(parsed)

            assert npc_events == []


class TestAutoAdvanceUntilUserAction:
    """Tests for auto-advance multi-turn execution."""

    @pytest.mark.asyncio
    async def test_auto_advance_runs_until_choice_turn(self) -> None:
        """Auto mode should continue narrate turns until user-action turn."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()
            uc.prompt_cache_enabled = False
            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=1),
            )

            ctx1 = _CtxBuilder().build()
            ctx1.current_turn_number = 1
            ctx1.max_turns = 30
            ctx2 = _CtxBuilder().build()
            ctx2.current_turn_number = 2
            ctx2.max_turns = 30
            uc.context_svc.build_context = MagicMock(side_effect=[ctx1, ctx2])
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")

            decision1 = GmDecisionResponse(
                decision_type="narrate",
                narration_text="First auto turn.",
            )
            decision2 = GmDecisionResponse(
                decision_type="choice",
                narration_text="Pick one.",
            )
            uc.decision_svc.decide = AsyncMock(side_effect=[decision1, decision2])

            uc.mutation_svc.apply = MagicMock()
            uc.mutation_svc.apply_session_end = MagicMock()
            uc.session_gw.increment_turn = MagicMock(side_effect=[2, 3])
            uc.turn_gw.create = MagicMock()
            uc.context_gw.get_by_session = MagicMock(return_value=None)
            uc.npc_gw.get_by_session = MagicMock(return_value=[])
            uc.npc_gw.get_by_scenario = MagicMock(return_value=[])

            show_continue_values: list[bool] = []

            async def _stream_decision(
                _decision: GmDecisionResponse,
                *,
                npc_images: dict[str, tuple[str | None, dict[str, str]]] | None = None,
                show_continue_button: bool = True,
                show_continue_input_cta: bool = False,
            ) -> AsyncIterator[str]:
                _ = npc_images
                show_continue_values.append(show_continue_button)
                assert show_continue_input_cta is False
                yield 'data: {"type":"done"}\n\n'

            uc.bridge_svc.stream_decision = _stream_decision

            events = await _collect(
                uc.execute(
                    _make_request(
                        auto_advance_until_user_action=True,
                    ),
                    MagicMock(),
                ),
            )
            parsed = _parse_sse_events(events)
            done_events = [e for e in parsed if e.get("type") == "done"]

            assert len(done_events) == 2
            assert done_events[0]["will_continue"] is True
            assert done_events[0]["requires_user_action"] is False
            assert done_events[0]["is_ending"] is False
            assert done_events[1]["will_continue"] is False
            assert done_events[1]["requires_user_action"] is True
            assert done_events[1]["is_ending"] is False
            assert show_continue_values == [False, False]

            assert uc.decision_svc.decide.await_count == 2
            assert uc.turn_gw.create.call_count == 2
            assert uc.context_svc.build_prompt.call_count == 2

            second_prompt_call = uc.context_svc.build_prompt.call_args_list[1]
            assert second_prompt_call.args[1] == "do"
            assert second_prompt_call.args[2] == "continue"

    @pytest.mark.asyncio
    async def test_auto_advance_start_turn_adds_continuation_prompt(self) -> None:
        """Auto mode start turn should suppress immediate handoff choices."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()
            uc.prompt_cache_enabled = False
            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=1),
            )

            ctx = _CtxBuilder().build()
            ctx.current_turn_number = 1
            ctx.max_turns = 30
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")
            uc.decision_svc.decide = AsyncMock(
                return_value=GmDecisionResponse(
                    decision_type="narrate",
                    narration_text="Opening narration.",
                ),
            )

            _stub_common(uc, turn_return=2)

            async def _stream_decision(
                _decision: GmDecisionResponse,
                *,
                npc_images: dict[str, tuple[str | None, dict[str, str]]] | None = None,
                show_continue_button: bool = True,
                show_continue_input_cta: bool = False,
            ) -> AsyncIterator[str]:
                _ = npc_images
                _ = show_continue_button
                _ = show_continue_input_cta
                yield 'data: {"type":"done"}\n\n'

            uc.bridge_svc.stream_decision = _stream_decision

            await _collect(
                uc.execute(
                    _make_request(
                        input_type="start",
                        input_text="start",
                        auto_advance_until_user_action=True,
                        max_auto_turns=3,
                    ),
                    MagicMock(),
                ),
            )

            prompt_call = uc.context_svc.build_prompt.call_args_list[0]
            raw_sections = prompt_call.kwargs.get("extra_sections", [])
            full = "\n".join(str(s) for s in raw_sections if s)
            assert "AUTO-ADVANCE CONTINUATION MODE" in full
            assert "turn 1 of" in full

    @pytest.mark.asyncio
    async def test_auto_advance_stops_on_ending_turn(self) -> None:
        """Auto mode should stop when ending is reached."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()
            uc.prompt_cache_enabled = False
            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=1),
            )

            ctx = _CtxBuilder().build()
            ctx.current_turn_number = 1
            ctx.max_turns = 30
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")
            uc.decision_svc.decide = AsyncMock(
                return_value=GmDecisionResponse(
                    decision_type="narrate",
                    narration_text="Final ending turn.",
                    state_changes=StateChanges(
                        session_end=SessionEnd(
                            ending_type="victory",
                            ending_summary="Reached ending.",
                        ),
                    ),
                ),
            )

            _stub_common(uc, turn_return=2)

            async def _stream_decision(
                _decision: GmDecisionResponse,
                *,
                npc_images: dict[str, tuple[str | None, dict[str, str]]] | None = None,
                show_continue_button: bool = True,
                show_continue_input_cta: bool = False,
            ) -> AsyncIterator[str]:
                _ = npc_images
                assert show_continue_button is False
                assert show_continue_input_cta is False
                yield 'data: {"type":"done"}\n\n'

            uc.bridge_svc.stream_decision = _stream_decision

            events = await _collect(
                uc.execute(
                    _make_request(
                        auto_advance_until_user_action=True,
                    ),
                    MagicMock(),
                ),
            )
            parsed = _parse_sse_events(events)
            done_events = [e for e in parsed if e.get("type") == "done"]

            assert len(done_events) == 1
            assert done_events[0]["will_continue"] is False
            assert done_events[0]["requires_user_action"] is False
            assert done_events[0]["is_ending"] is True
            assert uc.decision_svc.decide.await_count == 1

    @pytest.mark.asyncio
    async def test_auto_advance_stops_at_max_auto_turns(self) -> None:
        """Auto mode should stop when max_auto_turns budget is reached."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()
            uc.prompt_cache_enabled = False
            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=1),
            )

            ctx1 = _CtxBuilder().build()
            ctx1.current_turn_number = 1
            ctx1.max_turns = 30
            ctx2 = _CtxBuilder().build()
            ctx2.current_turn_number = 2
            ctx2.max_turns = 30
            ctx3 = _CtxBuilder().build()
            ctx3.current_turn_number = 3
            ctx3.max_turns = 30
            uc.context_svc.build_context = MagicMock(side_effect=[ctx1, ctx2, ctx3])
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")
            uc.decision_svc.decide = AsyncMock(
                side_effect=[
                    GmDecisionResponse(
                        decision_type="narrate",
                        narration_text="Turn 1",
                    ),
                    GmDecisionResponse(
                        decision_type="narrate",
                        narration_text="Turn 2",
                    ),
                    GmDecisionResponse(
                        decision_type="narrate",
                        narration_text="Turn 3",
                    ),
                ],
            )

            _stub_common(uc, turn_return=2)
            uc.session_gw.increment_turn = MagicMock(side_effect=[2, 3, 4])

            async def _stream_decision(
                _decision: GmDecisionResponse,
                *,
                npc_images: dict[str, tuple[str | None, dict[str, str]]] | None = None,
                show_continue_button: bool = True,
                show_continue_input_cta: bool = False,
            ) -> AsyncIterator[str]:
                _ = npc_images
                if _decision.narration_text == "Turn 3":
                    assert show_continue_button is True
                    assert show_continue_input_cta is True
                else:
                    assert show_continue_button is False
                    assert show_continue_input_cta is False
                yield 'data: {"type":"done"}\n\n'

            uc.bridge_svc.stream_decision = _stream_decision

            events = await _collect(
                uc.execute(
                    _make_request(
                        auto_advance_until_user_action=True,
                        max_auto_turns=3,
                    ),
                    MagicMock(),
                ),
            )
            parsed = _parse_sse_events(events)
            done_events = [e for e in parsed if e.get("type") == "done"]

            assert len(done_events) == 3
            assert done_events[0]["will_continue"] is True
            assert done_events[1]["will_continue"] is True
            assert done_events[2]["will_continue"] is False
            assert done_events[2]["requires_user_action"] is True
            assert done_events[2]["is_ending"] is False
            assert done_events[2]["stop_reason"] == "auto_turn_limit"
            assert uc.decision_svc.decide.await_count == 3
            assert uc.context_svc.build_prompt.call_count == 3

            last_prompt_call = uc.context_svc.build_prompt.call_args_list[2]
            raw_sections = last_prompt_call.kwargs.get("extra_sections", [])
            full = "\n".join(str(s) for s in raw_sections if s)
            assert "AUTO-ADVANCE CONTINUATION MODE" in full
            assert "turn 3 of 3" in full
            assert "last" in full.lower()

    @pytest.mark.asyncio
    async def test_auto_advance_uses_prompt_cache_after_first_turn(self) -> None:
        """When enabled, prompt cache should switch later turns to prompt delta."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()
            uc.prompt_cache_enabled = True
            uc.interactions_enabled = False
            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=1),
            )

            ctx1 = _CtxBuilder().build()
            ctx1.current_turn_number = 1
            ctx1.max_turns = 30
            ctx1.scenario_title = "Scenario"
            ctx1.scenario_setting = "Setting"
            ctx1.system_prompt = ""
            ctx2 = _CtxBuilder().build()
            ctx2.current_turn_number = 2
            ctx2.max_turns = 30
            ctx2.scenario_title = "Scenario"
            ctx2.scenario_setting = "Setting"
            ctx2.system_prompt = ""
            uc.context_svc.build_context = MagicMock(side_effect=[ctx1, ctx2])
            uc.context_svc.build_prompt = MagicMock(return_value="prompt-full")
            uc.context_svc.build_prompt_delta = MagicMock(return_value="prompt-delta")

            uc.decision_svc.create_prompt_cache = AsyncMock(
                return_value="cachedContents/game-1",
            )
            uc.decision_svc.cleanup_runtime = AsyncMock()
            uc.decision_svc.decide = AsyncMock(
                side_effect=[
                    GmDecisionResponse(
                        decision_type="narrate",
                        narration_text="Turn 1",
                    ),
                    GmDecisionResponse(
                        decision_type="choice",
                        narration_text="Turn 2",
                    ),
                ],
            )

            _stub_common(uc, turn_return=2)
            uc.session_gw.increment_turn = MagicMock(side_effect=[2, 3])

            async def _stream_decision(
                _decision: GmDecisionResponse,
                *,
                npc_images: dict[str, tuple[str | None, dict[str, str]]] | None = None,
                show_continue_button: bool = True,
                show_continue_input_cta: bool = False,
            ) -> AsyncIterator[str]:
                _ = npc_images
                _ = show_continue_button
                _ = show_continue_input_cta
                yield 'data: {"type":"done"}\n\n'

            uc.bridge_svc.stream_decision = _stream_decision

            await _collect(
                uc.execute(
                    _make_request(
                        auto_advance_until_user_action=True,
                        max_auto_turns=2,
                    ),
                    MagicMock(),
                ),
            )

            uc.decision_svc.create_prompt_cache.assert_awaited_once()
            assert uc.context_svc.build_prompt.call_count == 1
            assert uc.context_svc.build_prompt_delta.call_count == 1

            second_runtime = uc.decision_svc.decide.call_args_list[1].kwargs["runtime"]
            assert second_runtime.cached_content_name == "cachedContents/game-1"
            uc.decision_svc.cleanup_runtime.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_user_action_turn_emits_done_after_bgm_events(self) -> None:
        """User-action turns should include BGM status before done."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()
            uc.prompt_cache_enabled = False
            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=1),
            )

            ctx = _CtxBuilder().build()
            ctx.current_turn_number = 1
            ctx.max_turns = 30
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")
            uc.decision_svc.decide = AsyncMock(
                return_value=GmDecisionResponse(
                    decision_type="choice",
                    narration_text="Choose your action",
                ),
            )

            _stub_common(uc, turn_return=2)

            async def _stream_decision(
                _decision: GmDecisionResponse,
                *,
                npc_images: dict[str, tuple[str | None, dict[str, str]]] | None = None,
                show_continue_button: bool = True,
                show_continue_input_cta: bool = False,
            ) -> AsyncIterator[str]:
                _ = npc_images
                _ = show_continue_button
                _ = show_continue_input_cta
                yield 'data: {"type":"done"}\n\n'

            async def _bgm_event(
                _db: object,
                _scenario_id: object,
                _decision: GmDecisionResponse,
            ) -> AsyncIterator[str]:
                yield 'data: {"type":"bgmGenerating","mood":"tense"}\n\n'

            async def _no_backgrounds(
                _db: object,
                _session_id: object,
                _decision: GmDecisionResponse,
            ) -> AsyncIterator[str]:
                return
                yield  # pragma: no cover

            uc.bridge_svc.stream_decision = _stream_decision
            uc._resolve_bgm = _bgm_event  # type: ignore[method-assign]
            uc._resolve_backgrounds = _no_backgrounds  # type: ignore[method-assign]

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            types = [str(e.get("type")) for e in parsed]

            assert "done" in types
            assert "bgmGenerating" in types
            assert types.index("bgmGenerating") < types.index("done")

    @pytest.mark.asyncio
    async def test_user_action_turn_emits_done_after_background_assets(
        self,
    ) -> None:
        """User-action turns should resolve backgrounds before done."""
        with (
            patch(
                "src.usecase.gm_turn_usecase.GeminiClient",
                autospec=True,
            ),
            patch(
                "src.usecase.gm_turn_usecase.StorageService",
                autospec=True,
            ),
        ):
            from src.usecase.gm_turn_usecase import GmTurnUseCase

            uc = GmTurnUseCase()
            uc.prompt_cache_enabled = False
            uc.session_gw.get_by_id = MagicMock(
                return_value=_fake_session(turn=1),
            )

            ctx = _CtxBuilder().build()
            ctx.current_turn_number = 1
            ctx.max_turns = 30
            uc.context_svc.build_context = MagicMock(return_value=ctx)
            uc.context_svc.build_prompt = MagicMock(return_value="prompt")
            uc.decision_svc.decide = AsyncMock(
                return_value=GmDecisionResponse(
                    decision_type="choice",
                    narration_text="Choose your action",
                ),
            )

            _stub_common(uc, turn_return=2)

            async def _stream_decision(
                _decision: GmDecisionResponse,
                *,
                npc_images: dict[str, tuple[str | None, dict[str, str]]] | None = None,
                show_continue_button: bool = True,
                show_continue_input_cta: bool = False,
            ) -> AsyncIterator[str]:
                _ = npc_images
                _ = show_continue_button
                _ = show_continue_input_cta
                yield 'data: {"type":"done"}\n\n'

            async def _no_bgm(
                _db: object,
                _scenario_id: object,
                _decision: GmDecisionResponse,
            ) -> AsyncIterator[str]:
                return
                yield  # pragma: no cover

            async def _bg_asset(
                _db: object,
                _session_id: object,
                _decision: GmDecisionResponse,
            ) -> AsyncIterator[str]:
                yield (
                    'data: {"type":"assetReady",'
                    '"key":"cave_01","path":"scenario-assets/bg.png"}\n\n'
                )

            uc.bridge_svc.stream_decision = _stream_decision
            uc._resolve_bgm = _no_bgm  # type: ignore[method-assign]
            uc._resolve_backgrounds = _bg_asset  # type: ignore[method-assign]

            events = await _collect(uc.execute(_make_request(), MagicMock()))
            parsed = _parse_sse_events(events)
            types = [str(e.get("type")) for e in parsed]

            assert "done" in types
            assert "assetReady" in types
            assert types.index("assetReady") < types.index("done")


class TestAutoAdvanceAddition:
    """Unit tests for _build_auto_advance_addition prompt generation."""

    def _import_uc(self) -> type:
        from src.usecase.gm_turn_usecase import GmTurnUseCase

        return GmTurnUseCase

    def test_disabled_returns_empty(self) -> None:
        with (
            patch("src.usecase.gm_turn_usecase.GeminiClient", autospec=True),
            patch("src.usecase.gm_turn_usecase.StorageService", autospec=True),
        ):
            result = self._import_uc()._build_auto_advance_addition(
                auto_advance_enabled=False,
                should_handoff_with_cta=False,
                input_type="do",
                current_turn=1,
                total_turns=5,
            )
            assert result == ""

    def test_last_turn_is_not_empty(self) -> None:
        """Last turn should return guidance, not empty string."""
        with (
            patch("src.usecase.gm_turn_usecase.GeminiClient", autospec=True),
            patch("src.usecase.gm_turn_usecase.StorageService", autospec=True),
        ):
            result = self._import_uc()._build_auto_advance_addition(
                auto_advance_enabled=True,
                should_handoff_with_cta=True,
                input_type="do",
                current_turn=5,
                total_turns=5,
            )
            assert result != ""
            assert "AUTO-ADVANCE CONTINUATION MODE" in result

    def test_includes_turn_position(self) -> None:
        with (
            patch("src.usecase.gm_turn_usecase.GeminiClient", autospec=True),
            patch("src.usecase.gm_turn_usecase.StorageService", autospec=True),
        ):
            result = self._import_uc()._build_auto_advance_addition(
                auto_advance_enabled=True,
                should_handoff_with_cta=False,
                input_type="do",
                current_turn=2,
                total_turns=5,
            )
            assert "AUTO-ADVANCE CONTINUATION MODE" in result
            assert "turn 2 of 5" in result

    def test_prioritizes_immersion(self) -> None:
        with (
            patch("src.usecase.gm_turn_usecase.GeminiClient", autospec=True),
            patch("src.usecase.gm_turn_usecase.StorageService", autospec=True),
        ):
            result = self._import_uc()._build_auto_advance_addition(
                auto_advance_enabled=True,
                should_handoff_with_cta=False,
                input_type="do",
                current_turn=2,
                total_turns=5,
            )
            assert "immersion" in result.lower()
            # Should not contain fixed turn-count schedules
            assert "3-4 turns" not in result
            assert "1-2 turns" not in result

    def test_start_turn_has_opening_guidance(self) -> None:
        with (
            patch("src.usecase.gm_turn_usecase.GeminiClient", autospec=True),
            patch("src.usecase.gm_turn_usecase.StorageService", autospec=True),
        ):
            result = self._import_uc()._build_auto_advance_addition(
                auto_advance_enabled=True,
                should_handoff_with_cta=False,
                input_type="start",
                current_turn=1,
                total_turns=5,
            )
            assert "opening" in result.lower() or "first turn" in result.lower()
            assert "narrat" in result.lower()

    def test_last_turn_prompts_choice(self) -> None:
        """Last turn should guide GM to present a choice, not be empty."""
        with (
            patch("src.usecase.gm_turn_usecase.GeminiClient", autospec=True),
            patch("src.usecase.gm_turn_usecase.StorageService", autospec=True),
        ):
            result = self._import_uc()._build_auto_advance_addition(
                auto_advance_enabled=True,
                should_handoff_with_cta=True,
                input_type="do",
                current_turn=5,
                total_turns=5,
            )
            # Must NOT be empty — should guide GM to present choice
            assert result != ""
            assert "turn 5 of 5" in result
            assert "last" in result.lower()
            assert "choice" in result.lower()
