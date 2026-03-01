"""GM turn processing pipeline.

Orchestrates the full turn lifecycle: validate session, build context,
get GM decision via Gemini, apply state mutations, evaluate win/fail
conditions, persist the turn record, and stream the result as SSE events.
"""

from __future__ import annotations

import asyncio
import json
import os
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import TYPE_CHECKING, Any

from sqlmodel import Session as SQLModelSession

from domain.entity.gm_types import GmTurnRequest, SessionEnd, StateChanges
from domain.entity.models import Npcs, SceneBackgrounds, Turns
from domain.service.action_resolution_service import ActionResolutionService
from domain.service.bgm_service import BgmService
from domain.service.condition_evaluation_service import (
    ConditionEvaluationResult,
    ConditionEvaluationService,
)
from domain.service.context_service import ContextService
from domain.service.genui_bridge_service import GenuiBridgeService, NpcImageMap
from domain.service.gm_decision_service import GmDecisionRuntime, GmDecisionService
from domain.service.npc_clone_service import NpcCloneService
from domain.service.state_mutation_service import StateMutationService
from domain.service.storage_constants import SCENARIO_ASSETS_BUCKET
from domain.service.turn_limit_service import TurnLimitService
from gateway.context_summary_gateway import ContextSummaryGateway
from gateway.npc_gateway import NpcGateway
from gateway.scene_background_gateway import SceneBackgroundGateway
from gateway.session_gateway import SessionGateway
from gateway.turn_gateway import TurnGateway
from infra.gemini_client import GeminiClient
from infra.storage_service import StorageService
from util.logging import get_logger

if TYPE_CHECKING:
    from collections.abc import AsyncIterator

    from sqlmodel import Session

    from domain.entity.gm_types import (
        GameContext,
        GmDecisionResponse,
    )

logger = get_logger(__name__)
GENERATED_IMAGES_BUCKET = "generated-images"

try:
    from infra.db_client import engine as _bgm_engine
except ValueError:
    _bgm_engine = None


@dataclass(frozen=True)
class _DoneMeta:
    turn_number: int
    requires_user_action: bool
    is_ending: bool
    will_continue: bool
    stop_reason: str


@dataclass(frozen=True)
class _TurnStreamParams:
    db: Session
    session_id: uuid.UUID
    scenario_id: object
    decision: GmDecisionResponse
    npc_images: NpcImageMap
    done_meta: _DoneMeta
    show_continue_button: bool
    show_continue_input_cta: bool


class GmTurnUseCase:
    """Processes a single player turn through the GM pipeline."""

    def __init__(self) -> None:
        self.gemini = GeminiClient()
        self.session_gw = SessionGateway()
        self.turn_gw = TurnGateway()
        self.context_gw = ContextSummaryGateway()
        self.context_svc = ContextService()
        self.decision_svc = GmDecisionService(self.gemini)
        self.mutation_svc = StateMutationService()
        self.bridge_svc = GenuiBridgeService()
        self.bgm_svc = BgmService()
        self.storage_svc: StorageService | None = None
        self.bg_gw = SceneBackgroundGateway()
        self.npc_gw = NpcGateway()
        self.clone_svc = NpcCloneService()
        self.turn_limit_svc = TurnLimitService()
        self.condition_svc = ConditionEvaluationService()
        self.resolution_svc = ActionResolutionService()
        self.interactions_enabled = _env_bool(
            "GEMINI_INTERACTIONS_ENABLED",
            default=False,
        )
        self.prompt_cache_enabled = _env_bool(
            "GEMINI_PROMPT_CACHE_ENABLED",
            default=True,
        )
        self.prompt_cache_ttl_seconds = _env_int(
            "GEMINI_PROMPT_CACHE_TTL_SECONDS",
            default=3600,
        )

    @property
    def _storage_svc(self) -> StorageService:
        if self.storage_svc is None:
            self.storage_svc = StorageService()
        return self.storage_svc

    async def execute(
        self,
        request: GmTurnRequest,
        db: Session,
    ) -> AsyncIterator[str]:
        """Run the full turn pipeline and yield SSE events."""
        session_id = uuid.UUID(request.session_id)
        game_session = self.session_gw.get_by_id(db, session_id)

        if not game_session or game_session.status != "active":
            yield _error_event("Session not active")
            return

        auto_advance_enabled = request.auto_advance_until_user_action
        auto_turn_budget = request.max_auto_turns if auto_advance_enabled else 1
        generated_turn_count = 0
        current_input_type = request.input_type
        current_input_text = request.input_text
        is_first_turn = True
        decision_runtime = self._build_decision_runtime(
            auto_advance_enabled=auto_advance_enabled,
            auto_turn_budget=auto_turn_budget,
        )

        try:
            while True:
                turn_request = GmTurnRequest(
                    session_id=request.session_id,
                    input_type=current_input_type,
                    input_text=current_input_text,
                    auto_advance_until_user_action=auto_advance_enabled,
                    max_auto_turns=auto_turn_budget,
                )

                if is_first_turn:
                    self._maybe_clone_npcs(turn_request, db, session_id, game_session)
                    is_first_turn = False

                # Build context and resolve decision (with turn-limit checks)
                context = self.context_svc.build_context(db, session_id)
                await self._maybe_create_prompt_cache(
                    context=context,
                    runtime=decision_runtime,
                    session_id=session_id,
                    generated_turn_count=generated_turn_count,
                    auto_advance_enabled=auto_advance_enabled,
                    auto_turn_budget=auto_turn_budget,
                )
                should_handoff_with_cta = auto_advance_enabled and (
                    generated_turn_count + 1 >= auto_turn_budget
                )
                auto_section = self._build_auto_advance_addition(
                    auto_advance_enabled=auto_advance_enabled,
                    should_handoff_with_cta=should_handoff_with_cta,
                    input_type=turn_request.input_type,
                    current_turn=generated_turn_count + 1,
                    total_turns=auto_turn_budget,
                )
                decision = await self._resolve_decision(
                    context,
                    turn_request,
                    runtime=decision_runtime,
                    auto_advance_section=auto_section,
                )

                # Apply state mutations and evaluate conditions
                is_ending = self._apply_and_evaluate(
                    db,
                    session_id,
                    context,
                    decision,
                )

                # Persist turn
                turn_number = self._persist_turn(
                    turn_request, decision, db, game_session
                )
                generated_turn_count += 1

                await self._maybe_compress_context(
                    db,
                    session_id,
                    context.current_turn_number,
                )

                npc_images = self._resolve_npc_images(
                    db,
                    session_id,
                    game_session.scenario_id,
                    decision,
                )

                auto_limit_reached = (
                    auto_advance_enabled and generated_turn_count >= auto_turn_budget
                )
                narrate_requires_continue = (not auto_advance_enabled) or (
                    auto_advance_enabled and auto_limit_reached
                )
                show_continue_input_cta = (
                    auto_limit_reached and decision.decision_type == "narrate"
                )
                requires_user_action = _requires_user_action(
                    decision,
                    narrate_requires_continue=narrate_requires_continue,
                )
                will_continue = (
                    auto_advance_enabled
                    and not auto_limit_reached
                    and not requires_user_action
                    and not is_ending
                )
                stop_reason = _build_stop_reason(
                    is_ending=is_ending,
                    requires_user_action=requires_user_action,
                    auto_limit_reached=auto_limit_reached,
                    will_continue=will_continue,
                )

                stream_params = _TurnStreamParams(
                    db=db,
                    session_id=session_id,
                    scenario_id=game_session.scenario_id,
                    decision=decision,
                    npc_images=npc_images,
                    done_meta=_DoneMeta(
                        turn_number=turn_number,
                        requires_user_action=requires_user_action,
                        is_ending=is_ending,
                        will_continue=will_continue,
                        stop_reason=stop_reason,
                    ),
                    show_continue_button=narrate_requires_continue,
                    show_continue_input_cta=show_continue_input_cta,
                )
                async for event in self._stream_turn_events(stream_params):
                    yield event

                if not will_continue:
                    break

                current_input_type = "do"
                current_input_text = "continue"
        finally:
            logger.info(
                "Turn generation finished",
                session_id=str(session_id),
                total_turns=generated_turn_count,
            )
            await self.decision_svc.cleanup_runtime(decision_runtime)

    def _build_decision_runtime(
        self,
        *,
        auto_advance_enabled: bool,
        auto_turn_budget: int,
    ) -> GmDecisionRuntime:
        """Build per-request runtime knobs for decision acceleration."""
        return GmDecisionRuntime(
            use_interactions=(
                self.interactions_enabled
                and auto_advance_enabled
                and auto_turn_budget > 1
            ),
        )

    async def _maybe_create_prompt_cache(  # noqa: PLR0913
        self,
        *,
        context: GameContext,
        runtime: GmDecisionRuntime,
        session_id: uuid.UUID,
        generated_turn_count: int,
        auto_advance_enabled: bool,
        auto_turn_budget: int,
    ) -> None:
        """Create one explicit prompt cache for stable prompt prefix."""
        if runtime.prompt_cache_attempted:
            return
        if not self.prompt_cache_enabled:
            return
        if not auto_advance_enabled or auto_turn_budget <= 1:
            return
        if generated_turn_count == 0:
            return

        runtime.prompt_cache_attempted = True
        seed = self.context_svc.build_prompt_cache_seed(context)
        runtime.cached_content_name = await self.decision_svc.create_prompt_cache(
            contents=seed,
            ttl_seconds=self.prompt_cache_ttl_seconds,
            display_name=f"gm-turn-{session_id}",
        )

    def _maybe_clone_npcs(
        self,
        request: GmTurnRequest,
        db: Session,
        session_id: uuid.UUID,
        game_session: object,
    ) -> None:
        """Clone scenario NPCs into the session on the first turn."""
        if request.input_type != "start":
            return
        sid = game_session.scenario_id  # type: ignore[attr-defined]
        state = game_session.current_state  # type: ignore[attr-defined]
        self.clone_svc.clone_npcs_for_session(db, sid, session_id, state)

    async def _maybe_compress_context(
        self,
        db: Session,
        session_id: uuid.UUID,
        current_turn_number: int,
    ) -> None:
        """Run context compression when threshold is met."""
        ctx_rec = self.context_gw.get_by_session(db, session_id)
        last_updated = ctx_rec.last_updated_turn if ctx_rec else 0
        if not self.context_svc.should_compress(current_turn_number, last_updated):
            return
        try:
            await self.context_svc.compress(
                db,
                session_id,
                self.gemini,
                current_turn_number,
            )
        except Exception:
            logger.warning(
                "Context compression failed, will retry next turn",
                session_id=str(session_id),
            )

    async def _stream_turn_events(
        self,
        params: _TurnStreamParams,
    ) -> AsyncIterator[str]:
        """Yield all turn-related SSE events in canonical order."""
        done_event_seen = False
        done_emitted = False
        async for event in self.bridge_svc.stream_decision(
            params.decision,
            npc_images=params.npc_images,
            show_continue_button=params.show_continue_button,
            show_continue_input_cta=params.show_continue_input_cta,
        ):
            if _is_done_event(event):
                done_event_seen = True
                continue
            yield event

        async for event in self._resolve_bgm(
            params.db,
            params.scenario_id,
            params.decision,
        ):
            yield event

        # Resolve background images before done, so the frontend has all
        # scene assets ready when the user regains control.
        async for event in self._resolve_backgrounds(
            params.db,
            params.session_id,
            params.decision,
        ):
            yield event

        # Unlock user interaction after BGM and backgrounds are resolved.
        # Only NPC emotion variants may arrive after done -- they have
        # fallback images on the frontend side.
        if (
            done_event_seen
            and params.done_meta.requires_user_action
            and not done_emitted
        ):
            done_emitted = True
            yield _done_event(
                turn_number=params.done_meta.turn_number,
                requires_user_action=params.done_meta.requires_user_action,
                is_ending=params.done_meta.is_ending,
                will_continue=params.done_meta.will_continue,
                stop_reason=params.done_meta.stop_reason,
            )

        if params.decision.nodes:
            async for event in self._resolve_npc_emotion_assets(
                params.db,
                params.session_id,
                params.decision.nodes,
                params.npc_images,
            ):
                yield event

        if done_event_seen and not done_emitted:
            yield _done_event(
                turn_number=params.done_meta.turn_number,
                requires_user_action=params.done_meta.requires_user_action,
                is_ending=params.done_meta.is_ending,
                will_continue=params.done_meta.will_continue,
                stop_reason=params.done_meta.stop_reason,
            )

    async def _resolve_decision(
        self,
        context: GameContext,
        request: GmTurnRequest,
        *,
        runtime: GmDecisionRuntime | None = None,
        auto_advance_section: str = "",
    ) -> GmDecisionResponse:
        """Check turn limits and return the appropriate decision."""
        cur = context.current_turn_number
        mx = context.max_turns
        is_hard_limit = self.turn_limit_svc.is_hard_limit_reached(cur, mx)

        luck = self.resolution_svc.generate_luck_factor()
        resolution_ctx = self.resolution_svc.build_resolution_context(
            player_stats=dict(context.player.stats),
            luck_roll=luck,
        )
        hard_limit_section = (
            self.turn_limit_svc.build_hard_limit_prompt_addition(mx)
            if is_hard_limit
            else ""
        )
        extra_sections = [
            self._build_soft_addition(context),
            self._build_condition_progress(context),
            resolution_ctx,
            auto_advance_section,
            hard_limit_section,
        ]
        if runtime and runtime.cached_content_name:
            prompt = self.context_svc.build_prompt_delta(
                context,
                request.input_type,
                request.input_text,
                extra_sections=extra_sections,
            )
        else:
            prompt = self.context_svc.build_prompt(
                context,
                request.input_type,
                request.input_text,
                extra_sections=extra_sections,
            )
        decision = await self.decision_svc.decide(prompt, runtime=runtime)

        # Fallback: force session_end if GM omitted it at hard limit
        if is_hard_limit and not _has_session_end(decision.state_changes):
            logger.warning(
                "GM omitted session_end at hard limit; forcing bad_end",
                current_turn=cur,
                max_turns=mx,
            )
            if decision.state_changes is None:
                decision.state_changes = StateChanges(
                    session_end=SessionEnd(
                        ending_type="bad_end",
                        ending_summary=(f"Turn limit ({mx}) reached."),
                    ),
                )
            else:
                decision.state_changes.session_end = SessionEnd(
                    ending_type="bad_end",
                    ending_summary=(f"Turn limit ({mx}) reached."),
                )
        return decision

    @staticmethod
    def _build_auto_advance_addition(
        *,
        auto_advance_enabled: bool,
        should_handoff_with_cta: bool,
        input_type: str,
        current_turn: int = 1,
        total_turns: int = 1,
    ) -> str:
        """Prompt addition informing GM of auto-advance streaming context."""
        if not auto_advance_enabled:
            return ""

        is_last = should_handoff_with_cta or current_turn >= total_turns
        turn_note = (
            "\n- This is the opening turn. Use narrate to establish the scene."
            if input_type == "start"
            else ""
        )
        last_turn_note = (
            "\n- This is the LAST auto-advance turn. Present a choice to"
            " give the player agency, unless the scene truly calls for"
            " pure narration (in which case the player can type freely)."
            if is_last
            else ""
        )
        return (
            f"AUTO-ADVANCE CONTINUATION MODE (turn {current_turn} of"
            f" {total_turns}):\n"
            "- narrate → next turn is generated immediately.\n"
            "- choice  → auto-advance pauses, player decides.\n"
            "Prioritize immersion: present choices when the story\n"
            "naturally demands player agency, not on a fixed schedule.\n"
            '- Avoid decision_type="clarify" and "repair" unless truly needed.'
            f"{turn_note}{last_turn_note}"
        )

    def _build_soft_addition(self, context: GameContext) -> str:
        """Return soft-limit prompt addition or empty string."""
        cur = context.current_turn_number
        mx = context.max_turns
        if not self.turn_limit_svc.is_soft_limit_active(cur, mx):
            return ""
        remaining = self.turn_limit_svc.remaining_turns(cur, mx)
        return str(
            self.turn_limit_svc.build_soft_limit_prompt_addition(
                remaining,
            ),
        )

    def _build_condition_progress(self, context: GameContext) -> str:
        """Build condition progress prompt text."""
        flags = dict(context.current_state.get("flags", {}))
        result = self.condition_svc.evaluate(
            win_conditions=context.win_conditions,
            fail_conditions=context.fail_conditions,
            current_flags=flags,
            player_stats=dict(context.player.stats),
            current_turn=context.current_turn_number,
        )
        return str(self.condition_svc.build_progress_prompt(result))

    def _apply_and_evaluate(
        self,
        db: Session,
        session_id: uuid.UUID,
        context: GameContext,
        decision: GmDecisionResponse,
    ) -> bool:
        """Apply mutations, log session end, and evaluate conditions."""
        if decision.state_changes:
            self.mutation_svc.apply(db, session_id, decision.state_changes)
        llm_ended = _has_session_end(decision.state_changes)
        if llm_ended:
            _log_session_end(session_id, decision.state_changes)
            return True
        return self._evaluate_and_apply(
            db,
            session_id,
            context,
            decision,
        )

    def _evaluate_and_apply(
        self,
        db: Session,
        session_id: uuid.UUID,
        context: GameContext,
        decision: GmDecisionResponse,
    ) -> bool:
        """Evaluate conditions and apply session end if triggered."""
        flags = _compute_latest_flags(context, decision.state_changes)
        stats = _compute_latest_stats(context, decision.state_changes)
        result = self.condition_svc.evaluate(
            win_conditions=context.win_conditions,
            fail_conditions=context.fail_conditions,
            current_flags=flags,
            player_stats=stats,
            current_turn=context.current_turn_number,
        )
        return self._apply_condition_end(db, session_id, result)

    def _apply_condition_end(
        self,
        db: Session,
        session_id: uuid.UUID,
        result: ConditionEvaluationResult,
    ) -> bool:
        """Apply session end based on condition evaluation result."""
        if result.triggered_fail:
            desc = str(result.triggered_fail.get("description", ""))
            logger.info(
                "Condition triggered session end",
                session_id=str(session_id),
                trigger="fail",
                description=desc,
            )
            self.mutation_svc.apply_session_end(
                db,
                session_id,
                SessionEnd(
                    ending_type="bad_end",
                    ending_summary=desc,
                ),
            )
            return True
        if result.triggered_win:
            desc = str(result.triggered_win.get("description", ""))
            logger.info(
                "Condition triggered session end",
                session_id=str(session_id),
                trigger="win",
                description=desc,
            )
            self.mutation_svc.apply_session_end(
                db,
                session_id,
                SessionEnd(
                    ending_type="victory",
                    ending_summary=desc,
                ),
            )
            return True
        return False

    async def _resolve_bgm(
        self,
        db: Session,
        scenario_id: object,
        decision: GmDecisionResponse,
    ) -> AsyncIterator[str]:
        """Resolve BGM cache hit/miss and emit BGM SSE events."""
        if not isinstance(scenario_id, uuid.UUID):
            return

        mood = (decision.bgm_mood or "").strip().lower()
        prompt = (decision.bgm_music_prompt or "").strip()
        if not mood:
            return

        try:
            cached_path = self.bgm_svc.get_cached_bgm_path(db, scenario_id, mood)
        except Exception as exc:
            logger.warning(
                "BGM cache lookup failed; skipping BGM for this turn",
                scenario_id=str(scenario_id),
                mood=mood,
                error=str(exc),
            )
            return
        if cached_path:
            logger.info(
                "BGM cache hit",
                scenario_id=str(scenario_id),
                mood=mood,
                path=cached_path,
            )
            yield _bgm_update_event(f"generated-bgm/{cached_path}", mood)
            return

        # Cache miss: notify frontend immediately to show loading state.
        logger.info(
            "BGM cache miss; start generating",
            scenario_id=str(scenario_id),
            mood=mood,
        )
        yield _bgm_generating_event(mood)

        if not prompt:
            prompt = self._fallback_bgm_prompt(decision, mood)
            logger.warning(
                "BGM prompt missing from LLM; using fallback prompt",
                scenario_id=str(scenario_id),
                mood=mood,
                prompt=prompt,
            )

        try:
            await self.bgm_svc.generate_and_cache(
                db=db,
                scenario_id=scenario_id,
                mood=mood,
                music_prompt=prompt,
            )
        except Exception as exc:
            logger.warning(
                "BGM generation failed; skipping BGM for this turn",
                scenario_id=str(scenario_id),
                mood=mood,
                error=str(exc),
            )
            return
        generated_path = self.bgm_svc.get_cached_bgm_path(db, scenario_id, mood)
        if generated_path:
            logger.info(
                "BGM generated and cached",
                scenario_id=str(scenario_id),
                mood=mood,
                path=generated_path,
            )
            yield _bgm_update_event(f"generated-bgm/{generated_path}", mood)

    @staticmethod
    def _fallback_bgm_prompt(
        decision: GmDecisionResponse,
        mood: str,
    ) -> str:
        """Create a safe fallback prompt when LLM omits bgm_music_prompt."""
        scene = (decision.scene_description or "TRPG scene").strip()
        return (
            f"{scene}, background music mood={mood}, "
            "instrumental only, no vocals, no lyrics, "
            "no singing, seamless loop, loopable"
        )

    @staticmethod
    def _new_bgm_session() -> Session:
        if _bgm_engine is None:
            msg = "DATABASE_URL environment variable is not set"
            raise RuntimeError(msg)
        return SQLModelSession(_bgm_engine)

    async def _resolve_backgrounds(
        self,
        db: Session,
        session_id: uuid.UUID,
        decision: GmDecisionResponse,
    ) -> AsyncIterator[str]:
        """Route to node-based or legacy background resolution."""
        if decision.nodes:
            async for event in self._resolve_node_assets(
                db,
                session_id,
                decision.nodes,
            ):
                yield event
        else:
            image_ref = self._resolve_background_image(db, decision)
            if image_ref:
                yield _image_event(image_ref)
            elif decision.scene_description:
                gen_ref = await self._generate_and_upload_image(
                    db,
                    session_id,
                    decision.scene_description,
                )
                if gen_ref:
                    yield _image_event(gen_ref)

    def _resolve_background_image(
        self,
        db: Session,
        decision: GmDecisionResponse,
    ) -> str | None:
        """Look up background by LLM-selected ID."""
        if not decision.selected_background_id:
            return None

        try:
            bg_id = uuid.UUID(decision.selected_background_id)
        except ValueError:
            logger.warning(
                "Invalid background ID from LLM",
                selected_id=decision.selected_background_id,
            )
            return None

        bg = self.bg_gw.find_by_id(db, bg_id)
        if not bg or not bg.image_path:
            logger.warning(
                "Background not found or missing image_path",
                selected_id=decision.selected_background_id,
            )
            return None

        bucket = SCENARIO_ASSETS_BUCKET if bg.scenario_id else GENERATED_IMAGES_BUCKET
        logger.info(
            "Using LLM-selected background",
            bg_id=str(bg_id),
            location=bg.location_name,
            path=bg.image_path,
        )
        return f"{bucket}/{bg.image_path}"

    def _resolve_npc_images(
        self,
        db: Session,
        session_id: uuid.UUID,
        scenario_id: object,
        decision: GmDecisionResponse,
    ) -> NpcImageMap:
        """Build NPC name -> (default_path, emotion_map) and log each NPC."""
        npc_images = _build_npc_image_entries(
            self.npc_gw.get_by_session(db, session_id),
        )
        if not npc_images:
            npc_images = _build_npc_image_entries(
                self.npc_gw.get_by_scenario(db, scenario_id),
            )

        seen: set[str] = set()
        for dialogue in decision.npc_dialogues or []:
            seen.add(dialogue.npc_name)
            entry = npc_images.get(dialogue.npc_name)
            path = entry[0] if entry else None
            logger.info(
                "Using LLM-selected NPC",
                npc_name=dialogue.npc_name,
                source="dialogue",
                image_path=path,
                resolved=path is not None,
            )
        for intent in decision.npc_intents or []:
            if intent.npc_name not in seen:
                entry = npc_images.get(intent.npc_name)
                path = entry[0] if entry else None
                logger.info(
                    "Using LLM-selected NPC",
                    npc_name=intent.npc_name,
                    source="intent",
                    image_path=path,
                    resolved=path is not None,
                )
        return npc_images

    def _persist_turn(
        self,
        request: GmTurnRequest,
        decision: GmDecisionResponse,
        db: Session,
        game_session: object,
    ) -> int:
        """Increment turn counter and save the turn record."""
        sid = game_session.id  # type: ignore[attr-defined]
        new_turn_number: int = self.session_gw.increment_turn(db, sid)
        turn = Turns(
            id=uuid.uuid4(),
            session_id=sid,
            turn_number=new_turn_number,
            input_type=request.input_type,
            input_text=request.input_text,
            gm_decision_type=decision.decision_type,
            output=decision.model_dump(),
            created_at=datetime.now(UTC),
        )
        self.turn_gw.create(db, turn)
        logger.info(
            "Turn generated",
            session_id=str(sid),
            turn_number=new_turn_number,
            decision_type=decision.decision_type,
        )
        return new_turn_number

    async def _resolve_node_assets(
        self,
        db: Session,
        session_id: uuid.UUID,
        nodes: list[Any],
    ) -> AsyncIterator[str]:
        """Resolve background assets for scene nodes."""
        backgrounds = _collect_required_assets(nodes)
        if not backgrounds:
            return

        # Phase 1: DB lookups (UUID by id, text by description)
        unresolved: list[str] = []
        for bg_key in backgrounds:
            # Try UUID lookup first
            try:
                bg_id = uuid.UUID(bg_key)
                bg = self.bg_gw.find_by_id(db, bg_id)
                if bg and bg.image_path:
                    bucket = (
                        SCENARIO_ASSETS_BUCKET
                        if bg.scenario_id
                        else GENERATED_IMAGES_BUCKET
                    )
                    yield _asset_ready_event(
                        bg_key,
                        f"{bucket}/{bg.image_path}",
                    )
                    continue
            except ValueError:
                pass
            # Try description-based cache lookup
            cached = self.bg_gw.find_by_description(
                db,
                session_id,
                bg_key,
            )
            if cached and cached.image_path:
                yield _asset_ready_event(
                    bg_key,
                    f"{GENERATED_IMAGES_BUCKET}/{cached.image_path}",
                )
                continue
            unresolved.append(bg_key)

        if not unresolved:
            return

        # Phase 2: Parallel image generation (Gemini API)
        tasks = [
            self.gemini.generate_image(f"Fantasy RPG scene: {desc}")
            for desc in unresolved
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Sequential: upload + DB cache + yield events
        for desc, result in zip(unresolved, results, strict=True):
            if isinstance(result, BaseException) or result is None:
                logger.warning("Node asset generation failed", key=desc)
                continue
            try:
                storage_path = await asyncio.to_thread(
                    self._storage_svc.upload_image,
                    str(session_id),
                    result,
                )
                self.bg_gw.create(
                    db,
                    SceneBackgrounds(
                        id=uuid.uuid4(),
                        session_id=session_id,
                        location_name=desc[:100],
                        image_path=storage_path,
                        description=desc,
                        created_at=datetime.now(UTC),
                    ),
                )
                yield _asset_ready_event(
                    desc,
                    f"{GENERATED_IMAGES_BUCKET}/{storage_path}",
                )
            except Exception:
                logger.warning("Node asset upload failed", key=desc)

    async def _resolve_npc_emotion_assets(
        self,
        db: Session,
        session_id: uuid.UUID,
        nodes: list[Any],
        npc_images: NpcImageMap,
    ) -> AsyncIterator[str]:
        """Resolve NPC emotion images for scene nodes."""
        chars = _collect_npc_character_assets(nodes)
        if not chars:
            return

        sent: set[str] = set()

        for npc_name, expression in chars:
            default_path, emotion_map = npc_images.get(
                npc_name,
                (None, {}),
            )

            # Send default image once per NPC
            default_key = f"npc:{npc_name}:default"
            if default_path and default_key not in sent:
                sent.add(default_key)
                yield _asset_ready_event(
                    default_key,
                    _to_bucketed_npc_path(default_path),
                )

            # Resolve emotion-specific image
            asset_key = f"npc:{npc_name}:{expression or 'default'}"
            if asset_key in sent:
                continue
            sent.add(asset_key)

            if expression and expression in emotion_map:
                yield _asset_ready_event(
                    asset_key,
                    _to_bucketed_npc_path(emotion_map[expression]),
                )
                continue

            if not expression:
                continue

            # Generate missing emotion image
            event = await self._generate_npc_emotion(
                db,
                session_id,
                npc_name,
                expression,
                npc_images,
            )
            if event:
                yield _asset_ready_event(
                    asset_key,
                    event,
                )

    async def _generate_npc_emotion(
        self,
        db: Session,
        session_id: uuid.UUID,
        npc_name: str,
        expression: str,
        npc_images: NpcImageMap,
    ) -> str | None:
        """Generate, upload, and cache an NPC emotion image.

        Returns the storage path string on success, None on failure.
        """
        npc_rec = self.npc_gw.find_by_name_and_session(
            db,
            session_id,
            npc_name,
        )
        profile_desc = ""
        if npc_rec and npc_rec.profile:
            profile_desc = str(npc_rec.profile.get("description", ""))

        default_path = npc_images.get(npc_name, (None, {}))[0]
        source_image = await self._load_npc_base_image(default_path)

        prompt = (
            "Full-body standing fantasy RPG character portrait, single character, "
            "portrait orientation, 2:3 vertical composition, transparent background, "
            "no text, no frame, no watermark. "
            f"Character: {npc_name}. Expression: {expression}. "
            "Preserve the same outfit, hairstyle, face, and colors as the "
            "reference image when provided. "
            f"{profile_desc}"
        )
        try:
            image_bytes = await self.gemini.generate_image(
                prompt,
                source_image=source_image,
                transparent_background=True,
                size="1024x1536",
            )
            if not image_bytes:
                return None

            storage_path = await asyncio.to_thread(
                self._storage_svc.upload_image,
                str(session_id),
                image_bytes,
            )

            # Cache in DB
            if npc_rec:
                has_default = bool(npc_images.get(npc_name, (None,))[0])
                if not has_default:
                    self.npc_gw.update_image_path(
                        db,
                        npc_rec.id,
                        storage_path,
                    )
                self.npc_gw.update_emotion_image(
                    db,
                    npc_rec.id,
                    expression,
                    storage_path,
                )

            return f"{GENERATED_IMAGES_BUCKET}/{storage_path}"
        except Exception:
            logger.warning(
                "NPC emotion image generation failed",
                npc_name=npc_name,
                expression=expression,
            )
            return None

    async def _load_npc_base_image(
        self,
        default_path: str | None,
    ) -> bytes | None:
        """Load base NPC image bytes for expression-variant generation."""
        if not default_path:
            return None
        bucket, path = _resolve_npc_bucket_and_path(default_path)
        return await asyncio.to_thread(
            self._storage_svc.download_image,
            path,
            bucket,
        )

    async def _generate_and_upload_image(
        self,
        db: Session,
        session_id: uuid.UUID,
        description: str,
    ) -> str | None:
        """Generate scene image, upload, and cache in scene_backgrounds."""
        try:
            image_bytes = await self.gemini.generate_image(
                f"Fantasy RPG scene: {description}",
            )
            if not image_bytes:
                return None

            storage_path = await asyncio.to_thread(
                self._storage_svc.upload_image,
                str(session_id),
                image_bytes,
            )

            # Cache the generated background for reuse
            location_name = description[:100]
            self.bg_gw.create(
                db,
                SceneBackgrounds(
                    id=uuid.uuid4(),
                    session_id=session_id,
                    location_name=location_name,
                    image_path=storage_path,
                    description=description,
                    created_at=datetime.now(UTC),
                ),
            )

            return f"{GENERATED_IMAGES_BUCKET}/{storage_path}"
        except Exception:
            logger.warning(
                "Scene image generation/upload failed",
                description=description,
            )
            return None


# ---------------------------------------------------------------------------
# Module-level helpers
# ---------------------------------------------------------------------------


def _collect_npc_character_assets(
    nodes: list[Any],
) -> list[tuple[str, str | None]]:
    """Collect unique (npc_name, expression) pairs from scene nodes."""
    seen: set[tuple[str, str | None]] = set()
    result: list[tuple[str, str | None]] = []
    for node in nodes:
        characters = getattr(node, "characters", None)
        if not characters:
            continue
        for ch in characters:
            name = ch.npc_name if hasattr(ch, "npc_name") else None
            if not name:
                continue
            expr = ch.expression if hasattr(ch, "expression") else None
            pair = (name, expr)
            if pair not in seen:
                seen.add(pair)
                result.append(pair)
    return result


def _collect_required_assets(nodes: list[Any]) -> list[str]:
    """Collect unique background references from scene nodes.

    Returns deduplicated list of background values (IDs or descriptions).
    """
    seen: set[str] = set()
    result: list[str] = []
    for node in nodes:
        bg = node.background if hasattr(node, "background") else None
        if bg and bg not in seen:
            seen.add(bg)
            result.append(bg)
    return result


def _has_session_end(changes: StateChanges | None) -> bool:
    """Check if state_changes includes a session_end."""
    return changes is not None and changes.session_end is not None


def _log_session_end(
    session_id: uuid.UUID,
    changes: StateChanges | None,
) -> None:
    """Log when LLM decides to end the session."""
    se = changes.session_end if changes else None
    logger.info(
        "LLM decided to end session",
        session_id=str(session_id),
        ending_type=se.ending_type if se else "unknown",
        ending_summary=se.ending_summary if se else "",
    )


def _compute_latest_flags(
    context: GameContext,
    changes: StateChanges | None,
) -> dict[str, bool]:
    """Compute latest flags from context + decision without DB re-read."""
    flags: dict[str, bool] = dict(context.current_state.get("flags", {}))
    if changes and changes.flag_changes:
        for fc in changes.flag_changes:
            if fc.value:
                flags[fc.flag_id] = True
            else:
                flags.pop(fc.flag_id, None)
    return flags


def _compute_latest_stats(
    context: GameContext,
    changes: StateChanges | None,
) -> dict[str, Any]:
    """Compute latest stats from context + decision without DB re-read."""
    stats: dict[str, Any] = dict(context.player.stats)
    if changes and changes.stats_delta:
        for key, delta in changes.stats_delta.items():
            stats[key] = stats.get(key, 0) + delta
    return stats


def _build_npc_image_entries(npcs: list[Npcs]) -> NpcImageMap:
    """Extract (default_path, emotion_map) for each NPC with an image."""
    result: NpcImageMap = {}
    for npc in npcs:
        if not npc.image_path:
            continue
        emotion_map: dict[str, str] = {}
        raw = getattr(npc, "emotion_images", None)
        if raw and isinstance(raw, dict):
            emotion_map = {k: v for k, v in raw.items() if isinstance(v, str) and v}
        result[npc.name] = (npc.image_path, emotion_map)
    return result


def _resolve_npc_bucket_and_path(path: str) -> tuple[str, str]:
    """Resolve storage bucket for an NPC image path saved in DB."""
    if path.startswith(f"{SCENARIO_ASSETS_BUCKET}/"):
        return SCENARIO_ASSETS_BUCKET, path.removeprefix(
            f"{SCENARIO_ASSETS_BUCKET}/",
        )
    if path.startswith(f"{GENERATED_IMAGES_BUCKET}/"):
        return GENERATED_IMAGES_BUCKET, path.removeprefix(
            f"{GENERATED_IMAGES_BUCKET}/",
        )
    if path.startswith("sessions/"):
        return GENERATED_IMAGES_BUCKET, path
    return SCENARIO_ASSETS_BUCKET, path


def _to_bucketed_npc_path(path: str) -> str:
    """Convert DB path to ``{bucket}/{object_path}`` for assetReady."""
    bucket, resolved_path = _resolve_npc_bucket_and_path(path)
    return f"{bucket}/{resolved_path}"


def _error_event(message: str) -> str:
    """Build an SSE error event string."""
    payload = json.dumps(
        {"type": "error", "error": message},
        ensure_ascii=False,
    )
    return f"data: {payload}\n\n"


def _image_event(path: str) -> str:
    """Build an SSE imageUpdate event string.

    ``path`` is ``{bucket}/{object_path}`` so the frontend can call
    ``supabase.storage.from(bucket).getPublicUrl(objectPath)``.
    """
    payload = json.dumps(
        {"type": "imageUpdate", "path": path},
        ensure_ascii=False,
    )
    return f"data: {payload}\n\n"


def _asset_ready_event(key: str, path: str) -> str:
    """Build an SSE assetReady event string."""
    payload = json.dumps(
        {"type": "assetReady", "key": key, "path": path},
        ensure_ascii=False,
    )
    return f"data: {payload}\n\n"


def _bgm_update_event(path: str, mood: str) -> str:
    """Build an SSE bgmUpdate event string."""
    payload = json.dumps(
        {"type": "bgmUpdate", "path": path, "mood": mood},
        ensure_ascii=False,
    )
    return f"data: {payload}\n\n"


def _bgm_generating_event(mood: str) -> str:
    """Build an SSE bgmGenerating event string."""
    payload = json.dumps(
        {"type": "bgmGenerating", "mood": mood},
        ensure_ascii=False,
    )
    return f"data: {payload}\n\n"


def _done_event(
    *,
    turn_number: int,
    requires_user_action: bool,
    is_ending: bool,
    will_continue: bool,
    stop_reason: str,
) -> str:
    """Build an SSE done event with turn completion metadata."""
    payload = json.dumps(
        {
            "type": "done",
            "turn_number": turn_number,
            "requires_user_action": requires_user_action,
            "is_ending": is_ending,
            "will_continue": will_continue,
            "stop_reason": stop_reason,
        },
        ensure_ascii=False,
    )
    return f"data: {payload}\n\n"


def _is_done_event(raw_event: str) -> bool:
    """Return whether SSE raw string is a `{type: done}` payload."""
    line = raw_event.strip()
    if not line.startswith("data: "):
        return False
    payload = line[len("data: ") :].strip()
    try:
        decoded = json.loads(payload)
    except json.JSONDecodeError:
        return False
    if not isinstance(decoded, dict):
        return False
    return decoded.get("type") == "done"


def _requires_user_action(
    decision: GmDecisionResponse,
    *,
    narrate_requires_continue: bool,
) -> bool:
    """Return whether this decision needs explicit user input to continue."""
    if decision.decision_type in {"choice", "clarify", "repair"}:
        return True
    if decision.decision_type == "narrate":
        return narrate_requires_continue
    return False


def _build_stop_reason(
    *,
    is_ending: bool,
    requires_user_action: bool,
    auto_limit_reached: bool,
    will_continue: bool,
) -> str:
    """Build a compact reason string for done-event stop/continue status."""
    if will_continue:
        return "auto_continue"
    if is_ending:
        return "ending"
    if auto_limit_reached:
        return "auto_turn_limit"
    if requires_user_action:
        return "requires_user_action"
    return "completed"


def _env_bool(name: str, *, default: bool) -> bool:
    """Parse boolean env vars from common truthy/falsey tokens."""
    raw = os.getenv(name)
    if raw is None:
        return default
    val = raw.strip().lower()
    if val in {"1", "true", "yes", "on"}:
        return True
    if val in {"0", "false", "no", "off"}:
        return False
    return default


def _env_int(name: str, *, default: int) -> int:
    """Parse integer env var with fallback."""
    raw = os.getenv(name)
    if raw is None:
        return default
    try:
        parsed = int(raw)
    except ValueError:
        return default
    if parsed <= 0:
        return default
    return parsed
