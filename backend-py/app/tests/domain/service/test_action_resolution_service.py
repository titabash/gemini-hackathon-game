"""Tests for ActionResolutionService.

Validates luck factor generation and resolution context building.
"""

from __future__ import annotations

from src.domain.service.action_resolution_service import ActionResolutionService


class TestGenerateLuckFactor:
    """Tests for luck factor (random 1-20) generation."""

    def test_range(self) -> None:
        """Luck factor should be between 1 and 20 inclusive."""
        svc = ActionResolutionService()
        for _ in range(200):
            val = svc.generate_luck_factor()
            assert 1 <= val <= 20

    def test_with_seed_reproducible(self) -> None:
        """Same seed should produce the same value."""
        svc = ActionResolutionService()
        a = svc.generate_luck_factor(seed=42)
        b = svc.generate_luck_factor(seed=42)
        assert a == b

    def test_different_seeds_differ(self) -> None:
        """Different seeds should (almost certainly) produce different values."""
        svc = ActionResolutionService()
        results = {svc.generate_luck_factor(seed=i) for i in range(100)}
        assert len(results) > 1


class TestBuildResolutionContext:
    """Tests for resolution context string building."""

    def test_contains_luck_factor(self) -> None:
        """Output should mention the luck factor value."""
        svc = ActionResolutionService()
        ctx = svc.build_resolution_context(
            player_stats={"STR": 14, "DEX": 12},
            luck_factor=15,
        )
        assert "15" in ctx

    def test_contains_player_stats(self) -> None:
        """Output should include player stat values."""
        svc = ActionResolutionService()
        ctx = svc.build_resolution_context(
            player_stats={"STR": 14, "CHA": 8},
            luck_factor=10,
        )
        assert "STR" in ctx
        assert "14" in ctx
        assert "CHA" in ctx

    def test_empty_stats(self) -> None:
        """Empty stats should still produce valid context."""
        svc = ActionResolutionService()
        ctx = svc.build_resolution_context(
            player_stats={},
            luck_factor=5,
        )
        assert "5" in ctx
        assert isinstance(ctx, str)

    def test_contains_resolution_rules(self) -> None:
        """Output should contain difficulty thresholds or resolution guidance."""
        svc = ActionResolutionService()
        ctx = svc.build_resolution_context(
            player_stats={"STR": 10},
            luck_factor=12,
        )
        assert "difficulty" in ctx.lower() or "success" in ctx.lower()

    def test_contains_mandatory_keyword(self) -> None:
        """Output should contain MANDATORY or MUST for strong enforcement."""
        svc = ActionResolutionService()
        ctx = svc.build_resolution_context(
            player_stats={"STR": 14, "DEX": 12},
            luck_factor=15,
        )
        assert "MUST" in ctx or "MANDATORY" in ctx

    def test_contains_failure_guidance(self) -> None:
        """Output should contain guidance for failure narration."""
        svc = ActionResolutionService()
        ctx = svc.build_resolution_context(
            player_stats={"STR": 14},
            luck_factor=5,
        )
        assert "FAILURE" in ctx

    def test_no_hardcoded_dnd_stats(self) -> None:
        """Resolution context should NOT hardcode D&D stat names."""
        svc = ActionResolutionService()
        ctx = svc.build_resolution_context(
            player_stats={"confidence": 75, "fear": 20},
            luck_factor=10,
        )
        # Should NOT contain hardcoded D&D references as required stat names
        assert "Physical actions: STR" not in ctx

    def test_custom_stats_mentioned(self) -> None:
        """Custom stat names should appear in the context."""
        svc = ActionResolutionService()
        ctx = svc.build_resolution_context(
            player_stats={"confidence": 75, "fear": 20, "hope": 60},
            luck_factor=10,
        )
        assert "confidence" in ctx
        assert "fear" in ctx
        assert "hope" in ctx
