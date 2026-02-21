import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../engine/base_game.dart';
import '../models/game_state.dart';
import 'game_provider.dart';

part 'game_state_provider.g.dart';

/// Bridges [BaseGame.gameState] into Riverpod as a stream.
///
/// Widgets can `ref.watch(gameStateStreamProvider)` to react to
/// game state transitions without coupling to Flame directly.
@riverpod
Stream<GameState> gameStateStream(Ref ref) {
  final game = ref.watch(gameInstanceProvider);
  return game.gameState.toStream();
}

/// Extension to convert a [ValueNotifier] into a [Stream].
extension _ValueNotifierStream<T> on ValueNotifier<T> {
  Stream<T> toStream() async* {
    yield value;
    var previous = value;
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (value != previous) {
        previous = value;
        yield value;
      }
    }
  }
}
