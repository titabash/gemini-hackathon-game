"""Shared fixtures for gateway tests using testcontainers PostgreSQL."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import TYPE_CHECKING

import pytest
from sqlalchemy import text
from sqlmodel import Session, SQLModel, create_engine
from testcontainers.postgres import PostgresContainer

if TYPE_CHECKING:
    from collections.abc import Generator

    from sqlalchemy.engine import Engine

from domain.entity.models import (
    ContextSummaries,
    Items,
    NpcRelationships,
    Npcs,
    Objectives,
    PlayerCharacters,
    Scenarios,
    Sessions,
    Users,
)


def _now() -> datetime:
    return datetime.now(UTC)


@pytest.fixture(scope="session")
def _postgres() -> Generator[PostgresContainer]:
    with PostgresContainer("postgres:16-alpine") as pg:
        yield pg


@pytest.fixture(scope="session")
def db_engine(_postgres: PostgresContainer) -> Generator[Engine]:
    engine = create_engine(_postgres.get_connection_url())
    SQLModel.metadata.create_all(engine)
    yield engine
    engine.dispose()


@pytest.fixture(autouse=True)
def _clean_tables(db_engine: Engine) -> None:
    with Session(db_engine) as session:
        for table in reversed(SQLModel.metadata.sorted_tables):
            session.execute(text(f"TRUNCATE TABLE {table.name} CASCADE"))
        session.commit()


@pytest.fixture
def db_session(db_engine: Engine) -> Generator[Session]:
    with Session(db_engine) as session:
        yield session


@pytest.fixture
def user_id() -> uuid.UUID:
    return uuid.uuid4()


@pytest.fixture
def scenario_id() -> uuid.UUID:
    return uuid.uuid4()


@pytest.fixture
def session_id() -> uuid.UUID:
    return uuid.uuid4()


@pytest.fixture
def seed_user(db_session: Session, user_id: uuid.UUID) -> Users:
    user = Users(
        id=user_id,
        display_name="Test Player",
        account_name="test_player",
        created_at=_now(),
        updated_at=_now(),
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def seed_scenario(
    db_session: Session,
    scenario_id: uuid.UUID,
    seed_user: Users,
) -> Scenarios:
    scenario = Scenarios(
        id=scenario_id,
        title="Dark Forest Adventure",
        description="A mysterious forest full of danger.",
        initial_state={"phase": "intro"},
        win_conditions={"main": "Escape the forest"},
        fail_conditions={"death": "HP reaches 0"},
        created_by=seed_user.id,
        created_at=_now(),
        updated_at=_now(),
    )
    db_session.add(scenario)
    db_session.commit()
    db_session.refresh(scenario)
    return scenario


@pytest.fixture
def seed_session(
    db_session: Session,
    session_id: uuid.UUID,
    seed_user: Users,
    seed_scenario: Scenarios,
) -> Sessions:
    game_session = Sessions(
        id=session_id,
        user_id=seed_user.id,
        scenario_id=seed_scenario.id,
        title="Test Session",
        status="active",
        current_state={"phase": "exploration"},
        current_turn_number=0,
        created_at=_now(),
        updated_at=_now(),
    )
    db_session.add(game_session)
    db_session.commit()
    db_session.refresh(game_session)
    return game_session


@pytest.fixture
def seed_player_character(
    db_session: Session,
    seed_session: Sessions,
) -> PlayerCharacters:
    pc = PlayerCharacters(
        id=uuid.uuid4(),
        session_id=seed_session.id,
        name="Hero",
        stats={"str": 10, "dex": 12, "int": 14},
        status_effects=[],
        location_x=0,
        location_y=0,
        created_at=_now(),
        updated_at=_now(),
    )
    db_session.add(pc)
    db_session.commit()
    db_session.refresh(pc)
    return pc


@pytest.fixture
def seed_npc(
    db_session: Session,
    seed_session: Sessions,
) -> Npcs:
    npc = Npcs(
        id=uuid.uuid4(),
        session_id=seed_session.id,
        name="Merchant",
        profile={"personality": "friendly", "role": "trader"},
        goals={"primary": "Sell goods"},
        state={"mood": "neutral"},
        location_x=5,
        location_y=3,
        created_at=_now(),
        updated_at=_now(),
    )
    db_session.add(npc)
    db_session.commit()
    db_session.refresh(npc)
    return npc


@pytest.fixture
def seed_npc_relationship(
    db_session: Session,
    seed_npc: Npcs,
) -> NpcRelationships:
    rel = NpcRelationships(
        id=uuid.uuid4(),
        npc_id=seed_npc.id,
        affinity=10,
        trust=5,
        fear=0,
        debt=0,
        flags={},
        created_at=_now(),
        updated_at=_now(),
    )
    db_session.add(rel)
    db_session.commit()
    db_session.refresh(rel)
    return rel


@pytest.fixture
def seed_context_summary(
    db_session: Session,
    seed_session: Sessions,
) -> ContextSummaries:
    summary = ContextSummaries(
        id=uuid.uuid4(),
        session_id=seed_session.id,
        plot_essentials={"key_event": "Found a map"},
        short_term_summary="The hero entered the forest.",
        confirmed_facts={"forest_type": "dark"},
        last_updated_turn=3,
        created_at=_now(),
        updated_at=_now(),
    )
    db_session.add(summary)
    db_session.commit()
    db_session.refresh(summary)
    return summary


@pytest.fixture
def seed_objective(
    db_session: Session,
    seed_session: Sessions,
) -> Objectives:
    obj = Objectives(
        id=uuid.uuid4(),
        session_id=seed_session.id,
        title="Find the Exit",
        description="Navigate through the forest to find the exit.",
        status="active",
        sort_order=1,
        created_at=_now(),
        updated_at=_now(),
    )
    db_session.add(obj)
    db_session.commit()
    db_session.refresh(obj)
    return obj


@pytest.fixture
def seed_item(
    db_session: Session,
    seed_session: Sessions,
) -> Items:
    item = Items(
        id=uuid.uuid4(),
        session_id=seed_session.id,
        name="Health Potion",
        description="Restores 50 HP",
        type="consumable",
        quantity=3,
        is_equipped=False,
        created_at=_now(),
        updated_at=_now(),
    )
    db_session.add(item)
    db_session.commit()
    db_session.refresh(item)
    return item
