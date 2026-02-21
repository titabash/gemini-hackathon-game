// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bridges [BaseGame.gameState] into Riverpod as a stream.
///
/// Widgets can `ref.watch(gameStateStreamProvider)` to react to
/// game state transitions without coupling to Flame directly.

@ProviderFor(gameStateStream)
final gameStateStreamProvider = GameStateStreamProvider._();

/// Bridges [BaseGame.gameState] into Riverpod as a stream.
///
/// Widgets can `ref.watch(gameStateStreamProvider)` to react to
/// game state transitions without coupling to Flame directly.

final class GameStateStreamProvider
    extends
        $FunctionalProvider<AsyncValue<GameState>, GameState, Stream<GameState>>
    with $FutureModifier<GameState>, $StreamProvider<GameState> {
  /// Bridges [BaseGame.gameState] into Riverpod as a stream.
  ///
  /// Widgets can `ref.watch(gameStateStreamProvider)` to react to
  /// game state transitions without coupling to Flame directly.
  GameStateStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameStateStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameStateStreamHash();

  @$internal
  @override
  $StreamProviderElement<GameState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<GameState> create(Ref ref) {
    return gameStateStream(ref);
  }
}

String _$gameStateStreamHash() => r'16ad86db4a25fd8f8854f2dd112b28975c69fc7d';
