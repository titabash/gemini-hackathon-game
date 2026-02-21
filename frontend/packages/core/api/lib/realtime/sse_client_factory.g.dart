// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sse_client_factory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sseClientConfig)
final sseClientConfigProvider = SseClientConfigProvider._();

final class SseClientConfigProvider
    extends
        $FunctionalProvider<SseClientConfig, SseClientConfig, SseClientConfig>
    with $Provider<SseClientConfig> {
  SseClientConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sseClientConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sseClientConfigHash();

  @$internal
  @override
  $ProviderElement<SseClientConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SseClientConfig create(Ref ref) {
    return sseClientConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SseClientConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SseClientConfig>(value),
    );
  }
}

String _$sseClientConfigHash() => r'9f3a6b9cb1d41723bbca3d6f9a6b940bcb2351b1';

@ProviderFor(sseClientFactory)
final sseClientFactoryProvider = SseClientFactoryProvider._();

final class SseClientFactoryProvider
    extends
        $FunctionalProvider<
          SseClientFactory,
          SseClientFactory,
          SseClientFactory
        >
    with $Provider<SseClientFactory> {
  SseClientFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sseClientFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sseClientFactoryHash();

  @$internal
  @override
  $ProviderElement<SseClientFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SseClientFactory create(Ref ref) {
    return sseClientFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SseClientFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SseClientFactory>(value),
    );
  }
}

String _$sseClientFactoryHash() => r'9f3c12b93f3ed6286ddc284fd3bf37bcf151146c';
