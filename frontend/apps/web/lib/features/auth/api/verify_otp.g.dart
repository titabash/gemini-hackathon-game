// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// OTP検証処理

@ProviderFor(VerifyOtp)
final verifyOtpProvider = VerifyOtpProvider._();

/// OTP検証処理
final class VerifyOtpProvider extends $AsyncNotifierProvider<VerifyOtp, void> {
  /// OTP検証処理
  VerifyOtpProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'verifyOtpProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$verifyOtpHash();

  @$internal
  @override
  VerifyOtp create() => VerifyOtp();
}

String _$verifyOtpHash() => r'a4ae09db9bcc2c982b559c04776b5dd2fce4922e';

/// OTP検証処理

abstract class _$VerifyOtp extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<void>, void>,
        AsyncValue<void>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
