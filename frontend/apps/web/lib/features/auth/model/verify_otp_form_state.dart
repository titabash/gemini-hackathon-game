import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'verify_otp_form_state.g.dart';

/// OTP検証フォームのトークン状態管理
@riverpod
class VerifyOtpToken extends _$VerifyOtpToken {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

/// トークンのバリデーション
@riverpod
String? verifyOtpTokenError(Ref ref) {
  final token = ref.watch(verifyOtpTokenProvider);

  if (token.isEmpty) {
    return null; // 空の場合はエラーを表示しない
  }

  // 6桁の数字チェック
  if (token.length != 6 || !RegExp(r'^\d{6}$').hasMatch(token)) {
    return '6桁の数字を入力してください';
  }

  return null;
}

/// フォーム全体の有効性
@riverpod
bool isVerifyOtpFormValid(Ref ref) {
  final token = ref.watch(verifyOtpTokenProvider);
  final error = ref.watch(verifyOtpTokenErrorProvider);

  return token.isNotEmpty && error == null;
}
