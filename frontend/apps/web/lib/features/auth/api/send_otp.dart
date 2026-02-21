import 'package:core_auth/core_auth.dart';
import 'package:core_utils/core_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_otp.g.dart';

/// OTP送信処理
@riverpod
class SendOtp extends _$SendOtp {
  @override
  FutureOr<void> build() {}

  /// メールアドレスにOTPを送信
  Future<AuthResult<void>> call(String email) async {
    state = const AsyncLoading();

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithOtp(email: email);

      state = const AsyncData(null);
      Logger.info('OTP sent successfully to $email');
      return result;
    } catch (e, st) {
      Logger.error('Failed to send OTP', e, st);
      state = AsyncError(e, st);
      return AuthResult.failure(
        AuthException(
          message: 'OTPの送信に失敗しました',
          originalException: e,
        ),
      );
    }
  }
}
