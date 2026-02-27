"""Tests for BgmCacheGateway."""

from __future__ import annotations

import uuid

from domain.entity.models import Bgm
from gateway.bgm_cache_gateway import BgmCacheGateway


class TestBgmCacheGateway:
    """Gateway behavior for bgm table."""

    def test_find_by_scenario_and_mood_returns_none(
        self,
        db_session,
        seed_scenario,
    ) -> None:
        gw = BgmCacheGateway()

        result = gw.find_by_scenario_and_mood(
            db_session,
            seed_scenario.id,
            "battle",
        )

        assert result is None

    def test_create_and_find(
        self,
        db_session,
        seed_scenario,
    ) -> None:
        gw = BgmCacheGateway()
        record = Bgm(
            id=uuid.uuid4(),
            scenario_id=seed_scenario.id,
            mood="battle",
            audio_path="scenarios/1/battle.mp3",
            prompt_used="Epic battle score, loopable",
            duration_seconds=60,
            created_at=seed_scenario.created_at,
        )

        gw.create(db_session, record)
        found = gw.find_by_scenario_and_mood(
            db_session,
            seed_scenario.id,
            "battle",
        )

        assert found is not None
        assert found.scenario_id == seed_scenario.id
        assert found.audio_path == "scenarios/1/battle.mp3"
