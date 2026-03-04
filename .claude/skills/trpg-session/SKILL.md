# TrpgSession Architecture

このプロジェクトのビジュアルノベル/TRPGセッション管理の実装ガイド。

- **実装**: `frontend/apps/web/lib/features/trpg/model/trpg_session_provider.dart`
- **クラス**: `TrpgSessionNotifier`（Riverpod `Notifier`）

## アーキテクチャ概要

```
Backend (Python FastAPI)
  → SSE stream (nodesReady, stateUpdate, a2ui events, done)
  ↓
TrpgSessionNotifier
  ├── NodePlayer          # SceneNode を1つずつ表示管理
  ├── A2uiMessageProcessor (gameProcessorProvider)  # game-surface 管理
  ├── _isProcessingNotifier   # バックエンド処理中フラグ
  ├── _hasSurface             # game-surface が準備済みフラグ
  ├── _willAutoContinue       # 自動進行フラグ
  └── _displayModeNotifier    # 現在の表示モード
```

## 表示モード（NovelDisplayMode）

| モード | 意味 |
|--------|------|
| `paging` | ユーザーが節を読み進めている |
| `processing` | バックエンド処理待ち |
| `surface` | genui surface（choiceGroup など）表示中 |
| `input` | テキスト入力待ち |

## CRITICAL: resolvePostPagingMode の優先順位

```dart
static NovelDisplayMode resolvePostPagingMode({
  required bool isProcessing,
  required bool hasSurface,
}) {
  // ✅ hasSurface が isProcessing より優先
  if (hasSurface) return NovelDisplayMode.surface;  // ← 最優先
  if (isProcessing) return NovelDisplayMode.processing;
  return NovelDisplayMode.input;
}
```

**なぜこの優先順位か**:
- `hasSurface=true` はバックエンドが choiceGroup などの表示可能な Surface を既に送信済みであることを意味する
- `isProcessing=true` はバックエンドがまだ処理中であることを意味するが、Surface が準備済みなら即表示すべき
- この逆順（`isProcessing` 優先）にすると、auto-advance シナリオで choice が永遠に表示されない

### バグパターン（発生条件）

以下の条件が重なると choice が表示されない：

1. **auto-advance モード**（複数ターンがバッファリングされ自動再生）
2. **最後のターンが `decision_type=choice`**
3. `_isProcessingNotifier.value = true` のまま（auto-advance パイプライン中）

ログで確認できる症状：
```
onPagingComplete: replaying next buffered turn  ← 複数回
_onSurfaceUpdate: SurfaceAdded(game-surface)    ← surface は作成されている
onPagingComplete: resolved → NovelDisplayMode.processing, isProcessing=true, hasSurface=true
← hasSurface=true なのに processing になっている → BUG
```

## `_hasSurface` フラグ

```dart
bool _hasSurface = false;

// ✅ game-surface の SurfaceAdded/Updated で true に設定
void _onSurfaceUpdate(GenUiUpdate update) {
  switch (update) {
    case SurfaceAdded(:final surfaceId):
      if (surfaceId == 'game-surface') _hasSurface = true;
    case SurfaceRemoved(:final surfaceId):
      if (surfaceId == 'game-surface') _hasSurface = false;
    // ...
  }
}

// ✅ sendTurn() でリセット（新しいターン開始時）
void sendTurn(...) {
  _hasSurface = false;
  // ...
}
```

## NodePlayer - SceneNode の逐次表示

```dart
// NodePlayer が SceneNode を1つずつ管理
final nodePlayer = NodePlayer();

// 1. nodesReady イベントでノードをロード
nodePlayer.load(sceneNodes);

// 2. advancePaging() が呼ばれるたびに1ノード進む
void advancePaging() {
  if (_useNodePlayer) {
    final advanced = nodePlayer.advance();
    if (advanced) {
      _applyNodeVisualState(nodePlayer.currentNode.value);
      _saveCurrentNodeIndex(nodePlayer.currentIndex);
      // choice ノードに達したらページング完了
      if (nodePlayer.currentNode.value?.type == 'choice') {
        if (!_hasSurface) {
          // フォールバック: A2UI 未受信時はノードデータから surface を再構築
          final choices = nodePlayer.currentNode.value!.choices;
          if (choices != null && choices.isNotEmpty) {
            _ensureChoiceSurface(choices);
          }
        }
        onPagingComplete();
      }
    } else {
      onPagingComplete();
    }
  }
}
```

## バッファリングターン再生（`_willAutoContinue`）

auto-advance モードでは複数のバックエンドターンのSSEイベントをバッファリングして順次再生する。

```dart
// バッファリング中の判定
bool _bufferIncomingTurnEvents = false;
bool _replayingBufferedTurnEvents = false;
List<TurnStreamEvent> _bufferedTurnEvents = [];

// 次のバッファリングターンを再生
bool _replayNextBufferedTurn() {
  if (_bufferedTurnEvents.isEmpty) return false;
  _bufferIncomingTurnEvents = false;
  _replayingBufferedTurnEvents = true;
  while (_bufferedTurnEvents.isNotEmpty) {
    final event = _bufferedTurnEvents.removeAt(0);
    _applyTurnStreamEvent(event);
    if (event.kind == _TurnStreamEventKind.done) break;  // 1ターン分で停止
  }
  _replayingBufferedTurnEvents = false;
  return true;
}
```

### `onPagingComplete` の `_willAutoContinue` 処理

```dart
void onPagingComplete() {
  if (!_replayingBufferedTurnEvents && _replayNextBufferedTurn()) {
    Logger.debug('onPagingComplete: replaying next buffered turn');
    return;
  }
  if (_willAutoContinue) {
    if (_hasSurface) {
      // ✅ choice surface がある場合は auto-continue より優先してsurfaceを表示
      Logger.debug('onPagingComplete: willAutoContinue but hasSurface, showing surface');
      _bufferIncomingTurnEvents = false;
      _displayModeNotifier.value = NovelDisplayMode.surface;
      return;
    }
    Logger.debug('onPagingComplete: willAutoContinue, showing processing');
    _bufferIncomingTurnEvents = false;
    _displayModeNotifier.value = NovelDisplayMode.processing;
    return;
  }
  // ...
  final mode = resolvePostPagingMode(
    isProcessing: _isProcessingNotifier.value,
    hasSurface: _hasSurface,
  );
  _displayModeNotifier.value = mode;
}
```

## SSE イベントフロー（バックエンド → フロントエンド）

```
# 1ターンのイベント順序
nodesReady         ← NodePlayer にノードをロード
stateUpdate        ← Flame/UI の状態更新
a2ui: game-npcs    ← NPC ギャラリー（surfaceUpdate + beginRendering）
a2ui: game-narration ← ナレーションパネル（surfaceUpdate + beginRendering）
a2ui: game-surface ← 選択肢/ボタン（surfaceUpdate + beginRendering）← _hasSurface=true に
done               ← ターン完了

# _hasSurface が true になるタイミング
_onSurfaceUpdate(SurfaceAdded('game-surface')) 受信時
= surfaceUpdate + beginRendering の両方受信後
```

## `_ensureChoiceSurface` - 復旧シナリオ用フォールバック

SSE の `game-surface` A2UI イベントを受信できなかった場合（セッション復元時など）、
NodePlayer の choice ノードデータから直接 surface を再構築する。

```dart
void _ensureChoiceSurface(List<Map<String, dynamic>> choices) {
  if (choices.isEmpty) return;
  final proc = _ref.read(gameProcessorProvider);
  // surfaceUpdate で surface を定義
  proc.handleMessage(A2uiMessage.fromJson({
    'surfaceUpdate': {
      'surfaceId': 'game-surface',
      'components': [{
        'id': 'root',
        'component': {
          'choiceGroup': {'choices': choices, 'allowFreeInput': true},
        },
      }],
    },
  }));
  // beginRendering で表示を開始
  proc.handleMessage(A2uiMessage.fromJson({
    'beginRendering': {'surfaceId': 'game-surface', 'root': 'root'},
  }));
  _hasSurface = true;  // フラグを手動で立てる
}
```

## セッション復元（`_restoreChoiceSurface`）

読み込み途中のセッションを復元する際、choice ノードの surface を再構築する。

```dart
void _restoreChoiceSurface(Map<String, dynamic> output) {
  final decisionType = output['decision_type'] as String?;
  if (decisionType != 'choice') return;
  // nodes の最後の choice ノードを探す
  final rawNodes = output['nodes'] as List<dynamic>?;
  final lastNode = rawNodes?.isNotEmpty == true
      ? rawNodes!.last as Map<String, dynamic>?
      : null;
  final choices = lastNode?['type'] == 'choice'
      ? lastNode!['choices'] as List<dynamic>?
      : null;
  if (choices != null && choices.isNotEmpty) {
    _ensureChoiceSurface(choices.cast<Map<String, dynamic>>());
  }
}
```

**注意**: 旧実装（ADK 前）は `output['choices']` を参照していたが、ADK 導入後は `output['nodes'][-1]['choices']` を参照する必要がある。

## デバッグのポイント

### choice が表示されない場合のチェックリスト

1. **ログ確認**: `_onSurfaceUpdate: SurfaceAdded(game-surface)` が出ているか？
   - 出ていない → バックエンドの `genui_bridge_service.py` の `_build_surface_properties` を確認
   - 特に `decision.nodes` のアクセスを確認（`decision.choices` は存在しない）

2. **ログ確認**: `onPagingComplete: resolved → NovelDisplayMode.processing, isProcessing=true, hasSurface=true` が出ていないか？
   - 出ている → `resolvePostPagingMode` の優先順位を確認（`hasSurface` が最優先であるべき）

3. **auto-advance シナリオかどうか確認**:
   - `onPagingComplete: replaying next buffered turn` が複数回出ている場合は auto-advance
   - `_willAutoContinue` チェックが `_hasSurface` より先に評価されていないか確認

### テスト

```dart
// resolvePostPagingMode のテスト（trpg_session_provider_test.dart）
test('returns surface when isProcessing=true and hasSurface=true', () {
  // hasSurface=true は isProcessing より優先される
  final result = TrpgSessionNotifier.resolvePostPagingMode(
    isProcessing: true,
    hasSurface: true,
  );
  expect(result, NovelDisplayMode.surface);
});
```
