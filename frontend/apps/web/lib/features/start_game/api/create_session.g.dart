// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ゲームセッションを作成するProvider

@ProviderFor(CreateSession)
final createSessionProvider = CreateSessionProvider._();

/// ゲームセッションを作成するProvider
final class CreateSessionProvider
    extends $AsyncNotifierProvider<CreateSession, GameSession?> {
  /// ゲームセッションを作成するProvider
  CreateSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createSessionHash();

  @$internal
  @override
  CreateSession create() => CreateSession();
}

String _$createSessionHash() => r'c63b3997b3ecef0ac6ce7836b444f25ed40d7473';

/// ゲームセッションを作成するProvider

abstract class _$CreateSession extends $AsyncNotifier<GameSession?> {
  FutureOr<GameSession?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GameSession?>, GameSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GameSession?>, GameSession?>,
              AsyncValue<GameSession?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
