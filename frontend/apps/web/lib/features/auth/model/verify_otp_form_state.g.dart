// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp_form_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// OTP検証フォームのトークン状態管理

@ProviderFor(VerifyOtpToken)
final verifyOtpTokenProvider = VerifyOtpTokenProvider._();

/// OTP検証フォームのトークン状態管理
final class VerifyOtpTokenProvider
    extends $NotifierProvider<VerifyOtpToken, String> {
  /// OTP検証フォームのトークン状態管理
  VerifyOtpTokenProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'verifyOtpTokenProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$verifyOtpTokenHash();

  @$internal
  @override
  VerifyOtpToken create() => VerifyOtpToken();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$verifyOtpTokenHash() => r'0cdf0ef1da2c4259a776d8f655656d1de0428c22';

/// OTP検証フォームのトークン状態管理

abstract class _$VerifyOtpToken extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<String, String>, String, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

/// トークンのバリデーション

@ProviderFor(verifyOtpTokenError)
final verifyOtpTokenErrorProvider = VerifyOtpTokenErrorProvider._();

/// トークンのバリデーション

final class VerifyOtpTokenErrorProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// トークンのバリデーション
  VerifyOtpTokenErrorProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'verifyOtpTokenErrorProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$verifyOtpTokenErrorHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return verifyOtpTokenError(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$verifyOtpTokenErrorHash() =>
    r'1ae729e01f618eeb2d31538c8647d91d9ea22d62';

/// フォーム全体の有効性

@ProviderFor(isVerifyOtpFormValid)
final isVerifyOtpFormValidProvider = IsVerifyOtpFormValidProvider._();

/// フォーム全体の有効性

final class IsVerifyOtpFormValidProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// フォーム全体の有効性
  IsVerifyOtpFormValidProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'isVerifyOtpFormValidProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isVerifyOtpFormValidHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isVerifyOtpFormValid(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isVerifyOtpFormValidHash() =>
    r'd18ec42baa7c366807130bc8b192b891e39c5b1f';
