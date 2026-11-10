# A2UI SDK (a2ui_core 0.6 / a2ui_flutter 0.2) - Flutter Generative UI

## Overview

`core_genui` パッケージは A2UI の Dart SDK で Generative UI を描画する。バックエンドが A2UI v0.9 のメッセージを SSE で送り、Flutter 側が Widget に変換する。

- **パッケージ**: `frontend/packages/core/genui/`（パッケージ名 `core_genui`）
- **依存**: `a2ui_core: ^0.6.0`（メッセージ・`MessageProcessor`・データモデル）、`a2ui_flutter: ^0.2.0`（`A2uiSurface`・`ComponentImplementation`・basic catalog）
- **プロトコル**: A2UI v0.9（`createSurface` / `updateComponents` / `updateDataModel` / `deleteSurface`、各メッセージに `"version": "v0.9"`）
- **バックエンド**: `backend-py/app/src/controller/genui_controller.py`（チャット SSE）、`backend-py/app/src/domain/service/genui_bridge_service.py`（ゲーム SSE）

以前は Flutter の `genui` 0.7（A2UI v0.8 の `surfaceUpdate` / `beginRendering`）を使っていた。

## Architecture

```
User Input → GenuiConversation.sendRequest(text)
  → SseContentGenerator.sendRequest()
  → POST /api/genui/chat (Python FastAPI)
  → SSE でストリーム返却
  → SseContentGenerator が AgentToRendererMessage.fromJson() でパース
  → GenuiConversation が MessageProcessor.processMessages() に転送
  → GenuiSurfaceView / A2uiSurface が Flutter Widget をレンダリング
```

## Provider の方針

A2UI の型（`MessageProcessor<ComponentImplementation>`, `GenuiConversation` 等）を返す Provider は **手動定義** している（`@riverpod` アノテーション不使用）。

```dart
// 手動 Provider
final genuiConversationProvider = Provider<GenuiConversation>((ref) { ... });

// riverpod_generator
@Riverpod(keepAlive: true)
SseContentGenerator contentGenerator(Ref ref) { ... }
```

## Core Classes

### SseContentGenerator / GameContentGenerator

SSE でバックエンドと通信するクラス（`core_genui/lib/content_generator/`）。共通のストリーム:

```dart
Stream<AgentToRendererMessage> get a2uiMessageStream;  // A2UI メッセージ
Stream<String> get textResponseStream;                  // テキスト応答
Stream<ContentGeneratorError> get errorStream;          // エラー（core_genui の型）
ValueListenable<bool> get isProcessing;

// SseContentGenerator
Future<void> sendRequest(
  String message, {
  Iterable<GenuiMessage>? history,
  Map<String, Object?>? clientCapabilities,
});

// GameContentGenerator（ゲーム用。sessionId を渡す）
Future<void> sendTurn({required String sessionId, required String inputType, required String inputText, String? authToken});
```

`GameContentGenerator` はさらに `gameStateStream`, `nodesReadyStream`, `doneStream` などゲーム固有のストリームを持つ。

### GenuiConversation

会話ループ（`core_genui/lib/conversation/genui_conversation.dart`）。`SseContentGenerator` と `MessageProcessor` を結合し、ユーザー操作（action）をリクエストとして送り返す。

```dart
final conversation = GenuiConversation(
  contentGenerator: contentGenerator,
  processor: processor,
);

conversation.sendRequest('Hello');
conversation.processor;      // MessageProcessor（GenuiSurfaceView に渡す）
conversation.conversation;   // ValueListenable<List<GenuiMessage>>
conversation.isProcessing;   // ValueListenable<bool>
conversation.dispose();
```

### MessageProcessor（a2ui_core）

surface の状態管理。

```dart
final processor = MessageProcessor<ComponentImplementation>(
  catalogs: [catalog],
  validationConfig: ValidationConfig.relaxed,
  reportErrorsOnly: true, // 不正なメッセージは throw せず model.onError に通知
);

processor.processMessages(messageOrJson);  // AgentToRendererMessage / JSON Map / List
processor.model.getSurface('game-surface'); // SurfaceModel?（未作成なら null）
processor.model.onSurfaceCreated.subscribe((surface) { ... });
processor.model.onSurfaceDeleted.subscribe((surfaceId) { ... });
processor.model.onAction.subscribe((A2uiRendererAction action) { ... });
processor.model.onError.subscribe((A2uiRendererError error) { ... });
processor.dispose();
```

`subscribe` は `Subscription` を返す。dispose 時に `unsubscribe()` する。

### GenuiSurfaceView / A2uiSurface（Widget）

`A2uiSurface(surface: surfaceModel)` は作成済みの `SurfaceModel` を描画する。surfaceId で追従したい場合は `GenuiSurfaceView` を使う（surface が無い間は `defaultBuilder`）。

```dart
GenuiSurfaceView(
  processor: session.processor,
  surfaceId: 'game-surface',
  defaultBuilder: (context) => const SizedBox.shrink(),  // オプション
)
```

### GenuiMessage（Freezed union）

会話履歴の型（`user` / `assistant` / `system`、すべて `.text` を持つ）。`SseContentGenerator` は `user` を `role: 'user'`、それ以外を `role: 'model'` として送る。

### CatalogImplementation / ComponentImplementation

利用可能な UI コンポーネントを定義する。

```dart
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/v0_9/basic_catalog.dart' as v0_9;

// basic catalog（Text, Column, Button など A2UI v0.9 の標準コンポーネント）
final catalog = v0_9.basicCatalog();

// カスタムコンポーネントを追加（catalogId はバックエンドが createSurface で送る ID）
final extended = catalog.derive(
  catalogId: 'https://example.com/my_catalog.json',
  addComponents: [myComponent],
);
```

### AgentToRendererMessage（a2ui_core）

SSE で受信する A2UI メッセージ。

| クラス | 用途 |
|---|---|
| `CreateSurfaceMessage` | surface 作成（`catalogId` 必須） |
| `UpdateComponentsMessage` | コンポーネント追加/更新 |
| `UpdateDataModelMessage` | データモデル更新 |
| `DeleteSurfaceMessage` | surface 削除 |

```dart
final msg = AgentToRendererMessage.fromJson(jsonMap);
```

## Project Files

### core_genui パッケージ構成

```
frontend/packages/core/genui/
├── pubspec.yaml
├── lib/
│   ├── core_genui.dart                              # Barrel export
│   ├── content_generator/
│   │   ├── content_generator_config.dart            # Freezed 設定モデル
│   │   ├── content_generator_error.dart             # errorStream のエラー型
│   │   ├── game_content_generator.dart              # ゲーム用 SSE クライアント
│   │   └── sse_content_generator.dart               # チャット用 SSE クライアント
│   ├── catalog/
│   │   ├── app_catalog_items.dart                   # basic catalog + カスタム
│   │   └── game_catalog_items.dart                  # ゲーム用 VN コンポーネント
│   ├── conversation/
│   │   └── genui_conversation.dart                  # 会話ループ
│   ├── models/
│   │   ├── conversation_state.dart                  # 会話状態（Freezed union）
│   │   └── genui_message.dart                       # メッセージ（Freezed union）
│   ├── providers/
│   │   ├── content_generator_provider.dart          # SseContentGenerator Provider（@riverpod）
│   │   ├── conversation_provider.dart               # GenuiConversation Provider（手動）
│   │   └── surface_provider.dart                    # Surface IDs Provider（手動）
│   └── widgets/
│       ├── genui_chat_surface.dart                  # チャット UI Widget
│       └── genui_surface_view.dart                  # surfaceId で追従する surface Widget
```

### Python バックエンド

```
backend-py/app/src/
├── controller/genui_controller.py         # POST /api/genui/chat (SSE)
├── usecase/genui_usecase.py               # LLM 呼び出し（テキストのみ）
├── domain/service/genui_bridge_service.py # GM 判断 → A2UI v0.9 メッセージ
└── domain/entity/genui.py                 # Pydantic モデル
```

## Usage Patterns

### 基本的な使い方（Widget から）

```dart
import 'package:core_genui/core_genui.dart';

class MyChatPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(genuiConversationProvider);

    return Column(
      children: [
        Expanded(
          child: GenuiSurfaceView(
            processor: conversation.processor,
            surfaceId: 'main-surface',
          ),
        ),
        ElevatedButton(
          onPressed: () => conversation.sendRequest('Create a form'),
          child: const Text('Send'),
        ),
      ],
    );
  }
}
```

### カスタムコンポーネントの追加

`builder` は解決済みのプロパティ（`props`）を受け取る。ユーザー操作は `node.context?.dispatchAction` で送り、`processor.model.onAction` に届く。

```dart
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final customItem = ComponentImplementation(
  name: 'GameScore',
  schema: S.object(
    properties: {
      'score': S.integer(description: 'The player score'),
      'playerName': S.string(description: 'The player name'),
    },
    required: ['score', 'playerName'],
  ),
  builder: (context, node, props, buildChild) {
    return Card(
      child: Text('${props.string('playerName')}: ${props.number('score')}'),
    );
  },
);

final catalog = AppCatalogItems.asCatalog(additionalItems: [customItem]);
```

`schema` はメッセージ処理時に検証される。型が合わないプロパティを含む `updateComponents` は拒否され、`processor.model.onError` に通知される。

### テスト

`MessageProcessor` に JSON を渡し、`GenuiSurfaceView` を `MaterialApp` の下で pump する（例: `frontend/packages/core/genui/test/catalog/game_catalog_items_test.dart`）。

```dart
final processor = MessageProcessor<ComponentImplementation>(
  catalogs: [GameCatalogItems.asCatalog()],
  validationConfig: ValidationConfig.strict,
);
processor.processMessages([
  {'version': 'v0.9', 'createSurface': {'surfaceId': 's', 'catalogId': GameCatalogItems.catalogId}},
  {'version': 'v0.9', 'updateComponents': {'surfaceId': 's', 'components': [
    {'id': 'root', 'component': 'continueButton'},
  ]}},
]);
```

## SSE Protocol (Backend → Frontend)

```
# テキスト応答
data: {"type": "text", "content": "Hello!"}

# A2UI: surface 作成
data: {"version": "v0.9", "createSurface": {"surfaceId": "s1", "catalogId": "<catalog id>"}}

# A2UI: コンポーネント更新（root コンポーネントのプロパティはトップレベル）
data: {"version": "v0.9", "updateComponents": {"surfaceId": "s1", "components": [{"id": "root", "component": "choiceGroup", "choices": [...]}]}}

# A2UI: surface 削除
data: {"version": "v0.9", "deleteSurface": {"surfaceId": "s1"}}

# 完了
data: {"type": "done"}
```

## Environment Variables

```
GENUI_SERVER_URL=http://localhost:8000/api/genui/chat  # SSE エンドポイント
```

`--dart-define` または `env/frontend/local.json` で設定。

## このプロジェクト固有: game-surface パターン（CRITICAL）

TRPGゲームでは `game-surface` という固定の surfaceId を使って選択肢/ボタンを表示する。

### Surface ID 一覧

| surfaceId | 用途 |
|-----------|------|
| `game-surface` | choiceGroup / continueButton / clarifyQuestion / repairConfirm |
| `game-narration` | narrativePanel（ナレーションテキスト） |
| `game-npcs` | npcGallery（NPCキャラクター表示） |

すべて `GameCatalogItems.catalogId` のカタログで作成する。バックエンドの `GAME_CATALOG_ID`（`genui_bridge_service.py`）と一致させること。

### SSE イベント順序（1ターン分）

```
# バックエンドから送信される順序
deleteSurface (game-npcs, game-narration, game-surface) ← 前ターンの surface を削除
nodesReady         ← NodePlayer にノードをロード（SceneNode 配列）
stateUpdate        ← Flame キャンバス更新データ
createSurface + updateComponents (game-npcs)       ← NPC ギャラリー
createSurface + updateComponents (game-narration)  ← ナレーションパネル
createSurface + updateComponents (game-surface)    ← 選択肢/ボタン（これが重要）
done               ← ターン完了
```

A2UI v0.9 では同じ surfaceId の `createSurface` を二度送るとエラーになる。そのため各ターンの最初に `deleteSurface` する。フロントエンドの `_processA2ui`（`trpg_session_provider.dart`）も、既存の surface への `createSurface` を置き換えとして扱う。

`game-surface` の `createSurface` を処理したタイミングで、Flutter 側の `_hasSurface = true` になる。

### _hasSurface と表示モードの連動（CRITICAL）

`game-surface` の A2UI イベントを受信後、ユーザーが全ノードを読み終えた時に
表示モードを `surface` に切り替える。

**ルール**: `hasSurface=true` は `isProcessing=true` より**必ず優先**される。

```dart
// trpg_session_provider.dart の resolvePostPagingMode
static NovelDisplayMode resolvePostPagingMode({
  required bool isProcessing,
  required bool hasSurface,
}) {
  if (hasSurface) return NovelDisplayMode.surface;  // ← 最優先
  if (isProcessing) return NovelDisplayMode.processing;
  return NovelDisplayMode.input;
}
```

この優先順位が逆になると、auto-advance シナリオで choice が表示されないバグが発生する。
詳細は `.claude/skills/trpg-session/SKILL.md` を参照。

### 手動で game-surface を構築するパターン

SSE の A2UI イベントが届かない場合（セッション復元、フォールバック）は、
メッセージを直接 processor に渡せる（`_ensureChoiceSurface`）:

```dart
final version = A2uiProtocolVersion.v0_9.jsonValue;

// 1. createSurface で surface を作成
_processA2ui(CreateSurfaceMessage(
  version: version,
  surfaceId: 'game-surface',
  catalogId: GameCatalogItems.catalogId,
));

// 2. updateComponents で root を定義（必ずセットで送る）
_processA2ui(UpdateComponentsMessage(
  version: version,
  surfaceId: 'game-surface',
  components: [
    {'id': 'root', 'component': 'choiceGroup', 'choices': choices, 'allowFreeInput': true},
  ],
));
```

`createSurface` だけでは何も表示されない。**必ず root を含む `updateComponents` とセット**で送る。
