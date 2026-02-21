# Flame Game Engine 調査レポート

## 調査情報
- **調査日**: 2026-02-21
- **調査者**: spec agent

## バージョン情報
- **現在使用中**: なし（新規導入）
- **最新バージョン**: v1.35.1（2026-02-12 公開）
- **推奨バージョン**: v1.35.1
- **flame_riverpod**: v5.5.2（2026-02-12 公開）

## SDK 要件
- **Dart SDK**: >= 3.11.0 < 4.0.0
- **Flutter SDK**: >= 3.41.0
- **プロジェクトの Flutter**: 3.41.2（Dart 3.11.0）-- 互換性あり
- **注意**: pubspec.yaml の SDK 制約（^3.6.0 / ^3.27.0）は古いため要更新

## 依存関係
### flame 1.35.1
- collection: ^1.18.0
- flutter (SDK)
- meta: ^1.12.0
- ordered_set: ^8.0.0
- vector_math: ^2.1.4

### flame_riverpod 5.5.2
- flame: ^1.35.1
- flutter
- flutter_riverpod: ^3.0.3（プロジェクト hooks_riverpod ^3.0.3 と互換）
- riverpod: ^3.0.3

## 破壊的変更
v1.34.0 / v1.35.0 / v1.35.1 いずれも破壊的変更なし。

## コアクラス API

### FlameGame
```dart
import 'package:flame/game.dart';

class MyGame extends FlameGame {
  // コンストラクタ
  // FlameGame({Iterable<Component>? children, World? world, CameraComponent? camera})

  @override
  Future<void> onLoad() async {
    // 1回だけ呼ばれる初期化（リソースのロード等）
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 毎フレーム呼ばれる更新処理
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // 毎フレーム呼ばれる描画処理
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // リサイズ時に呼ばれる
  }
}
```

#### 主要プロパティ
| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `camera` | `CameraComponent` | ワールドのレンダリング担当 |
| `world` | `World` | カメラが描画する対象ワールド |
| `size` | `Vector2` | ビューポート変換考慮後のサイズ |
| `canvasSize` | `Vector2` | キャンバスの実寸 |
| `paused` | `bool` | 一時停止中かどうか |
| `pauseWhenBackgrounded` | `bool` | バックグラウンド時に自動停止 |

#### 主要メソッド
| メソッド | 説明 |
|---------|------|
| `onLoad()` | 非同期初期化（1回のみ） |
| `update(double dt)` | 毎フレーム更新 |
| `render(Canvas canvas)` | 毎フレーム描画 |
| `onGameResize(Vector2 size)` | サイズ変更通知 |
| `pauseEngine()` | ゲームループ停止 |
| `resumeEngine()` | ゲームループ再開 |
| `add(Component)` | コンポーネント追加 |
| `addAll(Iterable<Component>)` | 複数追加 |
| `remove(Component)` | コンポーネント削除 |
| `loadSprite(String path)` | スプライトロード |

#### ライフサイクル順序
1. `onGameResize` (追加/リサイズ時)
2. `onLoad` (1回のみ)
3. `onMount` (追加/再マウント時)
4. `update/render` ループ (毎フレーム)
5. `onRemove` (削除時)

### GameWidget
```dart
import 'package:flame/game.dart';

// 方法1: 直接ゲームインスタンスを渡す
GameWidget(game: MyGame())

// 方法2: ファクトリで生成（ウィジェット側でライフサイクル管理）
GameWidget.controlled(gameFactory: MyGame.new)
```

#### コンストラクタパラメータ
| パラメータ | 型 | 説明 |
|-----------|-----|------|
| `game` / `gameFactory` | `T` / `GameFactory<T>` | ゲームインスタンスまたはファクトリ |
| `overlayBuilderMap` | `Map<String, OverlayWidgetBuilder<T>>?` | オーバーレイウィジェット |
| `loadingBuilder` | `GameLoadingWidgetBuilder?` | ロード中ウィジェット |
| `errorBuilder` | `GameErrorWidgetBuilder?` | エラーウィジェット |
| `backgroundBuilder` | `WidgetBuilder?` | 背景ウィジェット |
| `initialActiveOverlays` | `List<String>?` | 初期表示オーバーレイ |
| `focusNode` | `FocusNode?` | フォーカス制御 |
| `autofocus` | `bool` | 自動フォーカス（デフォルト: true） |
| `mouseCursor` | `MouseCursor?` | マウスカーソル形状 |
| `addRepaintBoundary` | `bool` | RepaintBoundary（デフォルト: true） |

#### オーバーレイシステム
```dart
GameWidget(
  game: myGame,
  overlayBuilderMap: {
    'PauseMenu': (context, game) => PauseMenuWidget(game: game),
    'HUD': (context, game) => HudWidget(game: game),
  },
  initialActiveOverlays: const ['HUD'],
)

// ゲーム内からオーバーレイ制御
game.overlays.add('PauseMenu');
game.overlays.remove('PauseMenu');
```

### Component
```dart
import 'package:flame/components.dart';

class MyComponent extends Component {
  @override
  Future<void> onLoad() async {
    // リソース初期化（1回のみ）
  }

  @override
  void onMount() {
    // ゲームツリーに追加された時
  }

  @override
  void update(double dt) {
    // 毎フレーム更新
  }

  @override
  void render(Canvas canvas) {
    // 毎フレーム描画
  }

  @override
  void onRemove() {
    // 削除時のクリーンアップ
  }
}
```

#### Component ライフサイクル
1. `onLoad()` - 非同期リソース初期化（1回のみ）
2. `onGameResize()` - リサイズ時
3. `onMount()` - ツリーに追加時（複数回可）
4. `update(dt)` / `render(canvas)` - 毎フレーム
5. `onRemove()` - 削除時

#### 優先度（Priority）
```dart
component.priority = 2; // 高い値ほど前面に描画
```

## Riverpod 統合パターン（flame_riverpod）

### セットアップ
```dart
import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Game クラスに RiverpodGameMixin を追加
class MyGame extends FlameGame with RiverpodGameMixin {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(MyRiverpodComponent());
  }
}

// 2. Riverpod を使用するコンポーネントに RiverpodComponentMixin を追加
class MyRiverpodComponent extends PositionComponent
    with RiverpodComponentMixin {
  @override
  void onMount() {
    // addToGameWidgetBuild で Riverpod API を登録
    // super.onMount() の前に呼ぶ
    addToGameWidgetBuild(() {
      ref.listen(myProvider, (previous, next) {
        // プロバイダの変更に反応
      });
    });
    super.onMount();
  }
}

// 3. RiverpodAwareGameWidget を使用
class MyGamePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RiverpodAwareGameWidget(
      key: gameWidgetKey,
      game: MyGame(),
    );
  }
}
```

### 重要な注意点
- `addToGameWidgetBuild()` は `super.onMount()` の **前に** 呼ぶ
- コンポーネントのライフサイクルに従ってサブスクリプションが管理される
- マウント時に初期化、削除時に自動破棄
- `ref.watch` と `ref.listen` の両方が利用可能（v5.0.0以降）

## 基本的なゲーム構造パターン

### World + Camera パターン（推奨）
```dart
class MyWorld extends World {
  @override
  Future<void> onLoad() async {
    await add(Player());
    await add(Enemy());
  }
}

void main() {
  final game = FlameGame(world: MyWorld());
  runApp(
    ProviderScope(
      child: GameWidget(game: game),
    ),
  );
}
```

### Flutter ウィジェットツリーへの埋め込み
```dart
// ページの一部としてゲームを埋め込む
Scaffold(
  appBar: AppBar(title: Text('My Game')),
  body: GameWidget(game: MyGame()),
)

// または GameWidget.controlled で自動管理
Scaffold(
  body: GameWidget.controlled(
    gameFactory: MyGame.new,
    loadingBuilder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
    errorBuilder: (context, error) => Center(
      child: Text('Error: $error'),
    ),
  ),
)
```

## インポートパターン
```dart
// 基本
import 'package:flame/game.dart';         // FlameGame, GameWidget
import 'package:flame/components.dart';    // Component, PositionComponent, SpriteComponent 等
import 'package:flame/events.dart';        // TapCallbacks, DragCallbacks 等
import 'package:flame/effects.dart';       // MoveEffect, ScaleEffect 等
import 'package:flame/collisions.dart';    // Hitbox, CollisionCallbacks
import 'package:flame/palette.dart';       // BasicPalette
import 'package:flame/sprite.dart';        // Sprite, SpriteAnimation

// Riverpod 統合
import 'package:flame_riverpod/flame_riverpod.dart';
```

## 必要な設定（pubspec.yaml）
```yaml
dependencies:
  flame: ^1.35.1
  flame_riverpod: ^5.5.2  # Riverpod統合が必要な場合

# SDK 制約の更新が必要
environment:
  sdk: ^3.11.0
  flutter: ^3.41.0
```

## 参考リンク
- [Flame pub.dev](https://pub.dev/packages/flame)
- [flame_riverpod pub.dev](https://pub.dev/packages/flame_riverpod)
- [Flame 公式ドキュメント](https://docs.flame-engine.org/latest/)
- [FlameGame API](https://pub.dev/documentation/flame/latest/game/FlameGame-class.html)
- [GameWidget API](https://pub.dev/documentation/flame/latest/game/GameWidget-class.html)
- [flame_riverpod ドキュメント](https://docs.flame-engine.org/latest/bridge_packages/flame_riverpod/riverpod.html)
- [Flame GitHub](https://github.com/flame-engine/flame)
