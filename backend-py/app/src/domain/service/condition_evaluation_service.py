"""Programmatic win/fail condition evaluation.

Evaluates game conditions after each turn to determine if the session
should end automatically (victory or defeat).
"""

from __future__ import annotations

import re
from typing import Any

from pydantic import BaseModel

from util.logging import get_logger

logger = get_logger(__name__)

# Pattern: pc.stats.<stat_name> <op> <number>
_STAT_PATTERN = re.compile(
    r"^pc\.stats\.(\w+)\s*(<=|>=|<|>|==|!=)\s*(-?\d+(?:\.\d+)?)$",
)
# Pattern: session.currentTurnNumber <op> <number>
_TURN_PATTERN = re.compile(
    r"^session\.currentTurnNumber\s*(<=|>=|<|>|==|!=)\s*(-?\d+(?:\.\d+)?)$",
)

_OPS: dict[str, Any] = {
    "<=": lambda a, b: a <= b,
    ">=": lambda a, b: a >= b,
    "<": lambda a, b: a < b,
    ">": lambda a, b: a > b,
    "==": lambda a, b: a == b,
    "!=": lambda a, b: a != b,
}


class WinConditionProgress(BaseModel):
    """Progress towards a single win condition."""

    condition_id: str
    description: str
    required_flags: list[str]
    achieved_flags: list[str]
    is_achieved: bool
    progress_ratio: float


class ConditionEvaluationResult(BaseModel):
    """Result of evaluating all win/fail conditions."""

    triggered_win: dict[str, Any] | None = None
    triggered_fail: dict[str, Any] | None = None
    win_progress: list[WinConditionProgress] = []


class ConditionEvaluationService:
    """Evaluate win/fail conditions programmatically."""

    def evaluate(
        self,
        *,
        win_conditions: list[dict[str, Any]],
        fail_conditions: list[dict[str, Any]],
        current_flags: dict[str, bool],
        player_stats: dict[str, Any],
        current_turn: int,
    ) -> ConditionEvaluationResult:
        """Evaluate all conditions and return result.

        Fail conditions are checked first (fail takes priority).
        """
        # Check fail conditions first
        for fc in fail_conditions:
            expr = fc.get("condition")
            if not expr:
                continue
            if self.safe_eval_condition(
                str(expr),
                stats=player_stats,
                current_turn=current_turn,
            ):
                logger.info(
                    "Fail condition triggered",
                    condition_id=fc.get("id", "unknown"),
                )
                return ConditionEvaluationResult(
                    triggered_fail=fc,
                )

        # Check win conditions
        progress_list: list[WinConditionProgress] = []
        for wc in win_conditions:
            required = list(wc.get("requiredFlags", []))
            if not required:
                progress_list.append(
                    WinConditionProgress(
                        condition_id=str(wc.get("id", "")),
                        description=str(wc.get("description", "")),
                        required_flags=[],
                        achieved_flags=[],
                        is_achieved=False,
                        progress_ratio=0.0,
                    ),
                )
                continue

            achieved = [f for f in required if current_flags.get(f, False)]
            is_achieved = len(achieved) == len(required)

            progress_list.append(
                WinConditionProgress(
                    condition_id=str(wc.get("id", "")),
                    description=str(wc.get("description", "")),
                    required_flags=required,
                    achieved_flags=achieved,
                    is_achieved=is_achieved,
                    progress_ratio=len(achieved) / len(required),
                ),
            )

            if is_achieved:
                logger.info(
                    "Win condition triggered",
                    condition_id=wc.get("id", "unknown"),
                )
                return ConditionEvaluationResult(
                    triggered_win=wc,
                    win_progress=progress_list,
                )

        return ConditionEvaluationResult(win_progress=progress_list)

    def eval_win_condition(
        self,
        condition: dict[str, Any],
        flags: dict[str, bool],
    ) -> bool:
        """Check if a single win condition is satisfied."""
        required: list[str] = list(condition.get("requiredFlags", []))
        if not required:
            return False
        return all(flags.get(f, False) for f in required)

    def safe_eval_condition(
        self,
        expr: str,
        *,
        stats: dict[str, Any],
        current_turn: int,
    ) -> bool:
        """Safely evaluate a condition expression via pattern matching.

        Supports:
        - pc.stats.<name> <op> <number>
        - session.currentTurnNumber <op> <number>

        Returns False for unknown expressions (safe fallback).
        """
        expr = expr.strip()

        # Try stat pattern
        m = _STAT_PATTERN.match(expr)
        if m:
            stat_name, op, threshold_str = m.groups()
            stat_val = stats.get(stat_name)
            if stat_val is None:
                return False
            threshold = float(threshold_str)
            return bool(_OPS[op](float(stat_val), threshold))

        # Try turn pattern
        m = _TURN_PATTERN.match(expr)
        if m:
            op, threshold_str = m.groups()
            threshold = float(threshold_str)
            return bool(_OPS[op](float(current_turn), threshold))

        logger.warning("Unknown condition expression", expr=expr)
        return False

    def build_progress_prompt(
        self,
        result: ConditionEvaluationResult,
    ) -> str:
        """Build LLM-facing progress text for prompt injection."""
        if result.triggered_win or result.triggered_fail:
            return ""
        if not result.win_progress:
            return ""

        lines: list[str] = ["\n# Condition Progress"]
        for wp in result.win_progress:
            if not wp.required_flags:
                continue
            achieved = len(wp.achieved_flags)
            total = len(wp.required_flags)
            missing = [f for f in wp.required_flags if f not in wp.achieved_flags]
            lines.append(
                f"- {wp.description}: {achieved}/{total} flags"
                f" (achieved: {wp.achieved_flags},"
                f" missing: {missing})",
            )

        if len(lines) <= 1:
            return ""
        return "\n".join(lines)
