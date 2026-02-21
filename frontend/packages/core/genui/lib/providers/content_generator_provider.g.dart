// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_generator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [ContentGenerator] backed by the SSE content generator.
///
/// Override [contentGeneratorConfigProvider] to customise the endpoint.

@ProviderFor(contentGeneratorConfig)
final contentGeneratorConfigProvider = ContentGeneratorConfigProvider._();

/// Provides a [ContentGenerator] backed by the SSE content generator.
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
  /// Provides a [ContentGenerator] backed by the SSE content generator.
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
          ContentGenerator,
          ContentGenerator,
          ContentGenerator
        >
    with $Provider<ContentGenerator> {
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
  $ProviderElement<ContentGenerator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ContentGenerator create(Ref ref) {
    return contentGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentGenerator>(value),
    );
  }
}

String _$contentGeneratorHash() => r'11a49ee9607cf8a218651ac83989e970b2b56cbb';
