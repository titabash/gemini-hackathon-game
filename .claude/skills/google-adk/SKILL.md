# Google ADK (Agent Development Kit) - GM LLM Client

## Overview

このプロジェクトでは LangChain の代わりに **Google ADK** を使用して GM エージェントを実装している。

- **実装**: `backend-py/app/src/infra/adk_gm_client.py`
- **採用理由**: `output_schema` で Pydantic 直接指定 → 構造化出力が保証される
  - LangChain 不採用理由: `response_json_schema` が `langchain-google-genai` 未対応

## ADK 採用の判断基準

| 用途 | 推奨 |
|------|------|
| Pydantic モデルで構造化出力が必要 | **ADK** (`output_schema=`) |
| 一般的な LLM 呼び出し | LangChain |
| ツール呼び出し・エージェント | ADK または LangGraph |

## Core Setup

```python
from google.adk.agents import LlmAgent
from google.adk.models.google_llm import Gemini
from google.adk.runners import Runner
from google.adk.sessions import DatabaseSessionService
from google.genai import types as genai_types

from domain.entity.gm_types import GmDecisionResponse

agent = LlmAgent(
    name="gm_agent",
    model=Gemini(model="gemini-3-flash-preview"),
    instruction=GM_SYSTEM_PROMPT,
    output_schema=GmDecisionResponse,  # Pydantic モデル直接指定
)
runner = Runner(
    agent=agent,
    app_name="gm",
    session_service=DatabaseSessionService(db_url, connect_args=...),
    auto_create_session=True,  # session_id がなければ自動生成
)
```

## CRITICAL: use_interactions_api=True は使用禁止

```python
# ❌ 禁止: output_schema と組み合わせると構造化出力が保証されない
agent = LlmAgent(
    ...,
    output_schema=GmDecisionResponse,
    # use_interactions_api=True,  ← response_schema を API リクエストに含めないため NG
)

# ✅ 正しい: use_interactions_api は指定しない（デフォルト=False）
agent = LlmAgent(
    name="gm_agent",
    model=Gemini(model=...),
    instruction=SYSTEM_PROMPT,
    output_schema=GmDecisionResponse,
)
```

## 構造化出力の受け取り方

```python
async def decide(self, *, prompt: str, session_id: str) -> GmDecisionResponse:
    message = genai_types.Content(
        role="user",
        parts=[genai_types.Part(text=prompt)],
    )
    result: GmDecisionResponse | None = None
    async for event in runner.run_async(
        user_id="gm",
        session_id=session_id,
        new_message=message,
    ):
        if event.is_final_response():
            if event.content and event.content.parts:
                # ADK 内部と同じパターン: thought parts を除外して全 parts を結合
                text = "".join(
                    part.text
                    for part in event.content.parts
                    if part.text and not part.thought  # ← thought を除外
                )
                if text.strip():
                    result = GmDecisionResponse.model_validate_json(text)
            break

    if result is None:
        raise RuntimeError("ADK GM agent returned no structured output")
    return result
```

## スキーマ分離（CRITICAL）

ADK が自動生成するテーブル（sessions, events, app_states 等）を `adk` スキーマに隔離する。

**理由**:
- `public` スキーマとの衝突を防ぐ
- Drizzle は `schemaFilter: ['public']` → `adk` スキーマを無視
- sqlacodegen は `--schemas public` → `adk` スキーマをスキャンしない

```python
def _adk_session_service() -> DatabaseSessionService:
    connect_args: dict[str, object] = {
        "server_settings": {"search_path": "adk"},  # ← adk スキーマに隔離
    }
    return DatabaseSessionService(asyncpg_url, connect_args=connect_args)
```

## asyncpg の SSL 問題

asyncpg は URL の `sslmode` パラメータを解釈しない（[asyncpg#737](https://github.com/MagicStack/asyncpg/issues/737)）。

```python
# ❌ これは動かない
url = "postgresql+asyncpg://host/db?sslmode=require"

# ✅ URL から sslmode を除去し、connect_args で SSL を指定
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

parsed = urlparse(asyncpg_url)
query = parse_qs(parsed.query)
sslmode = query.pop("sslmode", [None])[0]
clean_url = urlunparse(
    parsed._replace(query=urlencode({k: v[0] for k, v in query.items()}))
)
connect_args: dict[str, object] = {"server_settings": {"search_path": "adk"}}
if sslmode == "require":
    connect_args["ssl"] = True

session_service = DatabaseSessionService(clean_url, connect_args=connect_args)
```

## API Key 設定

ADK は `GOOGLE_API_KEY` を読む。`GEMINI_API_KEY` がある場合はマッピングする：

```python
api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
os.environ.setdefault("GOOGLE_API_KEY", api_key)
```

## セッション管理

```python
runner = Runner(
    ...,
    session_service=DatabaseSessionService(...),
    auto_create_session=True,  # session_id がなければ自動生成
)

# 同一 session_id を使うことで ADK セッション履歴が引き継がれる
# auto-advance 時の複数ターン連鎖にも対応
result = runner.run_async(
    user_id="gm",
    session_id=game_session_id,  # ゲームセッション ID を流用
    new_message=message,
)
```

## テストでの注意

```python
# create_async_engine は lazy のため、runner.run_async をモックしている限り
# テストで実際の DB 接続は発生しない
@pytest.fixture
def mock_runner():
    with patch.object(AdkGmClient, '_runner') as mock:
        mock.run_async = AsyncMock(return_value=iter([fake_event]))
        yield mock
```

## GmDecisionResponse スキーマ（CRITICAL）

```python
class GmDecisionResponse(BaseModel):
    decision_type: Literal["narrate", "choice", "clarify", "repair"]
    narration_text: str
    nodes: list[SceneNode] | None = None  # ← ADK 導入後の主要フィールド
    # ... その他フィールド

class SceneNode(BaseModel):
    type: Literal["narration", "dialogue", "choice"]
    text: str
    speaker: str | None = None
    background: str | None = None
    characters: list[CharacterDisplay] | None = None
    choices: list[ChoiceOption] | None = None  # type="choice" のノードのみ
```

### ADK 導入で変わった点（LangChain との差分）

| 項目 | 旧（LangChain） | 新（ADK） |
|------|----------------|-----------|
| 選択肢フィールド | `decision.choices` | `decision.nodes[-1].choices`（最後の `type="choice"` ノード） |
| セッション管理 | 自前実装 | `DatabaseSessionService` に委譲 |
| 構造化出力 | `response_json_schema`（未対応） | `output_schema=` で Pydantic 直接指定 |

### choice ノードのアクセスパターン（CRITICAL）

```python
# ✅ ADK 後の正しいアクセス方法
choice_node = next(
    (n for n in reversed(decision.nodes) if n.type == "choice" and n.choices),
    None,
)
choices = choice_node.choices if choice_node else None

# ❌ 古い方法（ADK 前）- nodes が存在しなかった時代
choices = decision.choices  # AttributeError になる
```

**ルール**: `decision_type="choice"` の場合、選択肢は `decision.nodes` の中の `type="choice"` ノードの `.choices` に格納される。トップレベルの `.choices` フィールドは存在しない。

## プロンプト設計のポイント

`gm_prompts.py` での構造化出力を促すプロンプト：

- "The LAST node MUST be `type='choice'` if `decision_type='choice'`"
- "ALWAYS output a `nodes` array with 3-10 SceneNode objects"
- ノードは narration/dialogue → 最後に choice の順序で生成させる
