// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'polar_client_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backend API base URL provider
///
/// Override this provider in your app's initialization to set the correct backend URL.
///
/// @example
/// ```dart
/// ProviderScope(
///   overrides: [
///     backendBaseUrlProvider.overrideWithValue('https://api.example.com'),
///   ],
///   child: MyApp(),
/// )
/// ```

@ProviderFor(backendBaseUrl)
final backendBaseUrlProvider = BackendBaseUrlProvider._();

/// Backend API base URL provider
///
/// Override this provider in your app's initialization to set the correct backend URL.
///
/// @example
/// ```dart
/// ProviderScope(
///   overrides: [
///     backendBaseUrlProvider.overrideWithValue('https://api.example.com'),
///   ],
///   child: MyApp(),
/// )
/// ```

final class BackendBaseUrlProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Backend API base URL provider
  ///
  /// Override this provider in your app's initialization to set the correct backend URL.
  ///
  /// @example
  /// ```dart
  /// ProviderScope(
  ///   overrides: [
  ///     backendBaseUrlProvider.overrideWithValue('https://api.example.com'),
  ///   ],
  ///   child: MyApp(),
  /// )
  /// ```
  BackendBaseUrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backendBaseUrlProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backendBaseUrlHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return backendBaseUrl(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$backendBaseUrlHash() => r'134af6987d5649ca052b1cadd90b29f039502443';

/// Dio instance provider for Polar API client

@ProviderFor(polarDio)
final polarDioProvider = PolarDioProvider._();

/// Dio instance provider for Polar API client

final class PolarDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Dio instance provider for Polar API client
  PolarDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'polarDioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$polarDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return polarDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$polarDioHash() => r'5ac5358dbc99015dba509eb210693256a8668238';

/// Polar API client provider
///
/// Provides a configured instance of [PolarApiClient] for making API requests.

@ProviderFor(polarApiClient)
final polarApiClientProvider = PolarApiClientProvider._();

/// Polar API client provider
///
/// Provides a configured instance of [PolarApiClient] for making API requests.

final class PolarApiClientProvider
    extends $FunctionalProvider<PolarApiClient, PolarApiClient, PolarApiClient>
    with $Provider<PolarApiClient> {
  /// Polar API client provider
  ///
  /// Provides a configured instance of [PolarApiClient] for making API requests.
  PolarApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'polarApiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$polarApiClientHash();

  @$internal
  @override
  $ProviderElement<PolarApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PolarApiClient create(Ref ref) {
    return polarApiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PolarApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PolarApiClient>(value),
    );
  }
}

String _$polarApiClientHash() => r'02aee6ac6646848f0668e4e2f640d50937daee23';
