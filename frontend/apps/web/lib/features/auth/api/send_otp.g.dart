// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_otp.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// OTP送信処理

@ProviderFor(SendOtp)
final sendOtpProvider = SendOtpProvider._();

/// OTP送信処理
final class SendOtpProvider extends $AsyncNotifierProvider<SendOtp, void> {
  /// OTP送信処理
  SendOtpProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sendOtpProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sendOtpHash();

  @$internal
  @override
  SendOtp create() => SendOtp();
}

String _$sendOtpHash() => r'4836fa8c1089a42669a02d57e4e1f763eafa168d';

/// OTP送信処理

abstract class _$SendOtp extends $AsyncNotifier<void> {
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
