// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dio クライアントを提供するProvider
///
/// 認証トークンの自動付与とロギングを設定

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// Dio クライアントを提供するProvider
///
/// 認証トークンの自動付与とロギングを設定

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Dio クライアントを提供するProvider
  ///
  /// 認証トークンの自動付与とロギングを設定
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'8824231bbcfb4d82b4414ea0475bdb0b7128f424';

/// Edge Functions用のDioクライアント

@ProviderFor(edgeFunctionsDio)
final edgeFunctionsDioProvider = EdgeFunctionsDioProvider._();

/// Edge Functions用のDioクライアント

final class EdgeFunctionsDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Edge Functions用のDioクライアント
  EdgeFunctionsDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'edgeFunctionsDioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$edgeFunctionsDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return edgeFunctionsDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$edgeFunctionsDioHash() => r'b6d85f99d5bd6a88b816c42bebf471c011c9b851';

/// Python Backend用のDioクライアント

@ProviderFor(backendDio)
final backendDioProvider = BackendDioProvider._();

/// Python Backend用のDioクライアント

final class BackendDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Python Backend用のDioクライアント
  BackendDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backendDioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backendDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return backendDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$backendDioHash() => r'356a0eda2e48b36c8126b8f1a771b8729b40add1';
