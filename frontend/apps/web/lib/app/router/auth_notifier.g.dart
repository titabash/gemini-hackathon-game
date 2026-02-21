// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AuthStateNotifierのProvider

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// AuthStateNotifierのProvider

final class AuthStateProvider
    extends
        $FunctionalProvider<
          AuthStateNotifier,
          AuthStateNotifier,
          AuthStateNotifier
        >
    with $Provider<AuthStateNotifier> {
  /// AuthStateNotifierのProvider
  AuthStateProvider._()
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
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $ProviderElement<AuthStateNotifier> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthStateNotifier create(Ref ref) {
    return authState(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthStateNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthStateNotifier>(value),
    );
  }
}

String _$authStateHash() => r'04efcdc5b6a4d1ee600d8bf3344ed73b269ce621';
