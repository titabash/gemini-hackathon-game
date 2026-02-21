import 'dart:math';
import 'dart:ui' as ui;

import 'package:core_game/core_game.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart' as flame_particles;
import 'package:flutter/material.dart';

import '../../model/trpg_visual_state.dart';

/// TRPG game canvas for the novel-game style.
///
/// Renders an atmospheric background (gradient or generated image),
/// NPC character tokens, and ambient particle effects.
class TrpgGame extends BaseGame {
  TrpgGame({required this.visualState});

  final ValueNotifier<TrpgVisualState> visualState;

  late final _SceneBackground _background;
  final List<_NpcToken> _npcTokens = [];

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
    _updateNpcs(state.activeNpcs);
  }

  void _updateNpcs(List<NpcVisual> npcs) {
    for (final token in _npcTokens) {
      token.removeFromParent();
    }
    _npcTokens.clear();

    for (var i = 0; i < npcs.length; i++) {
      // Place NPCs along the bottom third, spread horizontally
      final xFraction = (i + 1) / (npcs.length + 1);
      final npc = _NpcToken(
        name: npcs[i].name,
        xFraction: xFraction,
        imageUrl: npcs[i].imageUrl,
      );
      _npcTokens.add(npc);
      add(npc);
    }
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

// ---------------------------------------------------------------------------
// NPC Standing Portrait (novel-game style)
// ---------------------------------------------------------------------------

class _NpcToken extends PositionComponent with HasGameReference {
  _NpcToken({required this.name, required this.xFraction, this.imageUrl});

  final String name;
  final String? imageUrl;

  /// Horizontal position as a fraction of screen width (0.0 - 1.0).
  final double xFraction;

  /// Height of the standing portrait relative to screen height.
  static const double _heightRatio = 0.65;

  /// Radius for the fallback circle when no image is available.
  static const double _fallbackRadius = 32;

  final _bodyPaint = Paint()
    ..color = const Color(0xFFCC6644)
    ..style = PaintingStyle.fill;

  final _shadowPaint = Paint()
    ..color = const Color(0x44000000)
    ..style = PaintingStyle.fill;

  late TextPaint _namePaint;
  late TextPaint _initialPaint;

  ui.Image? _portrait;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.bottomCenter;
    priority = 9;

    _namePaint = TextPaint(
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(color: Colors.black, blurRadius: 8),
          Shadow(color: Colors.black, blurRadius: 4),
        ],
      ),
    );

    _initialPaint = TextPaint(
      style: const TextStyle(
        fontSize: 22,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    add(
      MoveEffect.by(
        Vector2(0, -2),
        EffectController(
          duration: 3.0,
          reverseDuration: 3.0,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );

    _loadPortrait();
  }

  void _loadPortrait() {
    final url = imageUrl;
    if (url == null || url.isEmpty) return;
    try {
      final provider = NetworkImage(url);
      final stream = provider.resolve(ImageConfiguration.empty);
      stream.addListener(
        ImageStreamListener(
          (info, _) {
            _portrait = info.image;
            _recalculateSize();
          },
          onError: (error, stackTrace) {
            Logger.debug('Failed to load NPC portrait: $url', error);
          },
        ),
      );
    } catch (e) {
      Logger.debug('NPC portrait load exception: $url', e);
    }
  }

  void _recalculateSize() {
    if (!isMounted) return;
    final gameSize = game.size;
    final portraitHeight = gameSize.y * _heightRatio;

    final portrait = _portrait;
    if (portrait != null) {
      final aspect = portrait.width / portrait.height;
      size = Vector2(portraitHeight * aspect, portraitHeight);
    } else {
      size = Vector2(_fallbackRadius * 2, _fallbackRadius * 2);
    }
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = Vector2(gameSize.x * xFraction, gameSize.y);
    _recalculateSize();
  }

  @override
  void render(Canvas canvas) {
    final portrait = _portrait;
    if (portrait != null) {
      // Draw foot shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y + 2),
          width: size.x * 0.5,
          height: 8,
        ),
        _shadowPaint,
      );

      // Draw standing portrait (full body, no clipping)
      final src = Rect.fromLTWH(
        0,
        0,
        portrait.width.toDouble(),
        portrait.height.toDouble(),
      );
      final dst = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawImageRect(portrait, src, dst, Paint());

      // Name plate below feet
      _namePaint.render(
        canvas,
        name,
        Vector2(size.x / 2, size.y + 16),
        anchor: Anchor.center,
      );
    } else {
      // Fallback: small circle with initial
      final cx = size.x / 2;
      final cy = size.y / 2;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, size.y + 2),
          width: _fallbackRadius * 1.5,
          height: 6,
        ),
        _shadowPaint,
      );

      canvas.drawCircle(Offset(cx, cy), _fallbackRadius, _bodyPaint);

      final borderPaint = Paint()
        ..color = const Color(0xFFEE9966)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(cx, cy), _fallbackRadius, borderPaint);

      final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
      _initialPaint.render(
        canvas,
        initial,
        Vector2(cx, cy),
        anchor: Anchor.center,
      );

      _namePaint.render(
        canvas,
        name,
        Vector2(cx, size.y + 14),
        anchor: Anchor.center,
      );
    }
  }
}
