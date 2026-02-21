// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_client_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Supabaseクライアントを提供するProvider
///
/// アプリ全体で共有されるSupabaseクライアントインスタンス

@ProviderFor(supabaseClient)
final supabaseClientProvider = SupabaseClientProvider._();

/// Supabaseクライアントを提供するProvider
///
/// アプリ全体で共有されるSupabaseクライアントインスタンス

final class SupabaseClientProvider
    extends $FunctionalProvider<SupabaseClient, SupabaseClient, SupabaseClient>
    with $Provider<SupabaseClient> {
  /// Supabaseクライアントを提供するProvider
  ///
  /// アプリ全体で共有されるSupabaseクライアントインスタンス
  SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient>(value),
    );
  }
}

String _$supabaseClientHash() => r'2df5a38617329a3bb0a7e149189bea875722d7b8';

/// GoTrueClient（認証専用クライアント）を提供するProvider

@ProviderFor(authClient)
final authClientProvider = AuthClientProvider._();

/// GoTrueClient（認証専用クライアント）を提供するProvider

final class AuthClientProvider
    extends $FunctionalProvider<GoTrueClient, GoTrueClient, GoTrueClient>
    with $Provider<GoTrueClient> {
  /// GoTrueClient（認証専用クライアント）を提供するProvider
  AuthClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authClientHash();

  @$internal
  @override
  $ProviderElement<GoTrueClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoTrueClient create(Ref ref) {
    return authClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoTrueClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoTrueClient>(value),
    );
  }
}

String _$authClientHash() => r'e2165d5d9f35bf4680f1f1e6bb814b01c08da63f';

/// AuthServiceを提供するProvider

@ProviderFor(authService)
final authServiceProvider = AuthServiceProvider._();

/// AuthServiceを提供するProvider

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  /// AuthServiceを提供するProvider
  AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthService>(value),
    );
  }
}

String _$authServiceHash() => r'db42c9a805bfd029988467860edb8ee785098840';
