# Google ADK DatabaseSessionService + asyncpg + Supabase 調査レポート

## 調査情報

- **調査日**: 2026-03-03
- **調査者**: spec agent
- **調査対象バージョン**:
  - `google-adk`: 1.26.0（インストール済み）
  - `asyncpg`: 0.30.0（インストール済み）

---

## 1. Google ADK `DatabaseSessionService`

### 正式なシグネチャ

ソースコード（`/google/adk/sessions/database_session_service.py`）から確認した正確なシグネチャ：

```python
class DatabaseSessionService(BaseSessionService):
    def __init__(self, db_url: str, **kwargs: Any):
        """Initializes the database session service with a database URL."""
```

`**kwargs` は内部で `engine_kwargs = dict(kwargs)` として `create_async_engine(db_url, **engine_kwargs)` に渡される。

### 重要な破壊的変更

| バージョン | 変更内容 |
|-----------|---------|
| v1.19.0 | **同期ドライバのサポート廃止**。完全非同期実装に移行。asyncpg等の非同期ドライバが必須 |
| v1.24.0 | `func.now()` から明示的 `datetime.now(timezone.utc)` に変更（PostgreSQLタイムゾーンバグ発生源） |
| v1.26.0+ | PostgreSQLのタイムゾーン処理を修正（PR #4441 対応済み） |

### v1.19.0以降で非同期ドライバが必須

```python
# ❌ 旧来の同期ドライバ（v1.19.0以降は動作しない）
db_url = "postgresql+pg8000://user:pass@host/db"

# ✅ 非同期ドライバを使用
db_url = "postgresql+asyncpg://user:pass@host/db"
```

### ✅ `connect_args` の公式サポート有無

**サポートあり（✅）**。ソースコードを確認した結果：

```python
# database_session_service.py L150-153
connect_args = dict(engine_kwargs.get("connect_args", {}))
# SQLite:memory の場合のみ check_same_thread=False を設定
connect_args.setdefault("check_same_thread", False)
engine_kwargs["connect_args"] = connect_args
```

`connect_args` を含む `**kwargs` はすべて `create_async_engine()` に転送される。

### PostgreSQL でのスキーマ分離（schema isolation）

#### 方法1: `connect_args` + `options` パラメータ（psycopg系）

```python
# psycopg2 / psycopg3 ドライバの場合
session_service = DatabaseSessionService(
    "postgresql+psycopg2://user:pass@host/db",
    connect_args={"options": "-c search_path=my_schema"}
)
```

#### 方法2: `connect_args` + `server_settings`（asyncpg の場合）

```python
# asyncpg ドライバの場合（推奨）
session_service = DatabaseSessionService(
    "postgresql+asyncpg://user:pass@host/db",
    connect_args={"server_settings": {"search_path": "my_schema"}}
)
```

#### 方法3: 接続URLに直接指定（asyncpg の場合）

```python
db_url = "postgresql+asyncpg://user:pass@host/db?search_path=my_schema"
session_service = DatabaseSessionService(db_url)
```

#### 方法4: イベントリスナー（より明示的な制御）

```python
from sqlalchemy import event, text
from sqlalchemy.ext.asyncio import create_async_engine

engine = create_async_engine("postgresql+asyncpg://...")

@event.listens_for(engine.sync_engine, "connect")
def set_search_path(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("SET search_path TO my_schema")
    cursor.close()
```

### GitHub Issue #2217 からの知見

現在は `connect_args={"options": "-c search_path=..."}` または `connect_args={"server_settings": {"search_path": "..."}}` がワークアラウンドとして機能しているが、ADK に直接 `schema="..."` パラメータを渡すAPIは未実装（Feature Request として open）。

---

## 2. asyncpg (SQLAlchemy + asyncpg)

### 接続URL形式

```
postgresql+asyncpg://user:password@host:port/database
```

### ✅ `connect_args={"server_settings": {"search_path": "xxx"}}` の有効性

**有効（✅）**。asyncpg ソースコード（`connection.py`）を確認した結果：

```python
# asyncpg.connect() のシグネチャ
async def connect(
    dsn=None,
    *,
    host=None,
    port=None,
    user=None,
    password=None,
    database=None,
    ssl=None,           # ← SSL設定
    server_settings=None,  # ← PostgreSQL サーバー設定（search_pathを含む）
    ...
):
```

ドキュメントには：
```
:param dict server_settings:
    An optional dict of server runtime parameters. Refer to
    PostgreSQL documentation for a list of supported options.
```

と明記されており、`server_settings` は公式にサポートされているパラメータ。

### SQLAlchemy での使用例

```python
from sqlalchemy.ext.asyncio import create_async_engine

engine = create_async_engine(
    "postgresql+asyncpg://user:password@localhost/dbname",
    connect_args={
        "server_settings": {"search_path": "my_schema"}
    },
)
```

### PostgreSQL スキーマ指定の方法比較

| 方法 | 構文 | 推奨度 |
|------|------|--------|
| `server_settings` in `connect_args` | `connect_args={"server_settings": {"search_path": "schema"}}` | ✅ 推奨（asyncpg公式） |
| URLクエリパラメータ | `?search_path=schema` | ✅ 動作する |
| `options` in `connect_args` | `connect_args={"options": "-c search_path=schema"}` | ✅ psycopg系で使用（asyncpgでは`server_settings`を使用） |
| イベントリスナー | `SET search_path TO schema` | ✅ より明示的な制御が必要な場合 |

### ✅ `server_settings` の公式サポート

**サポートあり（✅）**。asyncpg v0.30.0 のソースコードで確認済み。

---

## 3. Supabase + asyncpg

### 接続URL形式

Supabase の PostgreSQL に asyncpg で接続する場合：

```python
# 直接接続（IPv6対応、ポート5432）
db_url = "postgresql+asyncpg://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres"

# セッションプーラー経由（IPv4対応、ポート5432）
db_url = "postgresql+asyncpg://postgres.[PROJECT_REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:5432/postgres"

# トランザクションプーラー経由（ポート6543）※注意あり、後述
db_url = "postgresql+asyncpg://postgres.[PROJECT_REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres"
```

### SSL 設定

asyncpg は `sslmode` クエリパラメータをサポートしていない（SQLAlchemy も変換しない）。

```python
# ❌ 動作しない（asyncpgは sslmode を理解しない）
db_url = "postgresql+asyncpg://...?sslmode=require"

# ✅ 方法1: connect_argsで ssl=True を渡す
engine = create_async_engine(
    "postgresql+asyncpg://user:pass@host/db",
    connect_args={"ssl": True}  # sslmode=require と同等
)

# ✅ 方法2: ssl.SSLContext を渡す（カスタム証明書）
import ssl
sslctx = ssl.create_default_context(ssl.Purpose.SERVER_AUTH)
sslctx.check_hostname = False
sslctx.verify_mode = ssl.CERT_NONE  # sslmode=require 相当
engine = create_async_engine(
    "postgresql+asyncpg://user:pass@host/db",
    connect_args={"ssl": sslctx}
)
```

### Supabase + asyncpg の Known Issues

#### トランザクションプーラー（ポート6543）+ asyncpg の問題

pgbouncer のトランザクションモードは prepared statements を未サポート。以下の設定が必須：

```python
from sqlalchemy.pool import NullPool

engine = create_async_engine(
    "postgresql+asyncpg://...@...pooler.supabase.com:6543/postgres",
    connect_args={
        "statement_cache_size": 0,
        "prepared_statement_cache_size": 0,
        "server_settings": {
            "jit": "off",
            "search_path": "my_schema"  # スキーマ設定と組み合わせ可能
        }
    },
    poolclass=NullPool,  # コネクションプーリング無効化
)
```

#### 直接接続（ポート5432）推奨

ADKの `DatabaseSessionService` 使用時は、直接接続（ポート5432）が最もシンプルで問題が少ない。

### Supabase での完全なセットアップ例

```python
from google.adk.sessions import DatabaseSessionService

# Supabase直接接続 + スキーマ分離 + SSL
db_url = "postgresql+asyncpg://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres"

session_service = DatabaseSessionService(
    db_url,
    connect_args={
        "ssl": True,  # Supabase は SSL 推奨
        "server_settings": {
            "search_path": "adk_sessions"  # ADK用の専用スキーマ
        }
    }
)
```

---

## まとめ（公式サポート有無）

| 項目 | サポート | 備考 |
|------|---------|------|
| `DatabaseSessionService(db_url, **kwargs)` | ✅ | `**kwargs` は `create_async_engine` に転送される |
| PostgreSQL + asyncpg での使用 | ✅ | v1.19.0以降で非同期ドライバ必須 |
| `connect_args` パラメータ | ✅ | 公式サポート。ソースコードで確認済み |
| `connect_args={"server_settings": {"search_path": "..."}}` | ✅ | asyncpg 公式サポート |
| `connect_args={"options": "-c search_path=..."}` | ✅ | psycopg系ドライバ向け（asyncpgでは `server_settings` を使用） |
| スキーマ分離（schema isolation） | ✅（ワークアラウン） | ADK直接パラメータなし、`server_settings` で対応 |
| `ssl=True` in `connect_args` | ✅ | asyncpg 公式サポート |
| `sslmode=require` in URL | ❌ | asyncpgは `sslmode` を未サポート |
| Supabase セッションプーラー（ポート5432） | ✅ | SSL推奨 |
| Supabase トランザクションプーラー（ポート6543） | ⚠️ | `statement_cache_size=0` + `NullPool` 必須 |

---

## 注意点: ADK v1.26.0 の既知バグ（修正済み）

GitHub Issue #4366 によると、v1.24.0-v1.25.x で PostgreSQL + asyncpg 使用時に以下のエラーが発生：

```
"invalid input for query argument $5: datetime.datetime(..., tzinfo=datetime.timezone.utc)
(can't subtract offset-naive and offset-aware datetimes)"
```

v1.26.0（現在使用中）でこのバグは修正済み（PR #4441）。

---

## 参考リンク

- [ADK Session Service 公式ドキュメント](https://google.github.io/adk-docs/sessions/session/)
- [DatabaseSessionService ソースコード (v1.23.0)](https://github.com/google/adk-python/blob/v1.23.0/src/google/adk/sessions/database_session_service.py)
- [Issue #2217: スキーマ分離の機能リクエスト](https://github.com/google/adk-python/issues/2217)
- [Issue #3653: v1.19.0で引数が受け付けられなくなった問題](https://github.com/google/adk-python/issues/3653)
- [Issue #1750: psycopg2依存性の問題](https://github.com/google/adk-python/issues/1750)
- [Issue #4366: PostgreSQL + asyncpg タイムゾーンバグ](https://github.com/google/adk-python/issues/4366)
- [SQLAlchemy Issue #6275: asyncpgでsslmodeが動作しない](https://github.com/sqlalchemy/sqlalchemy/issues/6275)
- [SQLAlchemy Discussion #6898: asyncpgでスキーマを設定する方法](https://github.com/sqlalchemy/sqlalchemy/discussions/6898)
- [asyncpg Issue #438: search_pathによるスキーマ指定](https://github.com/MagicStack/asyncpg/issues/438)
- [asyncpg Issue #737: sslmodeが動作しない問題](https://github.com/MagicStack/asyncpg/issues/737)
- [Supabase Issue #39227: asyncpg + pgbouncer prepared statement問題](https://github.com/supabase/supabase/issues/39227)
- [Supabase SSL設定ドキュメント](https://supabase.com/docs/guides/platform/ssl-enforcement)
- [SQLAlchemy PostgreSQL Dialects ドキュメント](https://docs.sqlalchemy.org/en/20/dialects/postgresql.html)
