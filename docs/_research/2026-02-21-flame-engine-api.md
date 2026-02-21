# Flame Game Engine v1.35 API 調査レポート

## 調査情報
- **調査日**: 2026-02-21
- **調査者**: spec agent
- **対象**: flame ^1.35.1 (Flutter)

## バージョン情報
- **現在使用中**: flame ^1.35.1, flame_riverpod ^5.5.2
- **最新バージョン**: 1.35.x (pub.dev)
- **推奨バージョン**: ^1.35.1 (現在のプロジェクト設定で問題なし)

## 破壊的変更
なし。v1.35.x は安定リリース。

---

## 1. カスタムコンポーネント (PositionComponent)

### 概要

`PositionComponent` は Flame の基盤クラス。位置、サイズ、回転、スケールを持つすべてのコンポーネントの親クラス。

### コンストラクタ

```dart
PositionComponent({
  Vector2? position,
  Vector2? size,
  Vector2? scale,
  double? angle,
  Anchor anchor = Anchor.topLeft,
  int? priority,
  List<Component>? children,
  ComponentKey? key,
})
```

### 主要プロパティ

| プロパティ | 型 | 説明 |
|-----------|------|------|
| `position` | `Vector2` | 親に対する相対位置（anchor基準） |
| `size` | `Vector2` | コンポーネントのサイズ |
| `scale` | `Vector2` | スケール（1.0 = 等倍） |
| `angle` | `double` | 回転（ラジアン、正 = 時計回り） |
| `anchor` | `Anchor` | 位置と回転の基準点 |
| `priority` | `int` | 描画順序（大きいほど手前） |
| `center` | `Vector2` | コンポーネントの中心座標 |
| `absolutePosition` | `Vector2` | 絶対位置 |

### ライフサイクル

```
1. onLoad()       -- 非同期初期化（1回のみ）
2. onGameResize() -- 画面リサイズ時（マウント前にも呼ばれる）
3. onMount()      -- コンポーネントツリーに追加時
4. update(dt)     -- 毎フレーム
5. render(canvas) -- 毎フレーム（update後）
6. onRemove()     -- 削除前（1回のみ）
```

### カスタムコンポーネント例

```dart
class MyComponent extends PositionComponent {
  MyComponent()
      : super(
          position: Vector2(100, 100),
          size: Vector2(50, 50),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // 非同期リソース読み込み
  }

  @override
  void update(double dt) {
    super.update(dt);
    // ゲームロジック
    position.x += 10 * dt;
  }

  @override
  void render(Canvas canvas) {
    // 重要: PositionComponentを拡張する場合、(0,0)から描画する
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFFFF0000),
    );
  }
}
```

### 可視性制御

```dart
class MyComponent extends PositionComponent with HasVisibility {
  // isVisible = false でレンダリングをスキップ
  // ただし update やイベントは引き続き処理される
}
```

---

## 2. テキスト描画 (TextComponent, TextPaint)

### TextComponent

単一行テキストを描画するコンポーネント。

```dart
// 基本使用
add(TextComponent(
  text: 'Hello, Flame',
  position: Vector2.all(16.0),
));

// TextPaint でスタイリング
final textPaint = TextPaint(
  style: TextStyle(
    fontSize: 48.0,
    color: BasicPalette.white.color,
    fontFamily: 'Awesome Font',
  ),
);

add(TextComponent(
  text: 'Styled Text',
  textRenderer: textPaint,
  position: Vector2(100, 50),
  anchor: Anchor.center,
));
```

### TextBoxComponent

テキストボックス内で自動改行するテキスト。

```dart
add(TextBoxComponent(
  text: 'This is a long text that will be wrapped...',
  textRenderer: TextPaint(
    style: TextStyle(fontSize: 16.0, color: Colors.white),
  ),
  boxConfig: TextBoxConfig(
    timePerChar: 0.05,  // タイピングエフェクト
    margins: EdgeInsets.all(8.0),
    growingBox: true,    // テキストに合わせてボックス拡大
  ),
  size: Vector2(300, 200),
));
```

### ScrollTextBoxComponent

スクロール可能なテキストボックス（ダイアログ向け）。

### Canvas への直接テキスト描画

```dart
@override
void render(Canvas canvas) {
  final textPaint = TextPaint(
    style: TextStyle(
      fontSize: 24.0,
      color: Colors.white,
    ),
  );
  textPaint.render(canvas, 'Direct text', Vector2(10, 10));
}
```

---

## 3. 図形コンポーネント (CircleComponent, RectangleComponent)

### CircleComponent

```dart
// 基本
add(CircleComponent(
  radius: 30,
  position: Vector2(100, 100),
  anchor: Anchor.center,
  paint: Paint()..color = const Color(0xFF00FF00),
));

// バウンディングボックスに対する相対サイズ
add(CircleComponent.relative(
  0.8,  // 短辺の80%
  parentSize: Vector2.all(100),
));
```

### RectangleComponent

```dart
// 基本
add(RectangleComponent(
  position: Vector2(10.0, 15.0),
  size: Vector2.all(100),
  angle: pi / 2,
  anchor: Anchor.center,
  paint: Paint()..color = const Color(0xFF0000FF),
));

// Rect から生成
add(RectangleComponent.fromRect(
  Rect.fromLTWH(10, 10, 100, 50),
));

// 正方形
add(RectangleComponent.square(
  position: Vector2.all(100),
  size: 200,
));

// 親に対する相対サイズ
add(RectangleComponent.relative(
  Vector2(0.5, 1.0),  // 幅50%, 高さ100%
  parentSize: Vector2(200, 100),
));
```

### paint プロパティ

ShapeComponent は `paint` プロパティを持ち、色や描画スタイルを設定できる。

```dart
final circle = CircleComponent(
  radius: 20,
  paint: Paint()
    ..color = const Color(0xFFFF0000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0,
);
```

---

## 4. パーティクルシステム (ParticleSystemComponent)

### 概要

Flame は `ParticleSystemComponent` でパーティクルエフェクトを管理する。パーティクルは `lifespan` で自動消滅し、コンポーネントも自動削除される。

### 基本使用

```dart
// ParticleSystemComponent でパーティクルをゲームに追加
game.add(
  ParticleSystemComponent(
    particle: CircleParticle(
      radius: 2.0,
      paint: Paint()..color = Colors.white,
      lifespan: 2.0,
    ),
    position: Vector2(100, 100),
  ),
);
```

### パーティクルの種類

| クラス | 説明 |
|--------|------|
| `CircleParticle` | 円を描画 |
| `MovingParticle` | 2点間を移動 |
| `AcceleratedParticle` | 物理ベースの動き（速度+加速度） |
| `TranslatedParticle` | オフセットして描画 |
| `ScalingParticle` | スケール変化 |
| `ComputedParticle` | カスタム描画デリゲート |
| `SpriteParticle` | スプライト画像 |
| `ImageParticle` | dart:ui Image |
| `SpriteAnimationParticle` | アニメーションスプライト |
| `ComponentParticle` | Flame コンポーネントをパーティクル化 |
| `RotatingParticle` | 回転するパーティクル |

### アンビエントエフェクトの例

```dart
// 浮遊パーティクル（アンビエント）
void spawnFloatingParticles() {
  final random = Random();

  add(
    ParticleSystemComponent(
      particle: Particle.generate(
        count: 20,
        lifespan: 3.0,
        generator: (i) {
          final startPos = Vector2(
            random.nextDouble() * size.x,
            size.y + 10,
          );
          return AcceleratedParticle(
            position: startPos,
            speed: Vector2(
              random.nextDouble() * 20 - 10,
              -30 - random.nextDouble() * 50,
            ),
            acceleration: Vector2(0, -5),
            child: CircleParticle(
              radius: 1.0 + random.nextDouble() * 2.0,
              paint: Paint()
                ..color = Colors.white.withValues(alpha: 0.3 + random.nextDouble() * 0.5),
            ),
          );
        },
      ),
    ),
  );
}
```

### パーティクルの連鎖（Chaining）

```dart
// fluent API で行動を連鎖
final particle = CircleParticle(
  radius: 2.0,
  paint: Paint()..color = Colors.blue,
)
  .moving(to: Vector2(100, -50))
  .rotating(speed: 1.0)
  .scaled(to: 0.0);
```

### Particle.generate

```dart
Particle.generate(
  count: 50,
  lifespan: 2.0,
  generator: (index) {
    // 各パーティクルをカスタム生成
    return AcceleratedParticle(
      speed: Vector2(cos(index * 0.1) * 50, sin(index * 0.1) * 50),
      child: CircleParticle(radius: 1.5, paint: paint),
    );
  },
);
```

### ComputedParticle（完全カスタム描画）

```dart
ComputedParticle(
  renderer: (canvas, particle) {
    // particle.progress は 0.0 -> 1.0
    canvas.drawCircle(
      Offset.zero,
      particle.progress * 10,
      Paint()
        ..color = Colors.white.withValues(alpha: 1 - particle.progress),
    );
  },
);
```

---

## 5. オーバーレイ (game.overlays)

### 概要

Flutter ウィジェットをゲーム上に重ねて表示する仕組み。メニュー、HUD、ポーズ画面に使用。

### 設定

```dart
// GameWidget で overlayBuilderMap を定義
GameWidget(
  game: myGame,
  overlayBuilderMap: {
    'PauseMenu': (context, game) {
      return Center(
        child: Container(
          color: Colors.black54,
          child: Text('PAUSED'),
        ),
      );
    },
    'HUD': (context, game) {
      return Positioned(
        top: 10,
        left: 10,
        child: Text('Score: 100'),
      );
    },
  },
  initialActiveOverlays: const ['HUD'],
)
```

### ゲーム内でのオーバーレイ制御

```dart
class MyGame extends FlameGame {
  void pauseGame() {
    overlays.add('PauseMenu');
  }

  void resumeGame() {
    overlays.remove('PauseMenu');
  }

  void togglePause() {
    if (overlays.isActive('PauseMenu')) {
      overlays.remove('PauseMenu');
    } else {
      overlays.add('PauseMenu');
    }
  }
}
```

### 優先度

```dart
// priority が高いほど上に表示
overlays.add('Background', priority: 0);
overlays.add('Menu', priority: 1);  // Background の上
```

---

## 6. ゲームリサイズ処理

### FlameGame のリサイズ

```dart
class MyGame extends FlameGame {
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // size にはゲームキャンバスの新しいサイズが入る
    // 注意: FlameGame では onLoad の前に onGameResize が呼ばれる
  }
}
```

### コンポーネントのリサイズ

```dart
class MyComponent extends PositionComponent {
  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    // ゲームのサイズ変更に応じてコンポーネントを調整
    size = gameSize;
    position = gameSize / 2;
  }
}
```

### ライフサイクルの順序（FlameGame特有）

FlameGame では通常のコンポーネントと順序が異なる:
1. `onGameResize()` -- 先に呼ばれる
2. `onLoad()` -- リサイズ後
3. `onMount()`

通常のコンポーネント:
1. `onLoad()`
2. `onGameResize()`
3. `onMount()`

### 固定解像度ビューポート

```dart
// 固定解像度（レターボックス付き）
class MyGame extends FlameGame {
  MyGame()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: 800,
            height: 600,
          ),
        );
}
```

### ビューポートの種類

| ビューポート | 説明 |
|-------------|------|
| `MaxViewport` | デフォルト。キャンバス全体に拡大 |
| `FixedResolutionViewport` | 固定解像度、レターボックス |
| `FixedSizeViewport` | 固定サイズの矩形 |
| `FixedAspectRatioViewport` | アスペクト比を維持して拡大 |
| `CircularViewport` | 円形ビューポート |

---

## 7. エフェクト (Effects)

### 概要

エフェクトはコンポーネントのプロパティを時間経過で変更する特別なコンポーネント。`EffectController` でタイミングを制御する。

### EffectController

```dart
EffectController(
  duration: 1.0,           // 秒数
  reverseDuration: 1.0,    // 逆再生の秒数
  infinite: true,          // 無限ループ
  alternate: true,         // 往復
  curve: Curves.easeInOut, // アニメーションカーブ
  repeatCount: 3,          // 繰り返し回数
  startDelay: 0.5,         // 開始遅延
)
```

### MoveEffect

```dart
// 相対移動
component.add(
  MoveByEffect(
    Vector2(0, -10),
    EffectController(duration: 0.5),
  ),
);

// 指定位置へ移動
component.add(
  MoveToEffect(
    Vector2(100, 500),
    EffectController(duration: 3),
  ),
);

// 静的メソッド版
component.add(
  MoveEffect.by(Vector2(30, 30), EffectController(duration: 1.0)),
);
component.add(
  MoveEffect.to(Vector2(100, 100), EffectController(duration: 1.0)),
);

// パスに沿って移動
component.add(
  MoveAlongPathEffect(
    Path()..quadraticBezierTo(100, 0, 50, -50),
    EffectController(duration: 1.5),
    absolute: false,   // 相対パス
    oriented: true,    // 移動方向を向く
  ),
);

// 無限往復移動
component.add(
  MoveEffect.to(
    Vector2(250, -5),
    EffectController(
      duration: 10,
      reverseDuration: 10,
      infinite: true,
      curve: Curves.linear,
    ),
  ),
);
```

### ScaleEffect

```dart
// 1.5倍に拡大
component.add(
  ScaleEffect.by(
    Vector2.all(1.5),
    EffectController(duration: 0.2),
  ),
);

// 指定スケールへ
component.add(
  ScaleEffect.to(
    Vector2.all(2.0),
    EffectController(duration: 0.5),
  ),
);
```

### RotateEffect

```dart
component.add(
  RotateEffect.by(
    pi / 2,  // 90度回転
    EffectController(duration: 1.0),
  ),
);
```

### SizeEffect

```dart
component.add(
  SizeEffect.to(
    Vector2(200, 200),
    EffectController(duration: 1.0),
  ),
);
```

### OpacityEffect

```dart
// フェードアウト
component.add(
  OpacityEffect.to(
    0.0,
    EffectController(duration: 0.5),
  ),
);

// フェードイン
component.add(
  OpacityEffect.fadeIn(
    EffectController(duration: 1.0),
  ),
);
```

注意: OpacityEffect は `HasPaint` ミックスインまたは `OpacityProvider` の実装が必要。

### ColorEffect

```dart
component.add(
  ColorEffect(
    const Color(0xFF00FF00),  // 緑にティント
    EffectController(duration: 1.5),
    opacityFrom: 0.2,
    opacityTo: 0.8,
  ),
);
```

注意: 1つのコンポーネントに複数の ColorEffect を同時に適用することはできない（最後のものだけが有効）。

### SequenceEffect

```dart
component.add(
  SequenceEffect([
    ScaleEffect.by(Vector2.all(1.5), EffectController(duration: 0.2)),
    MoveEffect.by(Vector2(30, -50), EffectController(duration: 0.5)),
    OpacityEffect.to(0, EffectController(duration: 0.3)),
    RemoveEffect(),  // 最後にコンポーネントを削除
  ]),
);
```

### RemoveEffect

```dart
// 遅延削除
component.add(
  RemoveEffect(delay: 2.0),
);
```

---

## 8. グラデーション背景の描画

### Canvas に直接グラデーションを描画

```dart
class GradientBackground extends PositionComponent {
  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // LinearGradient
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1a0533),  // 上: 濃い紫
        Color(0xFF0d1b2a),  // 下: 濃い青
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect);

    canvas.drawRect(rect, paint);
  }
}
```

### RadialGradient

```dart
@override
void render(Canvas canvas) {
  final rect = Rect.fromLTWH(0, 0, size.x, size.y);

  final gradient = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: const [
      Color(0xFF2a1a4e),
      Color(0xFF0a0a2e),
    ],
  );

  final paint = Paint()
    ..shader = gradient.createShader(rect);

  canvas.drawRect(rect, paint);
}
```

### 直接 Gradient.linear を使用

```dart
@override
void render(Canvas canvas) {
  final paint = Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      Offset(0, size.y),
      [
        const Color(0xFF1a0533),
        const Color(0xFF0d1b2a),
      ],
    );

  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.x, size.y),
    paint,
  );
}
```

---

## ベストプラクティス

1. **コンポーネント構成**: 子コンポーネントで階層を作り、変換は親に対して相対的になる
2. **render メソッド**: PositionComponent を拡張する場合、(0,0) から描画する（位置変換は自動適用）
3. **priority**: 高い値ほど手前に描画される
4. **onGameResize**: FlameGame では onLoad より先に呼ばれるので注意
5. **エフェクト**: 同種のエフェクトの同時適用は避ける（特に ColorEffect）
6. **パーティクル**: lifespan を設定すると自動で削除される

## 参考リンク
- [Flame 公式ドキュメント](https://docs.flame-engine.org/latest/)
- [Components](https://docs.flame-engine.org/latest/flame/components.html)
- [Text Rendering](https://docs.flame-engine.org/latest/flame/rendering/text_rendering.html)
- [Particles](https://docs.flame-engine.org/latest/flame/rendering/particles.html)
- [Overlays](https://docs.flame-engine.org/latest/flame/overlays.html)
- [Move Effects](https://docs.flame-engine.org/latest/flame/effects/move_effects.html)
- [Color Effects](https://docs.flame-engine.org/latest/flame/effects/color_effects.html)
- [Sequence Effect](https://docs.flame-engine.org/latest/flame/effects/sequence_effect.html)
- [Camera & World](https://docs.flame-engine.org/latest/flame/camera.html)
- [Game Widget](https://docs.flame-engine.org/latest/flame/game_widget.html)
- [pub.dev - flame](https://pub.dev/packages/flame)
- [GitHub - flame-engine/flame](https://github.com/flame-engine/flame)
