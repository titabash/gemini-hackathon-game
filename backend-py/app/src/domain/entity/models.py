from typing import Optional
import datetime
import uuid

from sqlalchemy import BigInteger, Boolean, CheckConstraint, Column, Enum, ForeignKeyConstraint, Integer, PrimaryKeyConstraint, Text, UniqueConstraint, Uuid, text
from sqlalchemy.dialects.postgresql import JSONB, TIMESTAMP
from sqlmodel import Field, Relationship, SQLModel

class DrizzleMigrations(SQLModel, table=True):
    __tablename__ = '__drizzle_migrations'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='__drizzle_migrations_pkey'),
    )

    id: int = Field(sa_column=Column('id', Integer, primary_key=True))
    hash: str = Field(sa_column=Column('hash', Text, nullable=False))
    created_at: Optional[int] = Field(default=None, sa_column=Column('created_at', BigInteger))


class Users(SQLModel, table=True):
    __table_args__ = (
        PrimaryKeyConstraint('id', name='users_pkey'),
        UniqueConstraint('account_name', name='users_account_name_unique')
    )

    id: uuid.UUID = Field(sa_column=Column('id', Uuid, primary_key=True))
    display_name: str = Field(sa_column=Column('display_name', Text, nullable=False, server_default=text("''::text")))
    account_name: str = Field(sa_column=Column('account_name', Text, nullable=False))
    created_at: datetime.datetime = Field(sa_column=Column('created_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    updated_at: datetime.datetime = Field(sa_column=Column('updated_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    avatar_path: Optional[str] = Field(default=None, sa_column=Column('avatar_path', Text))

    scenarios: list['Scenarios'] = Relationship(back_populates='users')
    sessions: list['Sessions'] = Relationship(back_populates='user')


class Scenarios(SQLModel, table=True):
    __table_args__ = (
        ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL', name='scenarios_created_by_users_id_fk'),
        PrimaryKeyConstraint('id', name='scenarios_pkey')
    )

    id: uuid.UUID = Field(sa_column=Column('id', Uuid, primary_key=True, server_default=text('gen_random_uuid()')))
    title: str = Field(sa_column=Column('title', Text, nullable=False))
    description: str = Field(sa_column=Column('description', Text, nullable=False, server_default=text("''::text")))
    initial_state: dict = Field(sa_column=Column('initial_state', JSONB, nullable=False))
    win_conditions: dict = Field(sa_column=Column('win_conditions', JSONB, nullable=False))
    fail_conditions: dict = Field(sa_column=Column('fail_conditions', JSONB, nullable=False))
    is_public: bool = Field(sa_column=Column('is_public', Boolean, nullable=False, server_default=text('true')))
    created_at: datetime.datetime = Field(sa_column=Column('created_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    updated_at: datetime.datetime = Field(sa_column=Column('updated_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    thumbnail_path: Optional[str] = Field(default=None, sa_column=Column('thumbnail_path', Text))
    created_by: Optional[uuid.UUID] = Field(default=None, sa_column=Column('created_by', Uuid))

    users: Optional['Users'] = Relationship(back_populates='scenarios')
    sessions: list['Sessions'] = Relationship(back_populates='scenario')
    npcs: list['Npcs'] = Relationship(back_populates='scenario')
    scene_backgrounds: list['SceneBackgrounds'] = Relationship(back_populates='scenario')


class Sessions(SQLModel, table=True):
    __table_args__ = (
        ForeignKeyConstraint(['scenario_id'], ['scenarios.id'], ondelete='RESTRICT', name='sessions_scenario_id_scenarios_id_fk'),
        ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE', name='sessions_user_id_users_id_fk'),
        PrimaryKeyConstraint('id', name='sessions_pkey')
    )

    id: uuid.UUID = Field(sa_column=Column('id', Uuid, primary_key=True, server_default=text('gen_random_uuid()')))
    user_id: uuid.UUID = Field(sa_column=Column('user_id', Uuid, nullable=False))
    scenario_id: uuid.UUID = Field(sa_column=Column('scenario_id', Uuid, nullable=False))
    title: str = Field(sa_column=Column('title', Text, nullable=False, server_default=text("''::text")))
    status: str = Field(sa_column=Column('status', Enum('active', 'completed', 'abandoned', name='session_status'), nullable=False, server_default=text("'active'::session_status")))
    current_state: dict = Field(sa_column=Column('current_state', JSONB, nullable=False))
    current_turn_number: int = Field(sa_column=Column('current_turn_number', Integer, nullable=False, server_default=text('0')))
    created_at: datetime.datetime = Field(sa_column=Column('created_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    updated_at: datetime.datetime = Field(sa_column=Column('updated_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    ending_summary: Optional[str] = Field(default=None, sa_column=Column('ending_summary', Text))
    ending_type: Optional[str] = Field(default=None, sa_column=Column('ending_type', Text))

    scenario: Optional['Scenarios'] = Relationship(back_populates='sessions')
    user: Optional['Users'] = Relationship(back_populates='sessions')
    context_summaries: Optional['ContextSummaries'] = Relationship(sa_relationship_kwargs={'uselist': False}, back_populates='session')
    items: list['Items'] = Relationship(back_populates='session')
    npcs: list['Npcs'] = Relationship(back_populates='session')
    objectives: list['Objectives'] = Relationship(back_populates='session')
    player_characters: Optional['PlayerCharacters'] = Relationship(sa_relationship_kwargs={'uselist': False}, back_populates='session')
    scene_backgrounds: list['SceneBackgrounds'] = Relationship(back_populates='session')
    turns: list['Turns'] = Relationship(back_populates='session')


class ContextSummaries(SQLModel, table=True):
    __tablename__ = 'context_summaries'
    __table_args__ = (
        ForeignKeyConstraint(['session_id'], ['sessions.id'], ondelete='CASCADE', name='context_summaries_session_id_sessions_id_fk'),
        PrimaryKeyConstraint('id', name='context_summaries_pkey'),
        UniqueConstraint('session_id', name='context_summaries_session_id_unique')
    )

    id: uuid.UUID = Field(sa_column=Column('id', Uuid, primary_key=True, server_default=text('gen_random_uuid()')))
    session_id: uuid.UUID = Field(sa_column=Column('session_id', Uuid, nullable=False))
    plot_essentials: dict = Field(sa_column=Column('plot_essentials', JSONB, nullable=False))
    short_term_summary: str = Field(sa_column=Column('short_term_summary', Text, nullable=False, server_default=text("''::text")))
    confirmed_facts: dict = Field(sa_column=Column('confirmed_facts', JSONB, nullable=False))
    last_updated_turn: int = Field(sa_column=Column('last_updated_turn', Integer, nullable=False, server_default=text('0')))
    created_at: datetime.datetime = Field(sa_column=Column('created_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    updated_at: datetime.datetime = Field(sa_column=Column('updated_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))

    session: Optional['Sessions'] = Relationship(back_populates='context_summaries')


class Items(SQLModel, table=True):
    __table_args__ = (
        ForeignKeyConstraint(['session_id'], ['sessions.id'], ondelete='CASCADE', name='items_session_id_sessions_id_fk'),
        PrimaryKeyConstraint('id', name='items_pkey')
    )

    id: uuid.UUID = Field(sa_column=Column('id', Uuid, primary_key=True, server_default=text('gen_random_uuid()')))
    session_id: uuid.UUID = Field(sa_column=Column('session_id', Uuid, nullable=False))
    name: str = Field(sa_column=Column('name', Text, nullable=False))
    description: str = Field(sa_column=Column('description', Text, nullable=False, server_default=text("''::text")))
    type: str = Field(sa_column=Column('type', Text, nullable=False, server_default=text("''::text")))
    quantity: int = Field(sa_column=Column('quantity', Integer, nullable=False, server_default=text('1')))
    is_equipped: bool = Field(sa_column=Column('is_equipped', Boolean, nullable=False, server_default=text('false')))
    created_at: datetime.datetime = Field(sa_column=Column('created_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    updated_at: datetime.datetime = Field(sa_column=Column('updated_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    image_path: Optional[str] = Field(default=None, sa_column=Column('image_path', Text))

    session: Optional['Sessions'] = Relationship(back_populates='items')


class Npcs(SQLModel, table=True):
    __table_args__ = (
        CheckConstraint('scenario_id IS NOT NULL OR session_id IS NOT NULL', name='npcs_at_least_one_parent'),
        ForeignKeyConstraint(['scenario_id'], ['scenarios.id'], ondelete='CASCADE', name='npcs_scenario_id_scenarios_id_fk'),
        ForeignKeyConstraint(['session_id'], ['sessions.id'], ondelete='CASCADE', name='npcs_session_id_sessions_id_fk'),
        PrimaryKeyConstraint('id', name='npcs_pkey')
    )

    id: uuid.UUID = Field(sa_column=Column('id', Uuid, primary_key=True, server_default=text('gen_random_uuid()')))
    name: str = Field(sa_column=Column('name', Text, nullable=False))
    profile: dict = Field(sa_column=Column('profile', JSONB, nullable=False))
    goals: dict = Field(sa_column=Column('goals', JSONB, nullable=False))
    state: dict = Field(sa_column=Column('state', JSONB, nullable=False))
    location_x: int = Field(sa_column=Column('location_x', Integer, nullable=False, server_default=text('0')))
    location_y: int = Field(sa_column=Column('location_y', Integer, nullable=False, server_default=text('0')))
    is_active: bool = Field(sa_column=Column('is_active', Boolean, nullable=False, server_default=text('true')))
    created_at: datetime.datetime = Field(sa_column=Column('created_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    updated_at: datetime.datetime = Field(sa_column=Column('updated_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    session_id: Optional[uuid.UUID] = Field(default=None, sa_column=Column('session_id', Uuid))
    image_path: Optional[str] = Field(default=None, sa_column=Column('image_path', Text))
    scenario_id: Optional[uuid.UUID] = Field(default=None, sa_column=Column('scenario_id', Uuid))

    scenario: Optional['Scenarios'] = Relationship(back_populates='npcs')
    session: Optional['Sessions'] = Relationship(back_populates='npcs')
    npc_relationships: Optional['NpcRelationships'] = Relationship(sa_relationship_kwargs={'uselist': False}, back_populates='npc')


class Objectives(SQLModel, table=True):
    __table_args__ = (
        ForeignKeyConstraint(['session_id'], ['sessions.id'], ondelete='CASCADE', name='objectives_session_id_sessions_id_fk'),
        PrimaryKeyConstraint('id', name='objectives_pkey')
    )

    id: uuid.UUID = Field(sa_column=Column('id', Uuid, primary_key=True, server_default=text('gen_random_uuid()')))
    session_id: uuid.UUID = Field(sa_column=Column('session_id', Uuid, nullable=False))
    title: str = Field(sa_column=Column('title', Text, nullable=False))
    description: str = Field(sa_column=Column('description', Text, nullable=False, server_default=text("''::text")))
    status: str = Field(sa_column=Column('status', Enum('active', 'completed', 'failed', name='objective_status'), nullable=False, server_default=text("'active'::objective_status")))
    sort_order: int = Field(sa_column=Column('sort_order', Integer, nullable=False, server_default=text('0')))
    created_at: datetime.datetime = Field(sa_column=Column('created_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    updated_at: datetime.datetime = Field(sa_column=Column('updated_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))

    session: Optional['Sessions'] = Relationship(back_populates='objectives')


class PlayerCharacters(SQLModel, table=True):
    __tablename__ = 'player_characters'
    __table_args__ = (
        ForeignKeyConstraint(['session_id'], ['sessions.id'], ondelete='CASCADE', name='player_characters_session_id_sessions_id_fk'),
        PrimaryKeyConstraint('id', name='player_characters_pkey'),
        UniqueConstraint('session_id', name='player_characters_session_id_unique')
    )

    id: uuid.UUID = Field(sa_column=Column('id', Uuid, primary_key=True, server_default=text('gen_random_uuid()')))
    session_id: uuid.UUID = Field(sa_column=Column('session_id', Uuid, nullable=False))
    name: str = Field(sa_column=Column('name', Text, nullable=False))
    stats: dict = Field(sa_column=Column('stats', JSONB, nullable=False))
    status_effects: dict = Field(sa_column=Column('status_effects', JSONB, nullable=False))
    location_x: int = Field(sa_column=Column('location_x', Integer, nullable=False, server_default=text('0')))
    location_y: int = Field(sa_column=Column('location_y', Integer, nullable=False, server_default=text('0')))
    created_at: datetime.datetime = Field(sa_column=Column('created_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    updated_at: datetime.datetime = Field(sa_column=Column('updated_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    image_path: Optional[str] = Field(default=None, sa_column=Column('image_path', Text))

    session: Optional['Sessions'] = Relationship(back_populates='player_characters')


class SceneBackgrounds(SQLModel, table=True):
    __tablename__ = 'scene_backgrounds'
    __table_args__ = (
        CheckConstraint('scenario_id IS NOT NULL OR session_id IS NOT NULL', name='at_least_one_parent'),
        ForeignKeyConstraint(['scenario_id'], ['scenarios.id'], ondelete='CASCADE', name='scene_backgrounds_scenario_id_scenarios_id_fk'),
        ForeignKeyConstraint(['session_id'], ['sessions.id'], ondelete='CASCADE', name='scene_backgrounds_session_id_sessions_id_fk'),
        PrimaryKeyConstraint('id', name='scene_backgrounds_pkey')
    )

    id: uuid.UUID = Field(sa_column=Column('id', Uuid, primary_key=True, server_default=text('gen_random_uuid()')))
    location_name: str = Field(sa_column=Column('location_name', Text, nullable=False))
    description: str = Field(sa_column=Column('description', Text, nullable=False, server_default=text("''::text")))
    created_at: datetime.datetime = Field(sa_column=Column('created_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    scenario_id: Optional[uuid.UUID] = Field(default=None, sa_column=Column('scenario_id', Uuid))
    session_id: Optional[uuid.UUID] = Field(default=None, sa_column=Column('session_id', Uuid))
    image_path: Optional[str] = Field(default=None, sa_column=Column('image_path', Text))

    scenario: Optional['Scenarios'] = Relationship(back_populates='scene_backgrounds')
    session: Optional['Sessions'] = Relationship(back_populates='scene_backgrounds')


class Turns(SQLModel, table=True):
    __table_args__ = (
        ForeignKeyConstraint(['session_id'], ['sessions.id'], ondelete='CASCADE', name='turns_session_id_sessions_id_fk'),
        PrimaryKeyConstraint('id', name='turns_pkey'),
        UniqueConstraint('session_id', 'turn_number', name='turns_session_id_turn_number_key')
    )

    id: uuid.UUID = Field(sa_column=Column('id', Uuid, primary_key=True, server_default=text('gen_random_uuid()')))
    session_id: uuid.UUID = Field(sa_column=Column('session_id', Uuid, nullable=False))
    turn_number: int = Field(sa_column=Column('turn_number', Integer, nullable=False))
    input_type: str = Field(sa_column=Column('input_type', Enum('start', 'do', 'say', 'choice', 'roll_result', 'clarify_answer', 'system', name='input_type'), nullable=False))
    input_text: str = Field(sa_column=Column('input_text', Text, nullable=False, server_default=text("''::text")))
    gm_decision_type: str = Field(sa_column=Column('gm_decision_type', Enum('narrate', 'choice', 'roll', 'clarify', 'repair', name='gm_decision_type'), nullable=False))
    output: dict = Field(sa_column=Column('output', JSONB, nullable=False))
    created_at: datetime.datetime = Field(sa_column=Column('created_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))

    session: Optional['Sessions'] = Relationship(back_populates='turns')


class NpcRelationships(SQLModel, table=True):
    __tablename__ = 'npc_relationships'
    __table_args__ = (
        ForeignKeyConstraint(['npc_id'], ['npcs.id'], ondelete='CASCADE', name='npc_relationships_npc_id_npcs_id_fk'),
        PrimaryKeyConstraint('id', name='npc_relationships_pkey'),
        UniqueConstraint('npc_id', name='npc_relationships_npc_id_unique')
    )

    id: uuid.UUID = Field(sa_column=Column('id', Uuid, primary_key=True, server_default=text('gen_random_uuid()')))
    npc_id: uuid.UUID = Field(sa_column=Column('npc_id', Uuid, nullable=False))
    affinity: int = Field(sa_column=Column('affinity', Integer, nullable=False, server_default=text('0')))
    trust: int = Field(sa_column=Column('trust', Integer, nullable=False, server_default=text('0')))
    fear: int = Field(sa_column=Column('fear', Integer, nullable=False, server_default=text('0')))
    debt: int = Field(sa_column=Column('debt', Integer, nullable=False, server_default=text('0')))
    flags: dict = Field(sa_column=Column('flags', JSONB, nullable=False))
    created_at: datetime.datetime = Field(sa_column=Column('created_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))
    updated_at: datetime.datetime = Field(sa_column=Column('updated_at', TIMESTAMP(True, 3), nullable=False, server_default=text('now()')))

    npc: Optional['Npcs'] = Relationship(back_populates='npc_relationships')
