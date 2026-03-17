# Game Engine & ADK Patterns

## Google ADK GM Agent (CRITICAL)

GM エージェントは LangChain ではなく **Google ADK** を使用する（`backend-py/app/src/infra/adk_gm_client.py`）。

### ADK 採用理由

`langchain-google-genai` は `response_json_schema` 未対応のため、Pydantic 構造化出力には ADK の `output_schema=` を使用する。

### 必須セットアップ

```python
from google.adk.agents import LlmAgent
from google.adk.models.google_llm import Gemini
from google.adk.runners import Runner
from google.adk.sessions import DatabaseSessionService

agent = LlmAgent(
    name="gm_agent",
    model=Gemini(model="gemini-3-flash-preview"),
    instruction=GM_SYSTEM_PROMPT,
    output_schema=GmDecisionResponse,  # Pydantic モデル直接指定
    # use_interactions_api は絶対に True にしない（構造化出力が壊れる）
)
```

### CRITICAL: use_interactions_api=True 禁止

`use_interactions_api=True` は `response_schema` を API リクエストに含めないため、`output_schema` と組み合わせると構造化出力が保証されない。

### GmDecisionResponse スキーマ（ADK 導入後）

```python
class GmDecisionResponse(BaseModel):
    decision_type: Literal["narrate", "choice", "clarify", "repair"]
    nodes: list[SceneNode] | None = None  # ← ADK 後の主要フィールド

class SceneNode(BaseModel):
    type: Literal["narration", "dialogue", "choice"]
    choices: list[ChoiceOption] | None = None  # type="choice" のノードのみ
```

### CRITICAL: 選択肢アクセスパターン

```python
# ✅ ADK 後の正しい方法
choice_node = next(
    (n for n in reversed(decision.nodes) if n.type == "choice" and n.choices),
    None,
)
choices = choice_node.choices if choice_node else None

# ❌ 古い方法（ADK 前）- decision.choices は存在しない
choices = decision.choices  # AttributeError になる
```

`decision_type="choice"` の場合、選択肢は **`decision.nodes` の中の `type="choice"` ノードの `.choices`** に格納される。

### スキーマ分離

ADK が自動生成するテーブルは PostgreSQL の `adk` スキーマに隔離する：

```python
connect_args = {"server_settings": {"search_path": "adk"}}
DatabaseSessionService(asyncpg_url, connect_args=connect_args)
```

## genui game-surface パターン（CRITICAL）

### Surface ID 一覧

| surfaceId | 用途 |
|-----------|------|
| `game-surface` | choiceGroup / continueButton / clarifyQuestion |
| `game-narration` | narrativePanel |
| `game-npcs` | npcGallery |

### surfaceUpdate + beginRendering は必ずセットで送る

```
# バックエンド SSE 送信順序
nodesReady → stateUpdate → game-npcs (A2UI) → game-narration (A2UI) → game-surface (A2UI) → done
```

`surfaceUpdate` だけでは surface は表示されない。**`beginRendering` とセット**で送ること。

## TrpgSession Surface 優先順位（CRITICAL）

`frontend/apps/web/lib/features/trpg/model/trpg_session_provider.dart`

### resolvePostPagingMode の優先順位ルール

```dart
// ✅ hasSurface が isProcessing より必ず優先される
static NovelDisplayMode resolvePostPagingMode({
  required bool isProcessing,
  required bool hasSurface,
}) {
  if (hasSurface) return NovelDisplayMode.surface;  // ← 最優先
  if (isProcessing) return NovelDisplayMode.processing;
  return NovelDisplayMode.input;
}
```

**なぜ**: auto-advance シナリオで `isProcessing=true` のまま choice turn が完了する場合がある。
`hasSurface=true` はバックエンドが選択肢 surface を送信済みであることを意味するため、処理状態より優先して表示すべき。

### バグ症状（この優先順位が逆の場合）

```
# ログで確認できる症状
_onSurfaceUpdate: SurfaceAdded(game-surface)  ← surface は作成されている
onPagingComplete: resolved → NovelDisplayMode.processing, isProcessing=true, hasSurface=true
← hasSurface=true なのに processing → 選択肢UIが表示されない
```

### onPagingComplete の willAutoContinue チェック

```dart
if (_willAutoContinue) {
  if (_hasSurface) {
    // ✅ choice surface がある場合は auto-continue より優先してsurfaceを表示
    _displayModeNotifier.value = NovelDisplayMode.surface;
    return;
  }
  _displayModeNotifier.value = NovelDisplayMode.processing;
  return;
}
```
