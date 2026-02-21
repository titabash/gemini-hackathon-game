// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fetch_scenarios.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 公開シナリオ一覧を取得するProvider

@ProviderFor(FetchScenarios)
final fetchScenariosProvider = FetchScenariosProvider._();

/// 公開シナリオ一覧を取得するProvider
final class FetchScenariosProvider
    extends $AsyncNotifierProvider<FetchScenarios, List<Scenario>> {
  /// 公開シナリオ一覧を取得するProvider
  FetchScenariosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fetchScenariosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fetchScenariosHash();

  @$internal
  @override
  FetchScenarios create() => FetchScenarios();
}

String _$fetchScenariosHash() => r'2e6b14c702db80986117fe5ff1620c17a1828268';

/// 公開シナリオ一覧を取得するProvider

abstract class _$FetchScenarios extends $AsyncNotifier<List<Scenario>> {
  FutureOr<List<Scenario>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Scenario>>, List<Scenario>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Scenario>>, List<Scenario>>,
              AsyncValue<List<Scenario>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
