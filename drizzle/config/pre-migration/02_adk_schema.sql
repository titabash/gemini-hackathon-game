-- ADK (Google Agent Development Kit) 専用スキーマ
-- ADK の DatabaseSessionService が自動生成するテーブル (sessions, events, app_states 等) を
-- public スキーマに混入させないために専用スキーマを作成する。
--
-- ADK 接続時に connect_args={"server_settings": {"search_path": "adk"}} を指定することで
-- ADK テーブルはすべて adk スキーマに格納される。
-- Drizzle は schemaFilter: ['public'] のため adk スキーマを無視する。
-- sqlacodegen は --schemas public のため adk スキーマをスキャンしない。
CREATE SCHEMA IF NOT EXISTS adk;
