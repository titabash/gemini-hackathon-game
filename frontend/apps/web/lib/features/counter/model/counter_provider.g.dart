// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CounterNotifier)
final counterProvider = CounterNotifierProvider._();

final class CounterNotifierProvider
    extends $NotifierProvider<CounterNotifier, CounterModel> {
  CounterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'counterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$counterNotifierHash();

  @$internal
  @override
  CounterNotifier create() => CounterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CounterModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CounterModel>(value),
    );
  }
}

String _$counterNotifierHash() => r'f77f0bd03aa697592cddaaf2b109ab6a0ecf3824';

abstract class _$CounterNotifier extends $Notifier<CounterModel> {
  CounterModel build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CounterModel, CounterModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CounterModel, CounterModel>,
              CounterModel,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
