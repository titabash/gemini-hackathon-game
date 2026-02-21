# Flame Game Engine (v1.35.1) + flame_riverpod (v5.5.2)

## Overview

Flame は Flutter 公式ゲームエンジン（Flutter Favorite 認定）。flame_riverpod で Riverpod との統合を提供。

- **パッケージ**: `frontend/packages/core/game/`
- **依存**: `flame: ^1.35.1`, `flame_riverpod: ^5.5.2`

## Architecture

```
FlameGame (BaseGame)
  ├── RiverpodGameMixin         # Riverpod Provider へのアクセス
  ├── ValueNotifier<GameState>  # Riverpod へのステートブリッジ
  └── Component Tree            # Flame のコンポーネントツリー

RiverpodAwareGameWidget         # GameWidget + Riverpod 統合
  └── GlobalKey 必須            # ← 重要: required パラメータ
```

## CRITICAL: RiverpodAwareGameWidget の key

`RiverpodAwareGameWidget` は `GlobalKey<RiverpodAwareGameWidgetState>` が **required** パラメータ。

```dart
// ✅ 正しい使い方
class _GameContainerState extends State<GameContainer> {
  final _key = GlobalKey<RiverpodAwareGameWidgetState<BaseGame>>();

  @override
  Widget build(BuildContext context) {
    return RiverpodAwareGameWidget<BaseGame>(
      key: _key,        // ← 必須
      game: widget.game,
    );
  }
}

// ❌ key なしはコンパイルエラー
RiverpodAwareGameWidget<BaseGame>(game: game);  // Error!
```

## Core Classes

### BaseGame（プロジェクト定義）

`FlameGame` + `RiverpodGameMixin` を拡張した基底クラス。

```dart
// frontend/packages/core/game/lib/engine/base_game.dart
class BaseGame extends FlameGame with RiverpodGameMixin {
  final ValueNotifier<GameState> gameState;
  // play(), pause(), endGame(), reportError() メソッド
}
```

### GameState（Freezed union）

```dart
GameState.initial()
GameState.loading(message: 'Loading...')
GameState.playing()
GameState.paused()
GameState.gameOver(score: 100, metadata: {...})
GameState.error(message: 'Error', error: exception)
```

### GameContainer（Widget）

`ClipRect` + `RiverpodAwareGameWidget` のラッパー。`StatefulWidget`（GlobalKey 管理のため）。

```dart
GameContainer(
  game: myGame,
  overlayBuilderMap: { 'pause': (ctx, game) => PauseMenu() },
  initialActiveOverlays: ['hud'],
  loadingBuilder: (ctx) => CircularProgressIndicator(),
  errorBuilder: (ctx, error) => Text('Error: $error'),
  backgroundBuilder: (ctx) => Container(color: Colors.black),
)
```

## Project Files

```
frontend/packages/core/game/
├── pubspec.yaml
├── lib/
│   ├── core_game.dart                    # Barrel export
│   ├── engine/
│   │   ├── base_game.dart                # FlameGame + RiverpodGameMixin
│   │   └── game_config.dart              # Freezed 設定
│   ├── models/
│   │   ├── game_state.dart               # Freezed union（ゲーム状態）
│   │   └── game_event.dart               # Freezed union（ゲームイベント）
│   ├── providers/
│   │   ├── game_provider.dart            # FlameGame インスタンス管理
│   │   └── game_state_provider.dart      # ステートブリッジ（Stream）
│   └── widgets/
│       └── game_container.dart           # GameWidget ラッパー
```

## Usage Patterns

### カスタムゲームの作成

```dart
import 'package:core_game/core_game.dart';

class MyGame extends BaseGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    play();  // ゲーム開始
    // コンポーネントを追加
    add(MyPlayer());
    add(MyBackground());
  }

  @override
  void update(double dt) {
    super.update(dt);
    // ゲームロジック
  }
}
```

### Riverpod からゲーム状態を監視

```dart
@riverpod
Stream<GameState> gameStateStream(Ref ref) {
  final game = ref.watch(gameInstanceProvider);
  return game.gameState.toStream();
}

// Widget 側
final stateAsync = ref.watch(gameStateStreamProvider);
stateAsync.when(
  data: (state) => switch (state) {
    GameStatePlaying() => Text('Playing'),
    GameStateGameOver(:final score) => Text('Score: $score'),
    _ => Text('...'),
  },
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

### Component から Provider を読む

```dart
import 'package:flame_riverpod/flame_riverpod.dart';

class MyPlayer extends SpriteComponent with RiverpodComponentMixin {
  @override
  void onMount() {
    super.onMount();
    // Provider を読む
    final config = ref.read(gameConfigProvider);
    // Provider を監視
    addToGameWidgetBuild(() {
      final state = ref.watch(someProvider);
      // state に基づいてコンポーネントを更新
    });
  }
}
```

## Freezed 3.x の注意点

Freezed 3.x では `sealed class` が必須:

```dart
// ✅ 正しい
@freezed
sealed class GameState with _$GameState { ... }

// ❌ コンパイルエラー
@freezed
class GameState with _$GameState { ... }
```
