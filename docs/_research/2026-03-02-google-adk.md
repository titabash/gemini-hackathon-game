# Google ADK (google-adk) 調査レポート

## 調査情報
- **調査日**: 2026-03-02
- **調査者**: spec agent
- **対象バージョン**: google-adk >= 1.0.0 (最新: 1.26.0)

---

## バージョン情報

- **最新バージョン**: v1.26.0 (2026-02-26 リリース)
- **Python 要件**: >= 3.10
- **google-genai 依存**: `>=1.56.0, <2.0.0`

### リリース履歴 (直近)

| バージョン | リリース日 | 主な変更 |
|-----------|-----------|---------|
| v1.26.0 | 2026-02-26 | Intra-invocation compaction, BigQuery search, Memory consolidation |
| v1.25.1 | 2026-02-18 | McpSessionManager pickle fix |
| v1.25.0 | 2026-02-11 | Auto-session creation, token-threshold compaction |
| v1.24.0 | 2026-02-04 | Breaking change to credential manager, A2UI v0.8 integration |

---

## 1. パッケージ情報

```bash
pip install google-adk
```

### 主要依存関係 (v1.26.0)

- `google-genai>=1.56.0,<2.0.0`
- `google-cloud-aiplatform[agent-engines]>=1.132.0,<2.0.0`
- `pydantic>=2.7.0,<3.0.0`
- `fastapi>=0.124.1,<1.0.0`
- `httpx`, `websockets`, `SQLAlchemy`

---

## 2. LlmAgent の使い方

### インポートパス

```python
from google.adk.agents import LlmAgent, Agent  # Agent は LlmAgent のエイリアス
from google.adk.agents.llm_agent import LlmAgent  # 明示的なパス
```

### 全パラメータ

| パラメータ | 型 | 必須 | 説明 |
|-----------|---|------|------|
| `name` | str | 必須 | エージェントの一意識別子 |
| `model` | str \| Gemini | 必須 | LLM モデル |
| `instruction` | str | 推奨 | system_instruction 相当 |
| `description` | str | 任意 | マルチエージェントでの能力説明 |
| `tools` | list | 任意 | ツールリスト |
| `output_schema` | type[BaseModel] | 任意 | 構造化出力スキーマ |
| `output_key` | str | 任意 | session.state に保存するキー名 |
| `input_schema` | type[BaseModel] | 任意 | 入力スキーマ |
| `generate_content_config` | GenerateContentConfig | 任意 | temperature 等の生成設定 |
| `include_contents` | str | 任意 | 'default' or 'none' |

### 基本的な使い方

```python
from google.adk.agents import LlmAgent
from pydantic import BaseModel, Field

class GmDecisionResponse(BaseModel):
    decision_type: str
    narration_text: str
    choices: list[str] | None = None

agent = LlmAgent(
    name="gm_agent",
    model="gemini-2.5-flash",  # 文字列指定が最も簡単
    instruction="You are a game master. Respond with structured JSON.",
    output_schema=GmDecisionResponse,
    output_key="gm_decision",  # session.state["gm_decision"] に保存
)
```

### output_schema の重要な制約

- **tools との組み合わせ**: 特定モデル (Gemini 3.0 以上) でのみ同時使用可能
- **内部動作**: `pydantic.BaseModel.model_validate_json` で自動バリデーション
- **スキーマ違反**: `pydantic.ValidationError` が発生
- `output_schema` 設定時は instruction に JSON 構造を明示すること

---

## 3. Gemini モデルの指定方法

### 方法1: 文字列指定 (推奨・最シンプル)

```python
agent = LlmAgent(
    model="gemini-2.5-flash",
    ...
)
```

### 方法2: Gemini クラスで詳細設定

```python
from google.adk.models.google_llm import Gemini  # または
from google.adk.agents.llm_agent import Gemini   # エイリアス

agent = LlmAgent(
    model=Gemini(
        model="gemini-2.5-flash",
        use_interactions_api=True,   # Interactions API 有効化
    ),
    ...
)
```

### use_interactions_api=True について

- Interactions API を有効化してサーバーサイドで会話履歴を管理
- ADK Runner が自動的に `previous_interaction_id` を連鎖させる
- **制限**: `bypass_multi_tools_limit=True` が必要な場合がある
- Python SDK 要件: `google-genai>=1.55.0` (ADK 1.26 は >=1.56.0 を要求)

### context_cache の設定方法

context_cache は **LlmAgent ではなく App レベル** で設定:

```python
from google.adk.agents.context_cache_config import ContextCacheConfig
from google.adk.apps.app import App

app = App(
    name='my-app',
    root_agent=root_agent,
    context_cache_config=ContextCacheConfig(
        min_tokens=2048,    # キャッシュ開始の最小トークン数
        ttl_seconds=1800,   # キャッシュ保持秒数 (デフォルト 1800)
        cache_intervals=10, # 最大再利用回数 (デフォルト 10)
    ),
)
```

- ADK Python v1.15.0 以降で対応
- Gemini 2.0 以上が必要

---

## 4. Runner / InMemoryRunner

### インポートパス

```python
from google.adk.runners import Runner, InMemoryRunner
from google.adk.sessions import InMemorySessionService
from google.genai import types as genai_types
```

### InMemoryRunner vs Runner

| | InMemoryRunner | Runner |
|-|----------------|--------|
| session_service | 自動内包 | 外部指定必須 |
| 用途 | 開発・テスト・実験 | プロダクション |
| セッション永続性 | なし (メモリのみ) | あり (DB など) |

### セッション作成

**InMemoryRunner を使う場合:**

```python
runner = InMemoryRunner(
    agent=agent,
    app_name="my_app",  # オプション
)

# InMemoryRunner が session_service を内包
session = await runner.session_service.create_session(
    app_name=runner.app_name,  # InMemoryRunner のデフォルト app_name
    user_id="user_123",
    session_id="session_abc",  # 省略時は自動生成
)
```

**Runner を使う場合:**

```python
from google.adk.sessions import InMemorySessionService

session_service = InMemorySessionService()
runner = Runner(
    agent=agent,
    app_name="my_app",
    session_service=session_service,
)

session = await session_service.create_session(
    app_name="my_app",
    user_id="user_123",
    session_id="session_abc",
)
```

### run_async シグネチャ

```python
async def run_async(
    user_id: str,
    session_id: str,
    new_message: types.Content,
    run_config: RunConfig | None = None,
) -> AsyncGenerator[Event, None]:
    ...
```

### new_message の作成方法

```python
from google.genai import types

message = types.Content(
    role="user",
    parts=[types.Part(text="プレイヤーのアクション")]
)
```

---

## 5. セッション管理

### セッション作成 → メッセージ送信 → 複数ターン

```python
# 1回目のメッセージ
async for event in runner.run_async(
    user_id="user_123",
    session_id="session_abc",
    new_message=types.Content(role="user", parts=[types.Part(text="Hello")])
):
    pass

# 2回目 (同じ session_id を使えばセッション履歴が引き継がれる)
async for event in runner.run_async(
    user_id="user_123",
    session_id="session_abc",  # 同じ session_id
    new_message=types.Content(role="user", parts=[types.Part(text="What did I say?")])
):
    pass
```

Runner は session_service から会話履歴を自動取得・更新するため、
**同じ session_id を指定するだけで複数ターンが実現される**。

---

## 6. output_schema からの出力取り出し方

### イベントの型と構造

```
Event:
  - author: str               # エージェント名または 'user'
  - content: types.Content | None
    - role: str               # 'model' or 'user'
    - parts: list[types.Part]
      - text: str | None      # テキスト内容
  - is_final_response() -> bool  # 最終ユーザー向けレスポンスか
  - invocation_id: str
  - id: str
  - timestamp: float
  - actions: EventActions
```

### 方法1: event.content.parts から直接取得

```python
from pydantic import ValidationError

result: GmDecisionResponse | None = None

async for event in runner.run_async(
    user_id=user_id,
    session_id=session_id,
    new_message=message,
):
    if event.is_final_response():
        if event.content and event.content.parts:
            text = event.content.parts[0].text
            if text:
                try:
                    result = GmDecisionResponse.model_validate_json(text)
                except ValidationError as e:
                    # バリデーション失敗時のハンドリング
                    pass
        break
```

### 方法2: output_key から session.state 経由で取得

```python
agent = LlmAgent(
    ...
    output_schema=GmDecisionResponse,
    output_key="gm_decision",  # session.state に格納
)

# run_async でイベントを消費
async for event in runner.run_async(...):
    pass

# session.state から取り出す
session = await session_service.get_session(
    app_name="my_app",
    user_id=user_id,
    session_id=session_id,
)
raw_json = session.state.get("gm_decision")
if raw_json:
    result = GmDecisionResponse.model_validate_json(raw_json)
    # または session.state には既に dict が入っている場合:
    # result = GmDecisionResponse.model_validate(raw_json)
```

### output_schema の内部動作

ADK は `_output_schema_processor.py` で以下を行う:
1. LLM の出力を `types.Content(role='model', parts=[types.Part(text=json_str)])` に格納
2. `model_validate_json(json_str)` で自動バリデーション
3. バリデーション失敗時は `pydantic.ValidationError` を発生

---

## 7. google-genai との共存可否

### 結論: **共存可能**

`google-adk` は `google-genai` を**依存関係として内包**している。

```
google-adk >= 1.56.0, < 2.0.0 の google-genai を必要とする
google-genai はそのまま使用可能 (上記バージョン範囲内であれば)
```

### このプロジェクトの現状

`pyproject.toml` に `google-genai>=1.64.0` が設定済み。
`google-adk` が要求する `>=1.56.0,<2.0.0` の範囲内であるため **互換性あり**。

### ただし注意点

- FastAPI のバージョン要件: ADK は `fastapi>=0.124.1,<1.0.0`
- このプロジェクトは FastAPI を既に使用しているため、FastAPI のバージョン互換性を確認すること
- ADK 自体が FastAPI サーバーも含むため、依存関係の競合が起きる可能性がある

---

## 完全な実装例

### output_schema + InMemoryRunner + セッション管理

```python
"""
Google ADK を使った構造化出力エージェントの完全な例。
"""

import asyncio
from pydantic import BaseModel, Field, ValidationError
from google.adk.agents import LlmAgent
from google.adk.runners import InMemoryRunner
from google.genai import types

# --- 1. 出力スキーマ定義 ---

class GmDecisionResponse(BaseModel):
    decision_type: str = Field(
        description="Type of decision: narrate, choice, clarify, repair"
    )
    narration_text: str = Field(
        description="Main narration text"
    )
    choices: list[str] | None = Field(
        default=None,
        description="Player choices if decision_type is 'choice'"
    )

# --- 2. エージェント作成 ---

agent = LlmAgent(
    name="gm_agent",
    model="gemini-2.5-flash",
    instruction=(
        "You are a game master. "
        "Always respond with a valid JSON object matching the output schema. "
        "Include decision_type and narration_text."
    ),
    output_schema=GmDecisionResponse,
    output_key="gm_decision",  # session.state["gm_decision"] に保存
)

# --- 3. Runner セットアップ ---

runner = InMemoryRunner(agent=agent, app_name="gm_game")

# --- 4. セッション作成 ---

async def run_gm_session() -> None:
    USER_ID = "player_1"
    SESSION_ID = "game_session_1"

    session = await runner.session_service.create_session(
        app_name=runner.app_name,
        user_id=USER_ID,
        session_id=SESSION_ID,
    )
    print(f"Session created: {session.id}")

    # --- 5. 複数ターンの対話 ---

    turns = [
        "I enter the dark forest.",
        "I look around carefully.",
    ]

    for turn_input in turns:
        print(f"\nPlayer: {turn_input}")

        message = types.Content(
            role="user",
            parts=[types.Part(text=turn_input)]
        )

        result: GmDecisionResponse | None = None

        # --- 6. run_async でイベントを処理 ---
        async for event in runner.run_async(
            user_id=USER_ID,
            session_id=SESSION_ID,  # 同じ session_id で継続
            new_message=message,
        ):
            if event.is_final_response():
                # --- 7. Pydantic モデルとして取り出す ---
                if event.content and event.content.parts:
                    text = event.content.parts[0].text
                    if text:
                        try:
                            result = GmDecisionResponse.model_validate_json(text)
                        except ValidationError as e:
                            print(f"Validation error: {e}")

        if result:
            print(f"GM Decision Type: {result.decision_type}")
            print(f"GM Narration: {result.narration_text}")
            if result.choices:
                print(f"Choices: {result.choices}")

    # --- 8. session.state からも取り出せる ---
    session = await runner.session_service.get_session(
        app_name=runner.app_name,
        user_id=USER_ID,
        session_id=SESSION_ID,
    )
    print(f"\nSession state: {session.state}")

if __name__ == "__main__":
    asyncio.run(run_gm_session())
```

### Gemini クラスを使った高度な設定例

```python
from google.adk.agents import LlmAgent
from google.adk.models.google_llm import Gemini

agent = LlmAgent(
    name="gm_agent",
    model=Gemini(
        model="gemini-2.5-flash",
        use_interactions_api=True,  # Interactions API でサーバーサイドセッション管理
    ),
    instruction="...",
    output_schema=GmDecisionResponse,
)
```

---

## 参考リンク

- [PyPI google-adk](https://pypi.org/project/google-adk/)
- [GitHub google/adk-python](https://github.com/google/adk-python)
- [公式ドキュメント: LLM Agents](https://google.github.io/adk-docs/agents/llm-agents/)
- [公式ドキュメント: Runtime](https://google.github.io/adk-docs/runtime/)
- [公式ドキュメント: Sessions](https://google.github.io/adk-docs/sessions/session/)
- [公式ドキュメント: Events](https://google.github.io/adk-docs/events/)
- [公式ドキュメント: Gemini Models](https://google.github.io/adk-docs/agents/models/google-gemini/)
- [公式ドキュメント: Context Caching](https://google.github.io/adk-docs/context/caching/)
- [DeepWiki: Structured Output](https://deepwiki.com/google/adk-python/5.6-structured-output-and-response-schemas)
- [GitHub Discussion: output_schema validation](https://github.com/google/adk-python/discussions/3759)
