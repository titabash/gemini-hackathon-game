// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AuthStateNotifierのProvider

@ProviderFor(authStateNotifier)
final authStateProvider = AuthStateNotifierProvider._();

/// AuthStateNotifierのProvider

final class AuthStateNotifierProvider extends $FunctionalProvider<
    AuthStateNotifier,
    AuthStateNotifier,
    AuthStateNotifier> with $Provider<AuthStateNotifier> {
  /// AuthStateNotifierのProvider
  AuthStateNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authStateProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authStateNotifierHash();

  @$internal
  @override
  $ProviderElement<AuthStateNotifier> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthStateNotifier create(Ref ref) {
    return authStateNotifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthStateNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthStateNotifier>(value),
    );
  }
}

String _$authStateNotifierHash() => r'60d036965e0cf9ec429e3ae2613fe75857c60f35';
