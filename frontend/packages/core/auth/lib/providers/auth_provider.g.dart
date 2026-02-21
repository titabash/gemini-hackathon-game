// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 認証状態を管理するNotifierProvider
///
/// 参考プロジェクトのZustandストアに相当
/// - セッション情報を保持
/// - 認証状態の更新
/// - リセット機能

@ProviderFor(Auth)
final authProvider = AuthProvider._();

/// 認証状態を管理するNotifierProvider
///
/// 参考プロジェクトのZustandストアに相当
/// - セッション情報を保持
/// - 認証状態の更新
/// - リセット機能
final class AuthProvider extends $NotifierProvider<Auth, AuthState> {
  /// 認証状態を管理するNotifierProvider
  ///
  /// 参考プロジェクトのZustandストアに相当
  /// - セッション情報を保持
  /// - 認証状態の更新
  /// - リセット機能
  AuthProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authHash();

  @$internal
  @override
  Auth create() => Auth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$authHash() => r'3cef5f64b6517fe70bda3a5decb8557639cdbf5f';

/// 認証状態を管理するNotifierProvider
///
/// 参考プロジェクトのZustandストアに相当
/// - セッション情報を保持
/// - 認証状態の更新
/// - リセット機能

abstract class _$Auth extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AuthState, AuthState>, AuthState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

/// 認証状態の便利なアクセサProvider
/// ユーザー情報を取得

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// 認証状態の便利なアクセサProvider
/// ユーザー情報を取得

final class CurrentUserProvider extends $FunctionalProvider<User?, User?, User?>
    with $Provider<User?> {
  /// 認証状態の便利なアクセサProvider
  /// ユーザー情報を取得
  CurrentUserProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentUserProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  User? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$currentUserHash() => r'136a4c18c102e18ca31daa576123c775047eded3';

/// 認証済みかどうか

@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = IsAuthenticatedProvider._();

/// 認証済みかどうか

final class IsAuthenticatedProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// 認証済みかどうか
  IsAuthenticatedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'isAuthenticatedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isAuthenticatedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isAuthenticated(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isAuthenticatedHash() => r'e340c24e8e96b3f86d7fbbb5aaf0e2c3a9ccd79c';

/// アクセストークンを取得

@ProviderFor(accessToken)
final accessTokenProvider = AccessTokenProvider._();

/// アクセストークンを取得

final class AccessTokenProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// アクセストークンを取得
  AccessTokenProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'accessTokenProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$accessTokenHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return accessToken(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$accessTokenHash() => r'1fd10bd84c86520c263e291c376b1c6bcf704a1e';
