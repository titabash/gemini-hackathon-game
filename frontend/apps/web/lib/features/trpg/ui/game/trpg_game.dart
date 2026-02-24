import 'dart:math';
import 'dart:ui' as ui;

import 'package:core_game/core_game.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart' as flame_particles;
import 'package:flutter/material.dart';

import '../../model/trpg_visual_state.dart';

/// TRPG game canvas for the novel-game style.
///
/// Renders an atmospheric background (gradient or generated image)
/// and ambient particle effects. NPC display is handled by genui surfaces.
class TrpgGame extends BaseGame {
  TrpgGame({required this.visualState});

  final ValueNotifier<TrpgVisualState> visualState;

  late final _SceneBackground _background;

  final _random = Random();
  double _particleTimer = 0;

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _background = _SceneBackground();
    await add(_background);

    visualState.addListener(_onVisualStateChanged);
    _onVisualStateChanged();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _particleTimer += dt;
    if (_particleTimer >= 0.8) {
      _particleTimer = 0;
      _spawnAmbientParticle();
    }
  }

  void _onVisualStateChanged() {
    final state = visualState.value;
    _background.updateScene(state.sceneDescription);
    _background.updateBackgroundImage(state.backgroundImageUrl);
  }

  void _spawnAmbientParticle() {
    final colors = _background.particleColors;
    final color = colors[_random.nextInt(colors.length)];

    add(
      ParticleSystemComponent(
        particle: flame_particles.AcceleratedParticle(
          position: Vector2(_random.nextDouble() * size.x, size.y + 5),
          speed: Vector2(
            _random.nextDouble() * 16 - 8,
            -20 - _random.nextDouble() * 40,
          ),
          acceleration: Vector2(_random.nextDouble() * 4 - 2, -3),
          child: flame_particles.CircleParticle(
            radius: 0.8 + _random.nextDouble() * 1.5,
            paint: Paint()
              ..color = color.withValues(
                alpha: 0.15 + _random.nextDouble() * 0.35,
              ),
          ),
        ),
        position: Vector2.zero(),
      ),
    );
  }

  @override
  void onRemove() {
    visualState.removeListener(_onVisualStateChanged);
    super.onRemove();
  }
}

// ---------------------------------------------------------------------------
// Scene Background
// ---------------------------------------------------------------------------

class _SceneBackground extends PositionComponent with HasGameReference {
  Color _topColor = const Color(0xFF0D0D2B);
  Color _bottomColor = const Color(0xFF1A1A3E);
  List<Color> _particleColors = const [Color(0xFF6644AA), Color(0xFF4488CC)];

  String? _imageUrl;
  ui.Image? _loadedImage;
  String? _loadedImageUrl;

  List<Color> get particleColors => _particleColors;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // If a background image is loaded, draw it covering the full area
    if (_loadedImage != null) {
      final imgRect = Rect.fromLTWH(
        0,
        0,
        _loadedImage!.width.toDouble(),
        _loadedImage!.height.toDouble(),
      );
      // Cover fit
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
      // Draw a slight dark overlay for text readability
      canvas.drawRect(rect, Paint()..color = const Color(0x44000000));
      return;
    }

    // Fallback: gradient background
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_topColor, _bottomColor],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void updateScene(String? description) {
    if (description == null) return;
    final lower = description.toLowerCase();

    if (_matchesAny(lower, ['forest', 'woods', '森', '林'])) {
      _topColor = const Color(0xFF071A07);
      _bottomColor = const Color(0xFF1A3A1A);
      _particleColors = const [Color(0xFF55AA55), Color(0xFF88CC44)];
    } else if (_matchesAny(lower, ['cave', 'dungeon', '洞窟', 'ダンジョン'])) {
      _topColor = const Color(0xFF0A0A0A);
      _bottomColor = const Color(0xFF1A1A2E);
      _particleColors = const [Color(0xFF555577), Color(0xFF887744)];
    } else if (_matchesAny(lower, [
      'town',
      'village',
      'tavern',
      'bar',
      '町',
      '村',
      '酒場',
      '宿',
    ])) {
      _topColor = const Color(0xFF1A1408);
      _bottomColor = const Color(0xFF2A2010);
      _particleColors = const [Color(0xFFCC9944), Color(0xFFEEBB66)];
    } else if (_matchesAny(lower, ['mountain', 'peak', '山', '峰'])) {
      _topColor = const Color(0xFF1A1A2A);
      _bottomColor = const Color(0xFF3A3A4A);
      _particleColors = const [Color(0xFFAABBCC), Color(0xFF8899AA)];
    } else if (_matchesAny(lower, ['ocean', 'sea', 'lake', '海', '湖'])) {
      _topColor = const Color(0xFF0A1A2A);
      _bottomColor = const Color(0xFF0A2A4A);
      _particleColors = const [Color(0xFF4488CC), Color(0xFF66AAEE)];
    } else if (_matchesAny(lower, ['desert', 'sand', '砂漠', '砂'])) {
      _topColor = const Color(0xFF2A1A08);
      _bottomColor = const Color(0xFF4A3018);
      _particleColors = const [Color(0xFFCCAA55), Color(0xFFEECC77)];
    } else if (_matchesAny(lower, ['castle', 'throne', '城', '玉座'])) {
      _topColor = const Color(0xFF1A0A1A);
      _bottomColor = const Color(0xFF2A1A2A);
      _particleColors = const [Color(0xFFAA6688), Color(0xFFCC88AA)];
    }
  }

  static bool _matchesAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  void updateBackgroundImage(String? url) {
    if (url == _imageUrl) return;
    _imageUrl = url;
    if (url == null || url.isEmpty) {
      _loadedImage = null;
      _loadedImageUrl = null;
      return;
    }
    _loadImageFromUrl(url);
  }

  Future<void> _loadImageFromUrl(String url) async {
    if (_loadedImageUrl == url) return;
    Logger.debug('Loading background image: $url');
    try {
      final provider = NetworkImage(url);
      final stream = provider.resolve(ImageConfiguration.empty);
      stream.addListener(
        ImageStreamListener(
          (info, _) {
            // Staleness check: ignore if a newer URL was requested
            if (_imageUrl != url) return;
            _loadedImage = info.image;
            _loadedImageUrl = url;
            Logger.debug('Background image loaded successfully');
          },
          onError: (error, stackTrace) {
            Logger.warning(
              'Failed to load background image: $url',
              error,
              stackTrace,
            );
          },
        ),
      );
    } catch (e, st) {
      Logger.warning('Background image load exception: $url', e, st);
    }
  }
}
