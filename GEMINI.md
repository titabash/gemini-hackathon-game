# Flutter TRPG Game - Gemini CLI Instructions

このプロジェクトは Flutter + Python FastAPI + Google ADK を使用した TRPG ゲームアプリです。

## 技術スタック

| Layer | Technology |
|-------|------------|
| Frontend | Flutter 3.35.6, Dart 3.5, Melos monorepo |
| State Management | Riverpod (riverpod_generator), Flutter Hooks |
| Navigation | GoRouter |
| Architecture | Feature Sliced Design (FSD) |
| Data Models | Freezed (immutable, json_serializable) |
| i18n | slang (type-safe, en/ja) |
| Game Engine | Flame 1.35.1, flame_riverpod 5.5.2 |
| Generative UI | genui 0.7.0 (A2UI Protocol, SSE) |
| GM Agent | Google ADK (output_schema=GmDecisionResponse) |
| Backend | FastAPI (Python), Supabase Edge Functions (Deno) |
| Database | PostgreSQL, Drizzle ORM, Supabase |

## 開発コマンド（MANDATORY: 必ず Makefile を使用）

```bash
make frontend          # Flutter Web 開発サーバー起動
make frontend-generate # コード生成（Freezed, Riverpod, slang）
make frontend-test     # Flutter テスト実行
make check-quality     # 全品質チェック
make fix-format        # 全コード自動フォーマット
make test-all          # 全テスト実行
make migrate-dev       # DB マイグレーション（承認必須）
```

**直接 `flutter`, `dart`, `melos` コマンドを実行しない。必ず `make` コマンドを使用すること。**

## CRITICAL: Google ADK GM Agent パターン

GM エージェントは **Google ADK** を使用（`backend-py/app/src/infra/adk_gm_client.py`）。

### 選択肢アクセス（ADK 導入後）

```python
# ✅ 正しい方法: decision.nodes の choice ノードを参照
choice_node = next(
    (n for n in reversed(decision.nodes) if n.type == "choice" and n.choices),
    None,
)

# ❌ 禁止: decision.choices は ADK 後に存在しない
choices = decision.choices  # AttributeError
```

### ADK セットアップ

```python
from google.adk.agents import LlmAgent
from google.adk.models.google_llm import Gemini
from google.adk.runners import Runner
from google.adk.sessions import DatabaseSessionService

agent = LlmAgent(
    name="gm_agent",
    model=Gemini(model="gemini-3-flash-preview"),
    instruction=GM_SYSTEM_PROMPT,
    output_schema=GmDecisionResponse,  # Pydantic 直接指定
    # use_interactions_api=True は禁止（構造化出力が壊れる）
)
runner = Runner(
    agent=agent,
    app_name="gm",
    session_service=DatabaseSessionService(
        asyncpg_url,
        connect_args={"server_settings": {"search_path": "adk"}},  # adk スキーマに隔離
    ),
    auto_create_session=True,
)
```

## CRITICAL: TrpgSession Surface 優先順位

`frontend/apps/web/lib/features/trpg/model/trpg_session_provider.dart`

`resolvePostPagingMode` では `hasSurface=true` が `isProcessing=true` より**必ず優先**される：

```dart
static NovelDisplayMode resolvePostPagingMode({
  required bool isProcessing,
  required bool hasSurface,
}) {
  if (hasSurface) return NovelDisplayMode.surface;  // ← 最優先
  if (isProcessing) return NovelDisplayMode.processing;
  return NovelDisplayMode.input;
}
```

**理由**: auto-advance シナリオで `isProcessing=true` のまま choice が完了する場合がある。
`hasSurface=true` = バックエンドが選択肢 surface を送信済み → 即表示すべき。

この優先順位が逆だと、auto-advance 中の choice UI が永遠に表示されないバグが発生する。

## CRITICAL: genui game-surface パターン

```
# SSE イベント順序（1ターン分）
nodesReady → stateUpdate → game-npcs → game-narration → game-surface → done
```

| surfaceId | 用途 |
|-----------|------|
| `game-surface` | choiceGroup / continueButton / clarifyQuestion |
| `game-narration` | narrativePanel |
| `game-npcs` | npcGallery |

**`surfaceUpdate` + `beginRendering` は必ずセットで送ること。**

## アーキテクチャ原則

### Feature Sliced Design (FSD)

```
lib/
├── app/           # アプリ設定
├── pages/         # ルートレベルページ
├── features/      # 機能モジュール
│   └── trpg/
│       ├── api/   # SSE クライアント
│       ├── model/ # TrpgSessionNotifier, NodePlayer
│       └── ui/    # ビジュアルノベル UI
├── entities/      # 共有エンティティ
└── shared/        # 共有ユーティリティ
```

### Riverpod Provider ルール

- `riverpod_generator` を使用（`@riverpod` アノテーション）
- genui 型（`GenUiConversation` 等）は riverpod_generator 非対応 → 手動 Provider 定義

### データモデル（Freezed）

```dart
@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    // ...
  }) = _MyModel;
  factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
}
```

コード生成後: `make frontend-generate`

## Python Backend ルール

- **型アノテーション必須**（mypy strict）
- **McCabe 複雑度 ≤ 3**（関数を小さく保つ）
- **SQLModel は同期のみ**（async SQLModel は未対応）
- **ロギング**: `src/util/logging.py` の `get_logger(__name__)` を使用（`print()` 禁止）
- **LLM クライアント**: 原則 LangChain。GM エージェントのみ ADK（理由: structured output）

## テスト方針（TDD 必須）

1. テストを先に書く（Red）
2. 最小実装でテストを通す（Green）
3. リファクタリング（Refactor）
4. `make frontend-test` で全テストパスを確認してから作業完了

## 多言語対応（i18n 必須）

すべてのユーザー向けテキストは slang を使用：

```dart
// ✅ 翻訳キーを使用
Text(t.common.save)

// ❌ ハードコード禁止
Text('Save')
```

翻訳ファイル: `frontend/packages/core/i18n/lib/translations/{en,ja}.i18n.json`
