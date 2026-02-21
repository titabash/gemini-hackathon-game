// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_form_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ログインフォームのメールアドレス状態管理

@ProviderFor(LoginEmail)
final loginEmailProvider = LoginEmailProvider._();

/// ログインフォームのメールアドレス状態管理
final class LoginEmailProvider extends $NotifierProvider<LoginEmail, String> {
  /// ログインフォームのメールアドレス状態管理
  LoginEmailProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginEmailProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginEmailHash();

  @$internal
  @override
  LoginEmail create() => LoginEmail();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$loginEmailHash() => r'980a72487c81c8eeb4bfe74ede40139f9f2bf89b';

/// ログインフォームのメールアドレス状態管理

abstract class _$LoginEmail extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// メールアドレスのバリデーション

@ProviderFor(loginEmailError)
final loginEmailErrorProvider = LoginEmailErrorProvider._();

/// メールアドレスのバリデーション

final class LoginEmailErrorProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// メールアドレスのバリデーション
  LoginEmailErrorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginEmailErrorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginEmailErrorHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return loginEmailError(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$loginEmailErrorHash() => r'c7678a982af05f9725e927db998bfb80b7bc546a';

/// フォーム全体の有効性

@ProviderFor(isLoginFormValid)
final isLoginFormValidProvider = IsLoginFormValidProvider._();

/// フォーム全体の有効性

final class IsLoginFormValidProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// フォーム全体の有効性
  IsLoginFormValidProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isLoginFormValidProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isLoginFormValidHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isLoginFormValid(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isLoginFormValidHash() => r'391fb890c7402d4cdc48bd493cb4a1ee69cfaad7';
