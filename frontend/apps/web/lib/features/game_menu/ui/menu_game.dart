import 'dart:math';
import 'dart:ui' as ui;

import 'package:core_game/core_game.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart' as flame_particles;
import 'package:flutter/material.dart';

/// メニュー背景用Flameゲーム
///
/// シナリオのサムネイル画像を全画面背景に表示（ダークオーバーレイ付き）。
/// サムネなしの場合はダークグラデーション。
/// 低頻度のアンビエントパーティクルを放出。
class MenuGame extends BaseGame {
  MenuGame({this.thumbnailUrl});

  final String? thumbnailUrl;

  late final _MenuBackground _background;

  final _random = Random();
  double _particleTimer = 0;

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _background = _MenuBackground(imageUrl: thumbnailUrl);
    await add(_background);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _particleTimer += dt;
    if (_particleTimer >= 1.2) {
      _particleTimer = 0;
      _spawnAmbientParticle();
    }
  }

  void _spawnAmbientParticle() {
    final color = _particleColors[_random.nextInt(_particleColors.length)];

    add(
      ParticleSystemComponent(
        particle: flame_particles.AcceleratedParticle(
          position: Vector2(_random.nextDouble() * size.x, size.y + 5),
          speed: Vector2(
            _random.nextDouble() * 12 - 6,
            -15 - _random.nextDouble() * 30,
          ),
          acceleration: Vector2(_random.nextDouble() * 3 - 1.5, -2),
          child: flame_particles.CircleParticle(
            radius: 0.6 + _random.nextDouble() * 1.2,
            paint: Paint()
              ..color = color.withValues(
                alpha: 0.1 + _random.nextDouble() * 0.25,
              ),
          ),
        ),
        position: Vector2.zero(),
      ),
    );
  }

  static const _particleColors = [
    Color(0xFF6644AA),
    Color(0xFF4488CC),
    Color(0xFFCC9944),
  ];
}

// ---------------------------------------------------------------------------
// Menu Background
// ---------------------------------------------------------------------------

class _MenuBackground extends PositionComponent with HasGameReference {
  _MenuBackground({this.imageUrl});

  final String? imageUrl;
  ui.Image? _loadedImage;

  static const _topColor = Color(0xFF0D0D2B);
  static const _bottomColor = Color(0xFF1A1A3E);

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      _loadImageFromUrl(imageUrl!);
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    if (_loadedImage != null) {
      final imgRect = Rect.fromLTWH(
        0,
        0,
        _loadedImage!.width.toDouble(),
        _loadedImage!.height.toDouble(),
      );
      final scale = max(
        size.x / _loadedImage!.width,
        size.y / _loadedImage!.height,
      );
      final scaledW = _loadedImage!.width * scale;
      final scaledH = _loadedImage!.height * scale;
      final dx = (size.x - scaledW) / 2;
      final dy = (size.y - scaledH) / 2;
      final dstRect = Rect.fromLTWH(dx, dy, scaledW, scaledH);

      canvas.drawImageRect(_loadedImage!, imgRect, dstRect, Paint());
      // Dark overlay for readability
      canvas.drawRect(rect, Paint()..color = const Color(0x88000000));
      return;
    }

    // Fallback: gradient
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_topColor, _bottomColor],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  Future<void> _loadImageFromUrl(String url) async {
    try {
      final provider = NetworkImage(url);
      final stream = provider.resolve(ImageConfiguration.empty);
      stream.addListener(
        ImageStreamListener(
          (info, _) {
            _loadedImage = info.image;
          },
          onError: (error, stackTrace) {
            Logger.warning(
              'Failed to load menu background image',
              error,
              stackTrace,
            );
          },
        ),
      );
    } catch (e, st) {
      Logger.warning('Menu background image load exception', e, st);
    }
  }
}
