# Flutter GenUI SDK - カスタムバックエンド統合 調査レポート

## 調査情報
- **調査日**: 2026-02-21
- **調査者**: spec agent

## バージョン情報
- **genui**: v0.7.0 (pub.dev)
- **genui_a2ui**: v0.7.0 (pub.dev)
- **A2UI Protocol**: v0.9 (2025-12-03)
- **Flutter 要件**: >= 3.35.7
- **ステータス**: Highly Experimental (API変更の可能性あり)

---

## 1. GenUI アーキテクチャ概要

GenUI SDK は LLM からの静的テキスト出力を、動的でインタラクティブな Flutter UI に変換するフレームワーク。内部的に A2UI プロトコルを使用。

### パッケージ構成

```
flutter/genui リポジトリ
├── packages/
│   ├── genui               # コアフレームワーク (UI レンダリングエンジン)
│   ├── genui_a2ui           # A2UI プロトコルサポート
│   ├── genai_primitives     # AI 用共通型定義
│   └── json_schema_builder  # JSON Schema バリデーション
```

### 依存関係

```
genui_a2ui → genui → genai_primitives → json_schema_builder
```

---

## 2. ContentGenerator インターフェース

**核心**: GenUI はバックエンド非依存。`ContentGenerator` インターフェースを実装すれば、任意のバックエンドと接続可能。

### API 定義 (genui v0.7.0)

```dart
abstract interface class ContentGenerator {
  // === Properties ===

  /// A2UI メッセージのストリーム (UI 更新命令)
  Stream<A2uiMessage> get a2uiMessageStream;

  /// エラーストリーム
  Stream<ContentGeneratorError> get errorStream;

  /// 処理中フラグ
  ValueListenable<bool> get isProcessing;

  /// テキストレスポンスのストリーム
  Stream<String> get textResponseStream;

  // === Methods ===

  /// メッセージ送信 (会話履歴 + クライアント機能情報をオプションで含む)
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  });

  /// リソース解放
  void dispose();
}
```

### ChatMessage の種類 (sealed class)

```dart
sealed class ChatMessage {
  // 6つの具体型:
  // - UserMessage            (ユーザーからのテキスト入力)
  // - UserUiInteractionMessage (ユーザーの UI 操作)
  // - AiTextMessage          (AI テキスト応答)
  // - AiUiMessage            (AI UI 応答)
  // - InternalMessage        (内部メッセージ)
  // - ToolResponseMessage    (ツール応答)
}
```

### A2uiMessage の種類 (sealed class)

```dart
sealed class A2uiMessage {
  // 4つの具体型:
  // - BeginRendering    (レンダリング開始)
  // - SurfaceUpdate     (Surface の更新)
  // - DataModelUpdate   (データモデル更新)
  // - SurfaceDeletion   (Surface の削除)

  factory A2uiMessage.fromJson(Map<String, dynamic> json);
  static Map<String, dynamic> a2uiMessageSchema(Catalog catalog);
}
```

---

## 3. カスタムバックエンドとの統合方法 (3つの選択肢)

### 選択肢 A: ContentGenerator を直接実装

Python バックエンドが A2UI JSON を生成し、Flutter 側で ContentGenerator を実装して通信する方法。

```dart
class CustomBackendContentGenerator implements ContentGenerator {
  final Uri backendUrl;

  final _a2uiController = StreamController<A2uiMessage>.broadcast();
  final _textController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

  CustomBackendContentGenerator({required this.backendUrl});

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiController.stream;

  @override
  Stream<String> get textResponseStream => _textController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) async {
    _isProcessing.value = true;
    try {
      // Python バックエンドに HTTP/SSE リクエスト
      // レスポンスの JSON を A2uiMessage.fromJson() でパース
      // _a2uiController.add() でストリームに流す
    } catch (e) {
      _errorController.add(ContentGeneratorError(e.toString()));
    } finally {
      _isProcessing.value = false;
    }
  }

  @override
  void dispose() {
    _a2uiController.close();
    _textController.close();
    _errorController.close();
  }
}
```

**メリット**: 完全な制御、A2A プロトコル不要
**デメリット**: A2UI メッセージ生成ロジックを自前実装

### 選択肢 B: genui_a2ui + A2UI サーバー実装

Python バックエンドを A2UI プロトコル準拠のサーバーとして実装し、`A2uiContentGenerator` で接続。

```dart
// Flutter 側 (既存の A2uiContentGenerator を使用)
final contentGenerator = A2uiContentGenerator(
  serverUrl: Uri.parse('http://localhost:8080'),
);

final conversation = GenUiConversation(
  contentGenerator: contentGenerator,
  a2uiMessageProcessor: A2uiMessageProcessor(),
);
```

**メリット**: Flutter 側の実装が最小限
**デメリット**: Python 側で A2A プロトコル + A2UI プロトコルの両方を実装する必要あり

### 選択肢 C: genui_dartantic (マルチプロバイダー)

`genui_dartantic` パッケージを使い、OpenAI/Anthropic/Ollama 等の LLM に直接接続。バックエンド不要。

```dart
final contentGenerator = DartanticContentGenerator(
  provider: Providers.openai,  // or anthropic, ollama, etc.
  catalog: catalog,
  systemInstruction: 'You are a helpful assistant.',
);
```

**対応プロバイダー**: Google, OpenAI, Anthropic, Mistral, Cohere, Ollama

**メリット**: バックエンド不要、即座に使用可能
**デメリット**: LLM を直接呼び出すため、バックエンドロジックの挿入が困難

---

## 4. A2UI プロトコル仕様 (v0.9)

### サーバー → クライアント メッセージ (4種類)

```json
// 1. createSurface - Surface の作成
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "main",
    "catalogId": "standard",
    "theme": { ... }
  }
}

// 2. updateComponents - コンポーネント追加/更新
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "main",
    "components": [
      {
        "id": "root",
        "type": "Column",
        "children": ["header", "content"]
      },
      {
        "id": "header",
        "type": "Text",
        "text": "Hello World"
      },
      {
        "id": "content",
        "type": "Card",
        "children": ["card-text"]
      }
    ]
  }
}

// 3. updateDataModel - データモデル更新
{
  "version": "v0.9",
  "updateDataModel": {
    "surfaceId": "main",
    "updates": [
      {
        "path": "/user/name",
        "value": "John"
      }
    ]
  }
}

// 4. deleteSurface - Surface 削除
{
  "version": "v0.9",
  "deleteSurface": {
    "surfaceId": "main"
  }
}
```

### コンポーネント一覧 (標準カタログ)

| カテゴリ | コンポーネント |
|---------|-------------|
| **レイアウト** | Row, Column, List, Card, Tabs, Divider, Modal |
| **表示** | Text, Image, Icon, Video, AudioPlayer |
| **入力** | Button, CheckBox, TextField, DateTimeInput, ChoicePicker, Slider |

### データバインディング (Dynamic* 型)

```json
// リテラル値
{ "text": "Hello" }

// JSON Pointer パス (データモデルからバインド)
{ "text": "/user/name" }

// 関数呼び出し
{ "text": { "functionCall": "formatString", "args": { "template": "Hello, ${/user/name}!" } } }
```

### トランスポート要件

- 信頼性のある順序付き配信
- メッセージフレーミング (JSONL, WebSocket, SSE)
- サポートされるトランスポート: **A2A, AG-UI, MCP, SSE+JSON-RPC, WebSocket, REST**

---

## 5. Python FastAPI での A2UI サーバー実装

### 方式 1: SSE ストリーミング (最もシンプル)

```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from sse_starlette.sse import EventSourceResponse
import json

app = FastAPI()

async def generate_a2ui_stream(user_message: str):
    """A2UI メッセージをストリームで生成"""

    # 1. Surface 作成
    yield json.dumps({
        "version": "v0.9",
        "createSurface": {
            "surfaceId": "main",
            "catalogId": "standard"
        }
    })

    # 2. LLM を呼び出して UI コンポーネントを生成
    # (ここで Gemini/Claude/OpenAI 等を呼び出す)
    components = await generate_ui_with_llm(user_message)

    yield json.dumps({
        "version": "v0.9",
        "updateComponents": {
            "surfaceId": "main",
            "components": components
        }
    })

    # 3. データモデル更新
    yield json.dumps({
        "version": "v0.9",
        "updateDataModel": {
            "surfaceId": "main",
            "updates": [
                {"path": "/status", "value": "ready"}
            ]
        }
    })

@app.post("/a2ui/stream")
async def stream_a2ui(request: dict):
    return EventSourceResponse(
        generate_a2ui_stream(request.get("message", "")),
        media_type="text/event-stream"
    )
```

### 方式 2: A2A プロトコル準拠サーバー

Google ADK (Agent Development Kit) を使用して A2A プロトコル準拠のサーバーを構築。
`genui_a2ui` パッケージの `A2uiContentGenerator` がそのまま接続可能。

```python
# Google ADK を使用した A2A エージェント
from google.adk.agents import LlmAgent
from google.adk.runners import Runner

agent = LlmAgent(
    model="gemini-2.0-flash",
    name="game_ui_agent",
    instruction=prompt_with_a2ui_schema,
    tools=[get_game_data, update_score],
)

runner = Runner(
    agent=agent,
    app_name="game-ui",
    session_service=InMemorySessionService(),
)
```

### 方式 3: カスタム ContentGenerator + HTTP API

最もフレキシブル。Python バックエンドは通常の REST/SSE API を提供し、Flutter 側で ContentGenerator を実装。

```python
# Python FastAPI 側 - 通常の API
@app.post("/api/generate-ui")
async def generate_ui(request: GameRequest):
    # ゲームロジック処理
    game_state = process_game_logic(request)

    # A2UI JSON を生成 (LLM またはテンプレートベース)
    a2ui_messages = build_a2ui_response(game_state)

    return {
        "text": "ゲームの状態が更新されました",
        "a2ui_messages": a2ui_messages
    }
```

---

## 6. 推奨アプローチ

### このプロジェクトに最適な選択肢

| 要件 | 推奨 |
|------|------|
| Python バックエンドと統合したい | **選択肢 A** (ContentGenerator 直接実装) |
| 標準プロトコルに準拠したい | **選択肢 B** (A2UI サーバー + genui_a2ui) |
| バックエンド不要で素早く試したい | **選択肢 C** (genui_dartantic) |
| Gemini 以外の LLM を使いたい | **選択肢 A** または **選択肢 C** |

### このプロジェクト (Gemini Hackathon Game) への提案

**選択肢 A (ContentGenerator 直接実装)** が最適と考えられる理由:

1. **既存の FastAPI バックエンドとの統合**: プロジェクトに既に `backend-py` があり、そこにゲームロジックを実装できる
2. **柔軟性**: A2A プロトコルの制約を受けず、独自の API 設計が可能
3. **シンプルさ**: SSE で A2UI JSON をストリーミングするだけで実装可能
4. **LLM 選択の自由**: Python 側で Gemini, Claude, OpenAI 等を自由に選択可能

**代替案**: `genui_dartantic` で Gemini に直接接続し、バックエンドは補助的なデータ提供のみにする方式も、Hackathon のスピード感には合致する。

---

## 7. 注意事項

1. **Highly Experimental**: GenUI SDK は実験的ステータス。API 破壊的変更の可能性が高い
2. **Flutter バージョン要件**: >= 3.35.7 (このプロジェクトの Flutter 3.35.6 では不足、アップデート必要)
3. **A2UI v0.9**: プロトコル自体もまだ進化中
4. **genui_a2ui の A2A 依存**: `A2uiContentGenerator` は内部で A2A (Agent-to-Agent) プロトコルを使用。単純な REST/SSE サーバーには直接接続できない可能性あり
5. **カタログ定義必須**: GenUI は事前定義されたウィジェットカタログのみレンダリング可能。任意の UI は生成できない

---

## 参考リンク

- [GenUI GitHub リポジトリ](https://github.com/flutter/genui)
- [GenUI SDK 公式ドキュメント](https://docs.flutter.dev/ai/genui)
- [GenUI コンポーネント解説](https://docs.flutter.dev/ai/genui/components)
- [genui pub.dev](https://pub.dev/packages/genui)
- [genui_a2ui pub.dev](https://pub.dev/packages/genui_a2ui)
- [genui_dartantic pub.dev](https://pub.dev/packages/genui_dartantic)
- [A2UI プロトコル仕様 v0.9](https://a2ui.org/specification/v0.9-a2ui/)
- [A2UI GitHub リポジトリ](https://github.com/google/A2UI)
- [A2UI エージェント開発ガイド](https://a2ui.org/guides/agent-development/)
- [A2UI クイックスタート](https://a2ui.org/quickstart/)
- [A2UI Restaurant Finder サンプル](https://github.com/google/A2UI/tree/main/samples/agent/adk/restaurant_finder)
- [Flutter Blog: Rich and dynamic UIs with GenUI](https://blog.flutter.dev/rich-and-dynamic-user-interfaces-with-flutter-and-generative-ui-178405af2455)
