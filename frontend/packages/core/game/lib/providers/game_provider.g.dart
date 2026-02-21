// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [BaseGame] instance managed by Riverpod.
///
/// Override this provider in a [ProviderScope] to supply a game-specific
/// subclass of [BaseGame].

@ProviderFor(GameInstance)
final gameInstanceProvider = GameInstanceProvider._();

/// Provides a [BaseGame] instance managed by Riverpod.
///
/// Override this provider in a [ProviderScope] to supply a game-specific
/// subclass of [BaseGame].
final class GameInstanceProvider
    extends $NotifierProvider<GameInstance, BaseGame> {
  /// Provides a [BaseGame] instance managed by Riverpod.
  ///
  /// Override this provider in a [ProviderScope] to supply a game-specific
  /// subclass of [BaseGame].
  GameInstanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameInstanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameInstanceHash();

  @$internal
  @override
  GameInstance create() => GameInstance();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BaseGame value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BaseGame>(value),
    );
  }
}

String _$gameInstanceHash() => r'bca3c0c1bb326b4b3a538c6849e4ec63afe44028';

/// Provides a [BaseGame] instance managed by Riverpod.
///
/// Override this provider in a [ProviderScope] to supply a game-specific
/// subclass of [BaseGame].

abstract class _$GameInstance extends $Notifier<BaseGame> {
  BaseGame build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BaseGame, BaseGame>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BaseGame, BaseGame>,
              BaseGame,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
