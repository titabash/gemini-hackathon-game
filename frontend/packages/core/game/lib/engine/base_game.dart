import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/game_state.dart';
import 'game_config.dart';

/// Base game class that bridges Flame engine state with Riverpod.
///
/// Subclass this to implement game-specific logic. The [gameState]
/// notifier is observed by [gameStateProvider] to keep Riverpod in sync.
class BaseGame extends FlameGame with RiverpodGameMixin {
  BaseGame({this.config = const GameConfig()});

  /// Game configuration.
  final GameConfig config;

  /// Observable game state for Riverpod bridge.
  final ValueNotifier<GameState> gameState = ValueNotifier(
    const GameState.initial(),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    pauseWhenBackgrounded = config.pauseWhenBackgrounded;
    gameState.value = const GameState.loading();
  }

  @override
  void onMount() {
    super.onMount();
    gameState.value = const GameState.playing();
  }

  @override
  void onRemove() {
    gameState.dispose();
    super.onRemove();
  }

  /// Transition to the playing state.
  void play() {
    resumeEngine();
    gameState.value = const GameState.playing();
  }

  /// Transition to the paused state.
  void pause() {
    pauseEngine();
    gameState.value = const GameState.paused();
  }

  /// End the game with a final score.
  void endGame({int score = 0, Map<String, dynamic>? metadata}) {
    pauseEngine();
    gameState.value = GameState.gameOver(score: score, metadata: metadata);
  }

  /// Report an error.
  void reportError(String message, [Object? error]) {
    gameState.value = GameState.error(message: message, error: error);
  }
}
