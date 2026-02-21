import 'dart:math';

import 'package:core_game/core_game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart' as flame_particles;
import 'package:flutter/material.dart';

import '../../model/trpg_visual_state.dart';

/// TRPG game canvas that renders an atmospheric scene with player/NPC tokens.
///
/// Receives visual state updates from [TrpgSessionNotifier] via a
/// [ValueNotifier] and updates the game components accordingly.
class TrpgGame extends BaseGame {
  TrpgGame({required this.visualState});

  final ValueNotifier<TrpgVisualState> visualState;

  late final _SceneBackground _background;
  late final _PlayerToken _playerToken;
  late final _LocationHud _locationHud;
  late final _HpBar _hpBar;
  final List<_NpcToken> _npcTokens = [];

  final _random = Random();
  double _particleTimer = 0;

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _background = _SceneBackground();
    _playerToken = _PlayerToken(name: visualState.value.playerName);
    _locationHud = _LocationHud();
    _hpBar = _HpBar();

    await addAll([_background, _playerToken, _locationHud, _hpBar]);

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
    _locationHud.updateLocation(state.locationName);
    _playerToken.updateName(state.playerName);
    _hpBar.updateHp(state.hp, state.maxHp);
    _updateNpcs(state.activeNpcs);
  }

  void _updateNpcs(List<NpcVisual> npcs) {
    for (final token in _npcTokens) {
      token.removeFromParent();
    }
    _npcTokens.clear();

    for (var i = 0; i < npcs.length; i++) {
      final angle = (2 * pi / max(npcs.length, 1)) * i - pi / 2;
      final npc = _NpcToken(name: npcs[i].name, orbitAngle: angle);
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

  List<Color> get particleColors => _particleColors;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
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

    if (lower.contains('forest') || lower.contains('woods')) {
      _topColor = const Color(0xFF071A07);
      _bottomColor = const Color(0xFF1A3A1A);
      _particleColors = const [Color(0xFF55AA55), Color(0xFF88CC44)];
    } else if (lower.contains('cave') || lower.contains('dungeon')) {
      _topColor = const Color(0xFF0A0A0A);
      _bottomColor = const Color(0xFF1A1A2E);
      _particleColors = const [Color(0xFF555577), Color(0xFF887744)];
    } else if (lower.contains('town') || lower.contains('village')) {
      _topColor = const Color(0xFF1A1408);
      _bottomColor = const Color(0xFF2A2010);
      _particleColors = const [Color(0xFFCC9944), Color(0xFFEEBB66)];
    } else if (lower.contains('mountain') || lower.contains('peak')) {
      _topColor = const Color(0xFF1A1A2A);
      _bottomColor = const Color(0xFF3A3A4A);
      _particleColors = const [Color(0xFFAABBCC), Color(0xFF8899AA)];
    } else if (lower.contains('ocean') ||
        lower.contains('sea') ||
        lower.contains('lake')) {
      _topColor = const Color(0xFF0A1A2A);
      _bottomColor = const Color(0xFF0A2A4A);
      _particleColors = const [Color(0xFF4488CC), Color(0xFF66AAEE)];
    } else if (lower.contains('desert') || lower.contains('sand')) {
      _topColor = const Color(0xFF2A1A08);
      _bottomColor = const Color(0xFF4A3018);
      _particleColors = const [Color(0xFFCCAA55), Color(0xFFEECC77)];
    } else if (lower.contains('castle') || lower.contains('throne')) {
      _topColor = const Color(0xFF1A0A1A);
      _bottomColor = const Color(0xFF2A1A2A);
      _particleColors = const [Color(0xFFAA6688), Color(0xFFCC88AA)];
    }
  }
}

// ---------------------------------------------------------------------------
// Player Token
// ---------------------------------------------------------------------------

class _PlayerToken extends PositionComponent with HasGameReference {
  _PlayerToken({required String name}) : _name = name;

  String _name;
  static const double _radius = 28;

  final _bodyPaint = Paint()
    ..color = const Color(0xFF4488FF)
    ..style = PaintingStyle.fill;

  final _borderPaint = Paint()
    ..color = const Color(0xFF88BBFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  final _glowPaint = Paint()
    ..color = const Color(0x334488FF)
    ..style = PaintingStyle.fill;

  late TextPaint _textPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_radius * 2);
    anchor = Anchor.center;
    priority = 10;

    _textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    add(
      MoveEffect.by(
        Vector2(0, -4),
        EffectController(
          duration: 2,
          reverseDuration: 2,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = gameSize / 2;
  }

  @override
  void render(Canvas canvas) {
    // Glow
    canvas.drawCircle(const Offset(_radius, _radius), _radius + 8, _glowPaint);
    // Body
    canvas.drawCircle(const Offset(_radius, _radius), _radius, _bodyPaint);
    // Border
    canvas.drawCircle(const Offset(_radius, _radius), _radius, _borderPaint);
    // Initial letter
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : '?';
    _textPaint.render(
      canvas,
      initial,
      Vector2(_radius, _radius),
      anchor: Anchor.center,
    );
  }

  void updateName(String name) {
    _name = name;
  }
}

// ---------------------------------------------------------------------------
// NPC Token
// ---------------------------------------------------------------------------

class _NpcToken extends PositionComponent with HasGameReference {
  _NpcToken({required this.name, required this.orbitAngle});

  final String name;
  final double orbitAngle;
  static const double _radius = 20;
  static const double _orbitDistance = 100;

  final _bodyPaint = Paint()
    ..color = const Color(0xFFCC6644)
    ..style = PaintingStyle.fill;

  final _borderPaint = Paint()
    ..color = const Color(0xFFEE9966)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  late TextPaint _namePaint;
  late TextPaint _initialPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_radius * 2);
    anchor = Anchor.center;
    priority = 9;

    _namePaint = TextPaint(
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white70,
        fontWeight: FontWeight.w500,
      ),
    );

    _initialPaint = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    add(
      MoveEffect.by(
        Vector2(0, -3),
        EffectController(
          duration: 2.5,
          reverseDuration: 2.5,
          infinite: true,
          curve: Curves.easeInOut,
          startDelay: orbitAngle.abs() * 0.3,
        ),
      ),
    );
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    final center = gameSize / 2;
    position = Vector2(
      center.x + cos(orbitAngle) * _orbitDistance,
      center.y + sin(orbitAngle) * _orbitDistance,
    );
  }

  @override
  void render(Canvas canvas) {
    // Body
    canvas.drawCircle(const Offset(_radius, _radius), _radius, _bodyPaint);
    // Border
    canvas.drawCircle(const Offset(_radius, _radius), _radius, _borderPaint);
    // Initial
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    _initialPaint.render(
      canvas,
      initial,
      Vector2(_radius, _radius),
      anchor: Anchor.center,
    );
    // Name below
    _namePaint.render(
      canvas,
      name,
      Vector2(_radius, _radius * 2 + 10),
      anchor: Anchor.center,
    );
  }
}

// ---------------------------------------------------------------------------
// Location HUD
// ---------------------------------------------------------------------------

class _LocationHud extends PositionComponent with HasGameReference {
  String _location = '';

  late TextPaint _textPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = 20;
    _textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 18,
        color: Colors.white70,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
      ),
    );
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = Vector2(gameSize.x / 2, 24);
  }

  @override
  void render(Canvas canvas) {
    if (_location.isEmpty) return;
    _textPaint.render(canvas, _location, Vector2.zero(), anchor: Anchor.center);
  }

  void updateLocation(String? location) {
    _location = location ?? '';
  }
}

// ---------------------------------------------------------------------------
// HP Bar
// ---------------------------------------------------------------------------

class _HpBar extends PositionComponent with HasGameReference {
  int _hp = 100;
  int _maxHp = 100;

  static const double _barWidth = 120;
  static const double _barHeight = 10;

  final _bgPaint = Paint()
    ..color = const Color(0x66000000)
    ..style = PaintingStyle.fill;

  final _fillPaint = Paint()
    ..color = const Color(0xFF44CC44)
    ..style = PaintingStyle.fill;

  final _borderPaint = Paint()
    ..color = const Color(0x88FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  late TextPaint _textPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(_barWidth, _barHeight + 20);
    anchor = Anchor.bottomLeft;
    priority = 20;

    _textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white70,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = Vector2(16, gameSize.y - 12);
  }

  @override
  void render(Canvas canvas) {
    // Label
    _textPaint.render(canvas, 'HP', Vector2.zero());

    // Background
    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 14, _barWidth, _barHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, _bgPaint);

    // Fill
    final ratio = _maxHp > 0 ? (_hp / _maxHp).clamp(0.0, 1.0) : 0.0;
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 14, _barWidth * ratio, _barHeight),
      const Radius.circular(4),
    );

    _fillPaint.color = ratio > 0.5
        ? const Color(0xFF44CC44)
        : ratio > 0.25
        ? const Color(0xFFCCAA22)
        : const Color(0xFFCC4444);

    canvas.drawRRect(fillRect, _fillPaint);

    // Border
    canvas.drawRRect(bgRect, _borderPaint);
  }

  void updateHp(int hp, int maxHp) {
    _hp = hp;
    _maxHp = maxHp;
  }
}
