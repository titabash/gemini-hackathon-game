# Flutter GenUI SDK - API リファレンス調査レポート

## 調査情報
- **調査日**: 2026-02-21
- **調査者**: spec agent

## バージョン情報
- **最新バージョン**: v0.7.0 (2026-02-07 公開)
- **Dart SDK 要件**: `>=3.9.2 <4.0.0`
- **Flutter SDK 要件**: `>=3.35.7 <4.0.0`
- **ステータス**: Alpha (実験的、API 破壊的変更の可能性あり)
- **パブリッシャー**: labs.flutter.dev (verified)
- **ライセンス**: BSD-3-Clause

---

## 破壊的変更 (v0.6.x -> v0.7.0)

v0.7.0 で大規模なクラスリネームが実施された。旧名称はすべて廃止済み:

| 旧名 (v0.6.x) | 新名 (v0.7.0) |
|----------------|---------------|
| `GenUiConversation` | `Conversation` |
| `GenUiController` | `SurfaceController` |
| `GenUiSurface` | `Surface` |
| `GenUiHost` | `SurfaceHost` |
| `GenUiContext` | `SurfaceContext` |
| `GenUiTransport` | `Transport` |
| `GenUiPromptFragments` | `PromptFragments` |
| `GenUiFunctionDeclaration` | `ClientFunction` |
| `GenUiFallback` | `FallbackWidget` |
| `configureGenUiLogging` | `configureLogging` |
| `GenUiManager` | `A2uiMessageProcessor` (v0.6.0) |
| `ChatMessageWidget` | `ChatMessageView` |
| `InternalMessageWidget` | `InternalMessageView` |

**注意**: 多くのオンライン記事やチュートリアルは旧API名 (`GenUiConversation`, `GenUiSurface` 等) を使用しているが、v0.7.0 では使用不可。

---

## パッケージ構成

| パッケージ | バージョン | 用途 |
|-----------|-----------|------|
| `genui` | 0.7.0 | コアフレームワーク |
| `genui_google_generative_ai` | 0.7.0 | Google Gemini API 直接統合 |
| `genui_firebase_ai` | 0.7.0 | Firebase AI Logic 統合 |
| `genui_a2ui` | 0.7.0 | A2UI プロトコルサーバー接続 |
| `genai_primitives` | 0.2.0 | AI 共通型定義 |
| `json_schema_builder` | 0.1.3 | JSON Schema 定義 |

---

## 依存関係 (genui v0.7.0)

```yaml
dependencies:
  collection: ^1.19.1
  flutter: sdk
  flutter_markdown_plus: ^1.0.5
  genai_primitives: ^0.2.0
  intl: ^0.20.2
  json_schema_builder: ^0.1.3
  logging: ^1.3.0
  meta: ^1.17.0
  rxdart: ^0.28.0
  url_launcher: ^6.3.2
  uuid: ^4.4.0
```

---

## インポートパターン

```dart
// コアパッケージ (すべての公開 API をエクスポート)
import 'package:genui/genui.dart';

// JSON Schema 定義用
import 'package:json_schema_builder/json_schema_builder.dart';

// ロギング用
import 'package:logging/logging.dart';

// ContentGenerator 実装パッケージ (1つ選択)
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';
import 'package:genui_a2ui/genui_a2ui.dart';
```

---

## 1. ContentGenerator インターフェース

GenUI のバックエンド通信を抽象化するインターフェース。バックエンド非依存設計の中核。

```dart
abstract interface class ContentGenerator {
  /// A2UI メッセージのストリーム (UI 更新命令)
  Stream<A2uiMessage> get a2uiMessageStream;

  /// エラーストリーム
  Stream<ContentGeneratorError> get errorStream;

  /// 処理中フラグ
  ValueListenable<bool> get isProcessing;

  /// テキストレスポンスのストリーム
  Stream<String> get textResponseStream;

  /// メッセージ送信
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  });

  /// リソース解放
  void dispose();
}
```

### 公式実装

```dart
// Google Gemini API 直接 (プロトタイピング向け)
final cg = GoogleGenerativeAiContentGenerator(
  catalog: catalog,
  systemInstruction: 'You are a helpful assistant.',
  modelName: 'models/gemini-2.5-flash',
  apiKey: 'YOUR_API_KEY', // または GEMINI_API_KEY 環境変数
);

// Firebase AI Logic (本番向け)
final cg = FirebaseAiContentGenerator(
  catalog: catalog,
  systemInstruction: 'You are a helpful assistant.',
  additionalTools: messageProcessor.getTools(),
);

// A2UI サーバー接続 (カスタムバックエンド向け)
final cg = A2uiContentGenerator(
  serverUrl: Uri.parse('http://localhost:8080'),
);
```

### ContentGeneratorError

v0.7.0 で `Exception` 型に変更:

```dart
class ContentGeneratorError implements Exception {
  final String message;
  ContentGeneratorError(this.message);
}
```

---

## 2. Conversation API (旧 GenUiConversation)

会話全体を管理するファサード。ContentGenerator と SurfaceController を統合。

### v0.7.0 API (新しい低レベル API)

```dart
final controller = SurfaceController(
  catalogs: [CoreCatalogItems.asCatalog()],
);

final transport = A2uiTransportAdapter(
  onSend: (ChatMessage message) async {
    // LLM にメッセージを送信
    // レスポンスのチャンクを transport.addChunk() で流す
  },
);

final conversation = Conversation(
  transport: transport,
  controller: controller,
);
```

### イベントリスニング

```dart
conversation.events.listen((event) {
  if (event is ConversationSurfaceAdded) {
    // 新しい Surface が追加された
    final surfaceId = event.surfaceId;
    final definition = event.definition;
  } else if (event is ConversationSurfaceRemoved) {
    // Surface が削除された
  } else if (event is ConversationContentReceived) {
    // テキストコンテンツ受信
    final text = event.text;
  } else if (event is ConversationComponentsUpdated) {
    // コンポーネントが更新された
  }
});
```

### メッセージ送信

```dart
// ユーザーメッセージ送信
conversation.sendRequest(UserMessage.text('Hello'));

// 処理中フラグの監視
conversation.state.addListener(() {
  final isWaiting = conversation.state.value.isWaiting;
});
```

### 旧 API パターン (一部チュートリアルで使用、v0.6.x 互換)

一部のチュートリアルや `genui_firebase_ai` のドキュメントでは旧パターンが記載されている場合がある:

```dart
// 旧パターン (v0.6.x の名前だが構造は類似)
final conversation = GenUiConversation(
  contentGenerator: contentGenerator,
  a2uiMessageProcessor: messageProcessor,
  onSurfaceAdded: (SurfaceAdded update) { ... },
  onSurfaceDeleted: (SurfaceRemoved update) { ... },
);
conversation.sendRequest(UserMessage.text(text));
conversation.dispose();
```

**重要**: v0.7.0 のコアパッケージでは `Conversation` + `A2uiTransportAdapter` パターンが正式 API。ただし `genui_firebase_ai` や `genui_google_generative_ai` は内部的に ContentGenerator を Transport にアダプトしている可能性があるため、使用するサブパッケージのドキュメントを確認すること。

---

## 3. Surface ウィジェット (旧 GenUiSurface)

AI が生成した UI をレンダリングするウィジェット。

```dart
Surface(
  host: conversation.host,   // SurfaceHost インスタンス
  surfaceId: surfaceId,       // String: Surface の一意識別子
)
```

### 使用パターン

```dart
// ListView で複数の Surface をレンダリング
ListView.builder(
  itemCount: surfaceIds.length,
  itemBuilder: (context, index) {
    final id = surfaceIds[index];
    return Surface(
      host: conversation.host,
      surfaceId: id,
    );
  },
)
```

### 内部動作

1. `surfaceId` に対応する Surface 更新をリッスン
2. A2UI メッセージに基づいて自動リビルド
3. ユーザーインタラクション (ボタンクリック等) をキャプチャし、`SurfaceHost.handleUiEvent()` に転送
4. `surfaceId` を自動的にイベントに注入

---

## 4. A2uiMessage フォーマットと種類

AI からクライアントへの命令メッセージ。JSON Lines (JSONL) 形式で送信。

```dart
sealed class A2uiMessage {
  factory A2uiMessage.fromJson(Map<String, dynamic> json);
  static Map<String, dynamic> a2uiMessageSchema(Catalog catalog);
}
```

### 4種類のメッセージ

#### 1. beginRendering - レンダリング開始信号

クライアントに初期レンダリング実行を指示。`surfaceUpdate` の後に送信する必要がある。

```json
{
  "beginRendering": {
    "surfaceId": "main",
    "root": "root-component-id",
    "catalogId": "standard",
    "styles": {}
  }
}
```

#### 2. surfaceUpdate - コンポーネント追加/更新

Surface 内のコンポーネント定義を提供。フラットな隣接リスト形式で階層を表現。

```json
{
  "surfaceUpdate": {
    "surfaceId": "main",
    "components": [
      {
        "id": "greeting",
        "component": {
          "Text": {
            "text": {"literalString": "Hello, World!"},
            "hint": "h1"
          }
        }
      },
      {
        "id": "card",
        "component": {
          "Card": {
            "children": ["card-text"]
          }
        }
      }
    ]
  }
}
```

#### 3. dataModelUpdate - データモデル更新

Surface のデータモデルにデータを挿入/更新。

```json
{
  "dataModelUpdate": {
    "surfaceId": "main",
    "path": "user",
    "contents": [
      {"key": "name", "valueString": "Alice"},
      {"key": "age", "valueNumber": 25},
      {"key": "active", "valueBoolean": true}
    ]
  }
}
```

**値の型指定**: `valueString`, `valueNumber`, `valueBoolean`, `valueMap` (LLM フレンドリーな設計で型推論の曖昧さを回避)

#### 4. deleteSurface - Surface 削除

```json
{
  "deleteSurface": {
    "surfaceId": "main"
  }
}
```

### メッセージ送信順序

推奨シーケンス:
```
surfaceUpdate -> dataModelUpdate -> beginRendering
```

クライアントは `beginRendering` を受信するまで `surfaceUpdate` と `dataModelUpdate` をバッファする。

---

## 5. CatalogItem 定義

AI が使用可能なウィジェットの「語彙」を定義。

### CatalogItem コンストラクタ

```dart
final item = CatalogItem(
  name: 'WidgetName',           // AI が参照する名前
  dataSchema: schema,           // JSON Schema (プロパティ定義)
  widgetBuilder: (CatalogItemContext itemContext) {
    // Flutter ウィジェットを返す
    return Container(...);
  },
);
```

### CatalogItemContext パラメータ

`widgetBuilder` に渡されるコンテキスト:

| パラメータ | 型 | 説明 |
|-----------|-----|------|
| `data` | `Object?` | コンポーネントのプロパティデータ (通常 `Map<String, Object?>`) |
| `id` | `String` | コンポーネントの一意ID |
| `buildChild` | `Function` | 子コンポーネントをビルドする関数 |
| `dispatchEvent` | `Function` | イベントをディスパッチする関数 |
| `context` | `BuildContext` | Flutter の BuildContext |
| `dataContext` | `DataContext` | データモデルへのアクセス |

### データスキーマ定義

`json_schema_builder` パッケージを使用:

```dart
import 'package:json_schema_builder/json_schema_builder.dart';

final schema = S.object(
  properties: {
    'question': S.string(description: 'The question part of a riddle.'),
    'answer': S.string(description: 'The answer part of a riddle.'),
    'difficulty': S.number(description: 'Difficulty level 1-5'),
    'tags': S.array(items: S.string()),
  },
  required: ['question', 'answer'],
);
```

### 完全な CatalogItem 例

```dart
final riddleCard = CatalogItem(
  name: 'RiddleCard',
  dataSchema: S.object(
    properties: {
      'question': S.string(description: 'The question part of a riddle.'),
      'answer': S.string(description: 'The answer part of a riddle.'),
    },
    required: ['question', 'answer'],
  ),
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final question = json['question'] as String;
    final answer = json['answer'] as String;

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(border: Border.all()),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: Theme.of(itemContext.context).textTheme.headlineMedium),
          const SizedBox(height: 8.0),
          Text(answer, style: Theme.of(itemContext.context).textTheme.headlineSmall),
        ],
      ),
    );
  },
);
```

### データバインディング付き CatalogItem

```dart
final holidayCard = CatalogItem(
  name: 'HolidayCard',
  dataSchema: holidayCardSchema,
  widgetBuilder: (itemContext) {
    // DataContext からリアクティブな値を取得
    final name = itemContext.dataContext.subscribeToString(
      itemContext.data['recipientName'] as Map<String, Object?>?,
    );
    final message = itemContext.dataContext.subscribeToString(
      itemContext.data['message'] as Map<String, Object?>?,
    );

    // ValueListenableBuilder でリアクティブにリビルド
    return ValueListenableBuilder<String?>(
      valueListenable: name,
      builder: (context, recipientName, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: message,
          builder: (context, body, _) {
            return Card(
              child: Column(
                children: [
                  Text('Dear ${recipientName ?? ""}'),
                  Text(body ?? ''),
                ],
              ),
            );
          },
        );
      },
    );
  },
);
```

### Catalog 構成

```dart
// コアカタログ (組み込みウィジェット) を取得
final coreCatalog = CoreCatalogItems.asCatalog();

// カスタムアイテムを追加
final customCatalog = coreCatalog.copyWith([riddleCard, holidayCard]);

// SurfaceController に設定 (複数カタログ対応)
final controller = SurfaceController(
  catalogs: [customCatalog],
);
```

### 組み込みコンポーネント (CoreCatalogItems)

| カテゴリ | コンポーネント |
|---------|-------------|
| **レイアウト** | Row, Column, List, Card, Tabs, Divider, Modal |
| **表示** | Text, Image, Icon, Video, AudioPlayer, Heading |
| **入力** | Button, CheckBox, TextField, DateTimeInput, ChoicePicker (MultipleChoice), Slider |

---

## 6. DataModel

集中型のオブザーバブルストア。ウィジェットはこのモデルにバインドし、変更時のみリビルド。

```dart
// DataContext 経由でデータにアクセス
final nameNotifier = itemContext.dataContext.subscribeToString(
  itemContext.data['name'] as Map<String, Object?>?,
);

// ValueListenableBuilder でリアクティブ UI
ValueListenableBuilder<String?>(
  valueListenable: nameNotifier,
  builder: (context, value, child) {
    return Text(value ?? 'Unknown');
  },
);
```

---

## 7. イベントハンドリング

### UiEvent / UserActionEvent

```dart
// UiEvent: ユーザーインタラクションを表すデータオブジェクト
extension type UiEvent.fromMap(JsonMap _json) { ... }

// UserActionEvent: 具体的なユーザーアクション
extension type UserActionEvent.fromMap(JsonMap _json) implements UiEvent {
  UserActionEvent({
    String? surfaceId,
    required String name,
    required String sourceComponentId,
    JsonMap? context,
  });
}
```

### イベントディスパッチ (ウィジェット内)

```dart
widgetBuilder: (itemContext) {
  final buttonData = itemContext.data as Map<String, Object?>;
  final actionData = buttonData['action'] as Map<String, Object?>;
  final actionName = actionData['name'] as String;

  return ElevatedButton(
    onPressed: () {
      // コンテキスト値をデータモデルから解決
      final resolvedContext = resolveContext(
        itemContext.dataContext,
        (actionData['context'] as List<Object?>?) ?? [],
      );

      // イベントをディスパッチ
      itemContext.dispatchEvent(
        UserActionEvent(
          name: actionName,
          sourceComponentId: itemContext.id,
          context: resolvedContext,
        ),
      );
    },
    child: Text('Click'),
  );
},
```

### イベントフロー

```
ユーザー操作
  -> CatalogItem.widgetBuilder 内の dispatchEvent()
  -> Surface が surfaceId を注入
  -> SurfaceHost.handleUiEvent()
  -> A2uiMessageProcessor が userAction JSON にラップ
  -> UserUiInteractionMessage として onSubmit ストリームに emit
  -> Conversation が ContentGenerator に転送
  -> AI が応答 (surfaceUpdate / dataModelUpdate)
  -> UI 自動更新
```

---

## 8. ChatMessage の種類

```dart
sealed class ChatMessage {
  // ユーザーからのテキスト入力
  UserMessage.text('Hello')

  // ユーザーの UI 操作 (自動生成)
  UserUiInteractionMessage.text(jsonString)

  // AI テキスト応答
  AiTextMessage(...)

  // AI UI 応答
  AiUiMessage(...)

  // 内部メッセージ
  InternalMessage(...)

  // ツール応答
  ToolResponseMessage(...)
}
```

---

## 9. ロギング設定

```dart
import 'package:logging/logging.dart';
import 'package:genui/genui.dart';

final logger = configureLogging(level: Level.ALL);

void main() async {
  logger.onRecord.listen((record) {
    debugPrint('${record.loggerName}: ${record.message}');
  });
  // ...
}
```

---

## 10. 基本的な使用例 (完全なセットアップ)

### Google Gemini API 直接接続

```dart
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

// 1. カスタムウィジェット定義
final riddleCard = CatalogItem(
  name: 'RiddleCard',
  dataSchema: S.object(
    properties: {
      'question': S.string(description: 'The question.'),
      'answer': S.string(description: 'The answer.'),
    },
    required: ['question', 'answer'],
  ),
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(json['question'] as String? ?? ''),
            const SizedBox(height: 8),
            Text(json['answer'] as String? ?? ''),
          ],
        ),
      ),
    );
  },
);

// 2. カタログ作成
final catalog = CoreCatalogItems.asCatalog().copyWith([riddleCard]);

// 3. SurfaceController 作成
final controller = SurfaceController(catalogs: [catalog]);

// 4. ContentGenerator 作成
final contentGenerator = GoogleGenerativeAiContentGenerator(
  catalog: catalog,
  systemInstruction: 'You are an expert riddle maker. Use RiddleCard to display riddles.',
  modelName: 'models/gemini-2.5-flash',
  apiKey: 'YOUR_API_KEY',
);

// 5. Transport Adapter 作成
final transport = A2uiTransportAdapter(
  onSend: (message) async {
    await contentGenerator.sendRequest(message);
  },
);

// 6. Conversation 作成
final conversation = Conversation(
  transport: transport,
  controller: controller,
);

// 7. イベントリスニング
conversation.events.listen((event) {
  if (event is ConversationSurfaceAdded) {
    // Surface ID を保存して UI 更新
  }
});

// 8. UI レンダリング
Surface(
  host: conversation.host,
  surfaceId: surfaceId,
)

// 9. メッセージ送信
conversation.sendRequest(UserMessage.text('Tell me a riddle about cats'));

// 10. クリーンアップ
conversation.dispose();
```

### プラットフォーム要件

**iOS/macOS**: ネットワーク通信のエンタイトルメント追加が必要:

```xml
<!-- {ios,macos}/Runner/*.entitlements -->
<dict>
  <key>com.apple.security.network.client</key>
  <true/>
</dict>
```

---

## 注意事項

1. **Alpha ステータス**: API は頻繁に破壊的変更される可能性が高い
2. **Flutter バージョン**: >= 3.35.7 が必要 (Dart >= 3.9.2)
3. **命名の混乱**: オンラインリソースの多くが旧名称 (`GenUiConversation`, `GenUiSurface`, `A2uiMessageProcessor`) を使用。v0.7.0 では `Conversation`, `Surface`, `SurfaceController` が正式名称
4. **サブパッケージ API の差異**: `genui_firebase_ai` のドキュメントは一部旧 API パターン (`GenUiConversation` 等) を使用している場合がある。サブパッケージの実際のエクスポートを確認すること
5. **カタログ制約**: GenUI は事前定義されたウィジェットカタログのみレンダリング可能。任意の UI は生成できない

---

## 参考リンク

- [genui pub.dev](https://pub.dev/packages/genui)
- [genui_google_generative_ai pub.dev](https://pub.dev/packages/genui_google_generative_ai)
- [genui_firebase_ai pub.dev](https://pub.dev/packages/genui_firebase_ai)
- [genui_a2ui pub.dev](https://pub.dev/packages/genui_a2ui)
- [GenUI SDK 公式ドキュメント](https://docs.flutter.dev/ai/genui)
- [GenUI コンポーネント解説](https://docs.flutter.dev/ai/genui/components)
- [GenUI Get Started](https://docs.flutter.dev/ai/genui/get-started)
- [GenUI Input and Events](https://docs.flutter.dev/ai/genui/input-events)
- [GenUI GitHub リポジトリ](https://github.com/flutter/genui)
- [GenUI CHANGELOG](https://pub.dev/packages/genui/changelog)
- [A2UI プロトコル メッセージリファレンス](https://a2ui.org/reference/messages/)
- [A2UI 仕様 v0.8](https://a2ui.org/specification/v0.8-a2ui/)
- [Flutter Blog: Rich and dynamic UIs with GenUI](https://blog.flutter.dev/rich-and-dynamic-user-interfaces-with-flutter-and-generative-ui-178405af2455)
- [freeCodeCamp: GenUI チュートリアル](https://www.freecodecamp.org/news/how-to-use-genui-in-flutter-to-build-dynamic-ai-driven-interfaces/)
