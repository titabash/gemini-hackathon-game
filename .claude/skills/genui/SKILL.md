# genui SDK (v0.7.0) - Flutter Generative UI

## Overview

genui は Flutter 公式の Generative UI SDK（Alpha）。LLM が A2UI プロトコルで Flutter Widget を動的生成する。

- **パッケージ**: `frontend/packages/core/genui/`
- **依存**: `genui: ^0.7.0`（pub.dev / labs.flutter.dev）
- **バックエンド**: `backend-py/app/src/controller/genui_controller.py`（SSE エンドポイント）

## Architecture

```
User Input → SseContentGenerator.sendRequest()
  → POST /api/genui/chat (Python FastAPI)
  → LLM が A2UI JSON を生成
  → SSE でストリーム返却
  → SseContentGenerator が A2uiMessage.fromJson() でパース
  → GenUiConversation が A2uiMessageProcessor に転送
  → GenUiSurface が Flutter Widget をレンダリング
```

## CRITICAL: genui の型は riverpod_generator 非対応

genui の型（`GenUiConversation`, `A2uiMessageProcessor` 等）は riverpod_generator の
コード生成と互換性がない（`InvalidTypeException` が発生する）。

**対処法**: genui 関連の Provider は **手動定義** する（`@riverpod` アノテーション不使用）。

```dart
// ✅ 手動 Provider（genui の型を返す場合）
final genuiConversationProvider = Provider<GenUiConversation>((ref) { ... });

// ✅ riverpod_generator OK（genui の型を返さない場合）
@Riverpod(keepAlive: true)
ContentGenerator contentGenerator(Ref ref) { ... }  // interface は OK
```

## Core Classes（実際の API）

### ContentGenerator（abstract interface）

`package:genui/genui.dart` からエクスポート。カスタム実装が必要。

```dart
abstract interface class ContentGenerator {
  Stream<A2uiMessage> get a2uiMessageStream;
  Stream<String> get textResponseStream;
  Stream<ContentGeneratorError> get errorStream;
  ValueListenable<bool> get isProcessing;

  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  });

  void dispose();
}
```

**本プロジェクトの実装**: `SseContentGenerator`（`core_genui/lib/content_generator/sse_content_generator.dart`）

### GenUiConversation

会話ループのファサード。`ContentGenerator` と `A2uiMessageProcessor` を結合。

```dart
final conversation = GenUiConversation(
  contentGenerator: contentGenerator,      // 必須
  a2uiMessageProcessor: processor,         // 必須
  onSurfaceAdded: (update) { ... },        // オプション
  onSurfaceUpdated: (update) { ... },      // オプション
  onSurfaceDeleted: (update) { ... },      // オプション
  onTextResponse: (text) { ... },          // オプション
  onError: (error) { ... },               // オプション
);

// 主要 API
conversation.sendRequest(UserMessage.text('Hello'));
conversation.host;           // GenUiHost（GenUiSurface に渡す）
conversation.conversation;   // ValueListenable<List<ChatMessage>>
conversation.isProcessing;   // ValueListenable<bool>
conversation.dispose();
```

### A2uiMessageProcessor

UI サーフェスの状態管理。`GenUiHost` インターフェースを実装。

```dart
final processor = A2uiMessageProcessor(catalogs: [catalog]);

// 主要 API
processor.surfaceUpdates;     // Stream<GenUiUpdate>（SurfaceAdded/Updated/Removed）
processor.surfaces;           // Map<String, ValueNotifier<UiDefinition?>>
processor.catalogs;           // Iterable<Catalog>
processor.handleMessage(msg); // A2uiMessage を処理
processor.dispose();
```

### GenUiSurface（Widget）

A2UI 定義から Flutter Widget を動的に構築する。

```dart
GenUiSurface(
  host: conversation.host,    // GenUiHost（必須）
  surfaceId: 'surface-123',   // String（必須）
  defaultBuilder: (context) => const Text('Loading...'),  // オプション
)
```

### ChatMessage（sealed class）

会話メッセージの型階層。**`ChatMessage` 自体に `.text` getter はない**。

| サブクラス | 用途 | `.text` getter |
|---|---|---|
| `UserMessage` | ユーザーメッセージ | あり |
| `AiTextMessage` | AI テキスト応答 | あり |
| `UserUiInteractionMessage` | UI 操作メッセージ | あり |
| `InternalMessage` | 内部メッセージ | あり |
| `AiUiMessage` | AI が生成した UI | なし（`definition`, `surfaceId`） |
| `ToolResponseMessage` | ツール結果 | なし（`results`） |

**テキスト抽出にはパターンマッチが必要**:

```dart
String extractText(ChatMessage message) {
  return switch (message) {
    UserMessage(:final text) => text,
    AiTextMessage(:final text) => text,
    UserUiInteractionMessage(:final text) => text,
    InternalMessage(:final text) => text,
    AiUiMessage() => '',
    ToolResponseMessage() => '',
  };
}
```

**メッセージ作成**:

```dart
UserMessage.text('Hello');           // テキストメッセージ
UserMessage([TextPart('Hello'), ImagePart.fromUrl(uri, mimeType: 'image/png')]);  // マルチモーダル
```

### Catalog / CatalogItem

利用可能な UI コンポーネントを定義。

```dart
// コアカタログ（標準 Widget セット）
final catalog = CoreCatalogItems.asCatalog();

// カスタム項目を追加
final extendedCatalog = catalog.copyWith([
  CatalogItem(
    name: 'MyCustomWidget',
    dataSchema: S.object(properties: { ... }),
    widgetBuilder: (context) => MyCustomWidget(...),
  ),
]);

// 利用可能なコアWidget:
// button, card, checkBox, column, dateTimeInput, divider,
// icon, image, list, modal, multipleChoice, row, slider,
// tabs, text, textField, video, audioPlayer
```

### A2uiMessage（sealed class）

SSE で受信する A2UI プロトコルメッセージ。

| サブクラス | 用途 |
|---|---|
| `SurfaceUpdate` | コンポーネント追加/更新 |
| `BeginRendering` | レンダリング開始（root 指定） |
| `DataModelUpdate` | データモデル更新 |
| `SurfaceDeletion` | サーフェス削除 |

```dart
final msg = A2uiMessage.fromJson(jsonMap);
```

### GenUiUpdate（sealed class）

サーフェス変更イベント。`A2uiMessageProcessor.surfaceUpdates` から emit。

```dart
switch (update) {
  case SurfaceAdded(:final surfaceId, :final definition):
    // 新しいサーフェスが追加された
  case SurfaceUpdated(:final surfaceId, :final definition):
    // 既存サーフェスが更新された
  case SurfaceRemoved(:final surfaceId):
    // サーフェスが削除された
}
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
│   │   └── sse_content_generator.dart               # ContentGenerator 実装（SSE）
│   ├── catalog/
│   │   └── app_catalog_items.dart                   # CoreCatalog + カスタム
│   ├── models/
│   │   ├── conversation_state.dart                  # 会話状態（Freezed union）
│   │   └── genui_message.dart                       # メッセージラッパー（Freezed union）
│   ├── providers/
│   │   ├── content_generator_provider.dart          # ContentGenerator Provider（@riverpod OK）
│   │   ├── conversation_provider.dart               # GenUiConversation Provider（手動）
│   │   └── surface_provider.dart                    # Surface IDs Provider（手動）
│   └── widgets/
│       └── genui_chat_surface.dart                  # チャット UI Widget
```

### Python バックエンド

```
backend-py/app/src/
├── controller/genui_controller.py   # POST /api/genui/chat (SSE)
├── usecase/genui_usecase.py         # LLM 呼び出し + A2UI メッセージ生成
└── domain/entity/genui.py           # Pydantic モデル
```

## Usage Patterns

### 基本的な使い方（Widget から）

```dart
import 'package:core_genui/core_genui.dart';
import 'package:genui/genui.dart';

class MyChatPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(genuiConversationProvider);

    return Column(
      children: [
        // サーフェス表示
        Expanded(
          child: GenUiSurface(
            host: conversation.host,
            surfaceId: 'main-surface',
          ),
        ),
        // メッセージ送信
        ElevatedButton(
          onPressed: () {
            conversation.sendRequest(UserMessage.text('Create a form'));
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}
```

### カスタム CatalogItem の追加

```dart
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final customItem = CatalogItem(
  name: 'GameScore',
  dataSchema: S.object(
    properties: {
      'score': S.integer(description: 'The player score'),
      'playerName': S.string(description: 'The player name'),
    },
    required: ['score', 'playerName'],
  ),
  widgetBuilder: (CatalogItemContext ctx) {
    final data = ctx.data as Map<String, dynamic>;
    return Card(
      child: Text('${data['playerName']}: ${data['score']}'),
    );
  },
);

// AppCatalogItems に追加
final catalog = AppCatalogItems.asCatalog(additionalItems: [customItem]);
```

### テスト（FakeContentGenerator）

```dart
import 'package:genui/test.dart';

final fakeGenerator = FakeContentGenerator();

// メッセージ送信のテスト
fakeGenerator.sendRequest(UserMessage.text('Hello'));
expect(fakeGenerator.sendRequestCallCount, 1);
expect(fakeGenerator.lastMessage, isA<UserMessage>());

// A2UI メッセージの注入
fakeGenerator.addA2uiMessage(
  SurfaceUpdate(surfaceId: 'test', components: [...]),
);

// テキスト応答の注入
fakeGenerator.addTextResponse('Hello from AI');
```

## SSE Protocol (Backend → Frontend)

バックエンドは以下の形式で SSE メッセージを送信:

```
# テキスト応答
data: {"type": "text", "content": "Hello!"}

# A2UI メッセージ（サーフェス更新）
data: {"surfaceUpdate": {"surfaceId": "s1", "components": [...]}}

# A2UI メッセージ（レンダリング開始）
data: {"beginRendering": {"surfaceId": "s1", "root": "root"}}

# A2UI メッセージ（サーフェス削除）
data: {"deleteSurface": {"surfaceId": "s1"}}

# 完了
data: [DONE]
```

## Environment Variables

```
GENUI_SERVER_URL=http://localhost:8000/api/genui/chat  # SSE エンドポイント
```

`--dart-define` または `env/frontend/local.json` で設定。

## Prompt Utilities

```dart
import 'package:genui/genui.dart';

// 基本チャットプロンプト
final prompt = GenUiPromptFragments.basicChat;

// Tool 定義をカタログから生成
final declaration = catalogToFunctionDeclaration(
  catalog, 'surfaceUpdate', 'Updates a UI surface',
);

// Tool call をパース
final parsed = parseToolCall(toolCall, 'surfaceUpdate');
```
