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
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createSessionHash();

  @$internal
  @override
  CreateSession create() => CreateSession();
}

String _$createSessionHash() => r'2d940efc1cbbb5dbd9287b3aaf32fdad27ff54e7';

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
