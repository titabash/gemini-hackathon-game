// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_generator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the configuration of the SSE content generator.
///
/// Override [contentGeneratorConfigProvider] to customise the endpoint.

@ProviderFor(contentGeneratorConfig)
final contentGeneratorConfigProvider = ContentGeneratorConfigProvider._();

/// Provides the configuration of the SSE content generator.
///
/// Override [contentGeneratorConfigProvider] to customise the endpoint.

final class ContentGeneratorConfigProvider
    extends
        $FunctionalProvider<
          ContentGeneratorConfig,
          ContentGeneratorConfig,
          ContentGeneratorConfig
        >
    with $Provider<ContentGeneratorConfig> {
  /// Provides the configuration of the SSE content generator.
  ///
  /// Override [contentGeneratorConfigProvider] to customise the endpoint.
  ContentGeneratorConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentGeneratorConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentGeneratorConfigHash();

  @$internal
  @override
  $ProviderElement<ContentGeneratorConfig> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentGeneratorConfig create(Ref ref) {
    return contentGeneratorConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentGeneratorConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentGeneratorConfig>(value),
    );
  }
}

String _$contentGeneratorConfigHash() =>
    r'6088e15a365ef8fa763418629b884416dc27890e';

/// Provides the [SseContentGenerator] instance.

@ProviderFor(contentGenerator)
final contentGeneratorProvider = ContentGeneratorProvider._();

/// Provides the [SseContentGenerator] instance.

final class ContentGeneratorProvider
    extends
        $FunctionalProvider<
          SseContentGenerator,
          SseContentGenerator,
          SseContentGenerator
        >
    with $Provider<SseContentGenerator> {
  /// Provides the [SseContentGenerator] instance.
  ContentGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentGeneratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentGeneratorHash();

  @$internal
  @override
  $ProviderElement<SseContentGenerator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SseContentGenerator create(Ref ref) {
    return contentGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SseContentGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SseContentGenerator>(value),
    );
  }
}

String _$contentGeneratorHash() => r'b9797b075d6d5f5c22f65da6be2d8f3759de4b98';
