import 'package:core_auth/core_auth.dart';
import 'package:core_utils/core_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'verify_otp.g.dart';

/// OTP検証処理
@riverpod
class VerifyOtp extends _$VerifyOtp {
  @override
  FutureOr<void> build() {}

  /// OTPを検証してサインイン
  Future<AuthResult<void>> call({
    required String email,
    required String token,
  }) async {
    state = const AsyncLoading();

    try {
      final authService = ref.read(authServiceProvider);
      final sessionResult = await authService.verifyOtp(
        email: email,
        token: token,
      );

      // セッションが成功した場合、voidのResultに変換
      final result = sessionResult.when(
        success: (_) => const AuthResult<void>.success(null),
        failure: (e) => AuthResult<void>.failure(e),
      );

      state = const AsyncData(null);
      Logger.info('OTP verified successfully for $email');
      return result;
    } catch (e, st) {
      Logger.error('Failed to verify OTP', e, st);
      state = AsyncError(e, st);
      return AuthResult.failure(
        AuthException(
          message: 'OTPの検証に失敗しました',
          originalException: e,
        ),
      );
    }
  }
}
