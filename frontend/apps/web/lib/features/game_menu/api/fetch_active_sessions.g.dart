// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fetch_active_sessions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// シナリオ別のアクティブセッション一覧を取得するProvider
///
/// RLS により user_id = auth.uid() は自動保証される。
/// updated_at DESC でソートし、最新のセッションを先頭に返す。

@ProviderFor(fetchActiveSessions)
final fetchActiveSessionsProvider = FetchActiveSessionsFamily._();

/// シナリオ別のアクティブセッション一覧を取得するProvider
///
/// RLS により user_id = auth.uid() は自動保証される。
/// updated_at DESC でソートし、最新のセッションを先頭に返す。

final class FetchActiveSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GameSession>>,
          List<GameSession>,
          FutureOr<List<GameSession>>
        >
    with
        $FutureModifier<List<GameSession>>,
        $FutureProvider<List<GameSession>> {
  /// シナリオ別のアクティブセッション一覧を取得するProvider
  ///
  /// RLS により user_id = auth.uid() は自動保証される。
  /// updated_at DESC でソートし、最新のセッションを先頭に返す。
  FetchActiveSessionsProvider._({
    required FetchActiveSessionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchActiveSessionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchActiveSessionsHash();

  @override
  String toString() {
    return r'fetchActiveSessionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<GameSession>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GameSession>> create(Ref ref) {
    final argument = this.argument as String;
    return fetchActiveSessions(ref, scenarioId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchActiveSessionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchActiveSessionsHash() =>
    r'082b794d462b924187ef917193639b7533e99367';

/// シナリオ別のアクティブセッション一覧を取得するProvider
///
/// RLS により user_id = auth.uid() は自動保証される。
/// updated_at DESC でソートし、最新のセッションを先頭に返す。

final class FetchActiveSessionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<GameSession>>, String> {
  FetchActiveSessionsFamily._()
    : super(
        retry: null,
        name: r'fetchActiveSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// シナリオ別のアクティブセッション一覧を取得するProvider
  ///
  /// RLS により user_id = auth.uid() は自動保証される。
  /// updated_at DESC でソートし、最新のセッションを先頭に返す。

  FetchActiveSessionsProvider call({required String scenarioId}) =>
      FetchActiveSessionsProvider._(argument: scenarioId, from: this);

  @override
  String toString() => r'fetchActiveSessionsProvider';
}
