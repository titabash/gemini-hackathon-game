# google-adk ADK ベストプラクティス調査レポート

## 調査情報
- **調査日**: 2026-03-02
- **調査者**: spec agent
- **調査対象**: google-adk InMemoryRunner / セッション管理 / output_schema

## バージョン情報
- **現在使用中**: v1.26.0
- **最新バージョン**: v1.26.0 (2026-03-02時点)
- **ソースの著作権表記**: Copyright 2026 Google LLC

---

## 1. InMemoryRunner vs Runner の使い分け

### InMemoryRunner の定義（ソースより）

```python
class InMemoryRunner(Runner):
  """An in-memory Runner for testing and development.

  This runner uses in-memory implementations for artifact, session, and memory
  services, providing a lightweight and self-contained environment for agent
  execution.
  """
```

ソースコードのコメントが明確に "testing and development" と定義しており、**本番用途は想定外**。

### 使い分けの基準

| 用途 | 推奨クラス | 理由 |
|------|-----------|------|
| テスト・開発・ハッカソン | `InMemoryRunner` | 設定不要で即使用可能 |
| 本番（永続化不要の場合） | `Runner` + `InMemorySessionService` | 明示的に in-memory を選択可能 |
| 本番（永続化が必要な場合） | `Runner` + `DatabaseSessionService` | PostgreSQL/SQLite等への保存 |
| Google Cloud 本番 | `Runner` + `VertexAiSessionService` | GCP管理セッション |

### 現在のコードへの評価

現在のプロジェクト（ハッカソン）では `InMemoryRunner` の使用は適切。
ただし本番移行時は `DatabaseSessionService` への切り替えが必要。

---

## 2. InMemoryRunner のライフサイクル管理

### Singleton が推奨かどうか

**Singleton（インスタンスを1つ保持し続ける）が正しい**。

理由:
- `InMemorySessionService` はインスタンス内の dict にセッションデータを保持する
  ```python
  self.sessions: dict[str, dict[str, dict[str, Session]]] = {}
  ```
- インスタンスを再作成するとセッション履歴が消える
- リクエストごとに `InMemoryRunner` を作成するとセッション連続性が失われる

### 現在のコードの評価

`AdkGmClient` が singleton として DI される実装は**正しい**。

---

## 3. auto_create_session フラグ（重要な発見）

`Runner` には `auto_create_session: bool = False` パラメータが存在する（v1.26.0以降）。

```python
def __init__(
    self,
    *,
    ...
    auto_create_session: bool = False,
):
    """
    auto_create_session: Whether to automatically create a session when
      not found. Defaults to False. If False, a missing session raises
      ValueError with a helpful message.
    """
```

`run_async` 内では `_get_or_create_session` が呼ばれ、
`auto_create_session=True` なら セッション未存在時に自動作成される。

```python
async def _get_or_create_session(self, *, user_id: str, session_id: str) -> Session:
    session = await self.session_service.get_session(...)
    if not session:
        if self.auto_create_session:
            session = await self.session_service.create_session(...)
        else:
            raise SessionNotFoundError(...)
    return session
```

**ただし `InMemoryRunner` の `__init__` には `auto_create_session` を受け取るパラメータがない**ため、
`InMemoryRunner` を使う場合は `super().__init__()` に渡せない。
→ `Runner` を直接使うか、手動で `create_session` を呼び出す必要がある。

---

## 4. _created_sessions の自前管理について

### 問題点

現在のコードでは以下の課題がある:

```python
self._created_sessions: set[str] = set()
```

1. **ADK が `AlreadyExistsError` を raise する**: `InMemorySessionService.create_session()` は `session_id` が既に存在する場合 `AlreadyExistsError` を raise する
2. **自前管理は冗長**: ADK 側でセッション存在確認が可能(`get_session`で`None`チェック)

### 推奨パターン

```python
from google.adk.errors.already_exists_error import AlreadyExistsError

async def _ensure_session(self, session_id: str) -> None:
    existing = await self._runner.session_service.get_session(
        app_name=self._APP_NAME,
        user_id=self._USER_ID,
        session_id=session_id,
    )
    if existing is None:
        await self._runner.session_service.create_session(
            app_name=self._APP_NAME,
            user_id=self._USER_ID,
            session_id=session_id,
        )
```

または `get_session` を使わず `AlreadyExistsError` をキャッチする方法:

```python
from google.adk.errors.already_exists_error import AlreadyExistsError

async def _ensure_session(self, session_id: str) -> None:
    try:
        await self._runner.session_service.create_session(
            app_name=self._APP_NAME,
            user_id=self._USER_ID,
            session_id=session_id,
        )
    except AlreadyExistsError:
        pass  # セッション既存は正常ケース
```

---

## 5. output_schema + event.content.parts[0].text パターンの評価

### LlmAgent のソースコードでの実装

```python
# llm_agent.py L830-844
result = ''.join(
    part.text
    for part in event.content.parts
    if part.text and not part.thought
)
if self.output_schema:
    if not result.strip():
        return
    result = self.output_schema.model_validate_json(result).model_dump(...)
event.actions.state_delta[self.output_key] = result
```

ADK 自身が `output_schema.model_validate_json(result)` を内部で使用している。
つまり現在のコードのパターン `event.content.parts[0].text → model_validate_json` は**正しいアプローチ**。

### 改善点

`parts[0].text` ではなく、ADK 内部と同様に**全 parts のテキストを結合**する方が堅牢:

```python
# 現在（問題あり）
text = event.content.parts[0].text

# 推奨（ADK 内部と同じパターン）
text = ''.join(
    part.text
    for part in event.content.parts
    if part.text and not part.thought
)
```

### output_key を使う代替案

`output_key` を設定することでセッション状態への自動保存が可能:

```python
agent = LlmAgent(
    output_schema=GmDecisionResponse,
    output_key="gm_decision",  # セッション状態に自動保存
)

# セッション状態から取得（dict形式）
session_state = session.state.get("gm_decision")
```

ただしこの場合 `dict` として取得されるため、Pydantic モデルへの変換は別途必要。
現在のコードように `event.content.parts[0].text` から直接取得する方が簡潔。

---

## 6. use_interactions_api=True の適切な使用場面

### ソースコードの説明

```
use_interactions_api: Whether to use the interactions API for model invocation.

When enabled, uses the interactions API (client.aio.interactions.create())
instead of the traditional generate_content API. The interactions API
provides stateful conversation capabilities, allowing you to chain
interactions using previous_interaction_id instead of sending full history.
```

### 使用する場面

- 長い会話履歴がある場合（全履歴を送信せず ID で参照）
- トークン効率を重視する場合
- Gemini の stateful conversation を活用する場合

### 注意点

- `use_interactions_api=True` は `InMemoryRunner` と組み合わせた場合、ADK 側でセッションを管理しているので二重管理になる可能性がある
- ハッカソン用途では必須ではない可能性がある（通常の generate_content で十分な場合も多い）

---

## 7. app_name / user_id の役割

### InMemorySessionService での実装

```python
self.sessions: dict[str, dict[str, dict[str, Session]]] = {}
# sessions[app_name][user_id][session_id] = session
```

| パラメータ | 役割 |
|-----------|------|
| `app_name` | アプリケーション名のネームスペース（セッションの区画） |
| `user_id` | ユーザー単位の区画（マルチユーザー対応時に重要） |
| `session_id` | 個別の会話セッションID |

### 現在のコードの評価

```python
_APP_NAME = "gm"
_USER_ID = "gm"
```

ゲームマスター専用のシングルユーザー用途では問題ないが、
`user_id` に実際のユーザーIDを使う場合はユーザーごとのセッション分離が可能になる。

---

## 8. エラーハンドリングのベストプラクティス

### セッション関連エラー

```python
from google.adk.errors.already_exists_error import AlreadyExistsError
from google.adk.errors.session_not_found_error import SessionNotFoundError
```

- `AlreadyExistsError`: セッション重複作成時
- `SessionNotFoundError`: セッション未存在時（`auto_create_session=False` の場合）

### ファイナルレスポンスが来ない場合の対処

```python
result: GmDecisionResponse | None = None
async for event in self._runner.run_async(...):
    if event.is_final_response():
        # ... パース処理
        break

if result is None:
    raise RuntimeError("ADK GM agent returned no structured output")
```

この実装は適切。ただし `break` の前に `result` 代入が成功しているか確認するパスが必要。

---

## まとめ: 現在のコードの問題点と改善案

### 問題点 1: `_created_sessions` の自前管理（中程度の問題）

**現状**: `set[str]` で作成済みセッションを追跡
**問題**: ADK の `AlreadyExistsError` を広い `except Exception` で握りつぶしている
**改善**: `AlreadyExistsError` を明示的にキャッチするか、`get_session` で存在確認する

### 問題点 2: `parts[0].text` での取得（軽微な問題）

**現状**: `event.content.parts[0].text`
**問題**: 複数の parts がある場合や thought part がある場合に不完全
**改善**: ADK 内部と同じく `''.join(part.text for part in parts if part.text and not part.thought)`

### 問題点 3: `use_interactions_api=True` の副作用

**現状**: `use_interactions_api=True` を設定している
**注意**: ADK のセッション管理と interactions API の内部ステートが干渉する可能性がある。ハッカソンでは不要かもしれない

### 問題なし（適切な実装）

- `InMemoryRunner` を singleton として管理 → 正しい
- `event.is_final_response()` で最終レスポンスを判定 → 正しい
- `model_validate_json()` で Pydantic モデルに変換 → 正しい（ADK 内部と同じ実装）
- `cleanup_session` での `delete_session` 呼び出し → 正しい

---

## 参考リンク

- [ADK Sessions ドキュメント](https://google.github.io/adk-docs/sessions/session/)
- [ADK LLM Agents ドキュメント](https://google.github.io/adk-docs/agents/llm-agents/)
- [output_schema Discussion](https://github.com/google/adk-python/discussions/322)
- [output_schema valid output Discussion](https://github.com/google/adk-python/discussions/3759)
- [ADK Runner ドキュメント](https://iamulya.one/posts/adk-runner-and-runtime-configuration/)
- [PyPI: google-adk](https://pypi.org/project/google-adk/)
