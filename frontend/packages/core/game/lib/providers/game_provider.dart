import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../engine/base_game.dart';
import '../engine/game_config.dart';

part 'game_provider.g.dart';

/// Provides a [BaseGame] instance managed by Riverpod.
///
/// Override this provider in a [ProviderScope] to supply a game-specific
/// subclass of [BaseGame].
@riverpod
class GameInstance extends _$GameInstance {
  @override
  BaseGame build() {
    final game = BaseGame();
    ref.onDispose(game.gameState.dispose);
    return game;
  }

  /// Replace the current game with a new instance.
  void reset({GameConfig config = const GameConfig()}) {
    state.gameState.dispose();
    state = BaseGame(config: config);
  }
}
