// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fetch_scenario.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 単一シナリオを取得するProvider（scenarioId パラメータ）

@ProviderFor(fetchScenario)
final fetchScenarioProvider = FetchScenarioFamily._();

/// 単一シナリオを取得するProvider（scenarioId パラメータ）

final class FetchScenarioProvider
    extends
        $FunctionalProvider<AsyncValue<Scenario>, Scenario, FutureOr<Scenario>>
    with $FutureModifier<Scenario>, $FutureProvider<Scenario> {
  /// 単一シナリオを取得するProvider（scenarioId パラメータ）
  FetchScenarioProvider._({
    required FetchScenarioFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchScenarioProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchScenarioHash();

  @override
  String toString() {
    return r'fetchScenarioProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Scenario> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Scenario> create(Ref ref) {
    final argument = this.argument as String;
    return fetchScenario(ref, scenarioId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchScenarioProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchScenarioHash() => r'ef2eb62a5fcd84e67fdac8688cdc0fb3dace4a56';

/// 単一シナリオを取得するProvider（scenarioId パラメータ）

final class FetchScenarioFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Scenario>, String> {
  FetchScenarioFamily._()
    : super(
        retry: null,
        name: r'fetchScenarioProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 単一シナリオを取得するProvider（scenarioId パラメータ）

  FetchScenarioProvider call({required String scenarioId}) =>
      FetchScenarioProvider._(argument: scenarioId, from: this);

  @override
  String toString() => r'fetchScenarioProvider';
}
