import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_form_state.g.dart';

/// ログインフォームのメールアドレス状態管理
@riverpod
class LoginEmail extends _$LoginEmail {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

/// メールアドレスのバリデーション
@riverpod
String? loginEmailError(Ref ref) {
  final email = ref.watch(loginEmailProvider);

  if (email.isEmpty) {
    return null; // 空の場合はエラーを表示しない
  }

  // 簡易的なメールアドレス形式チェック
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(email)) {
    return 'メールアドレスの形式が正しくありません';
  }

  return null;
}

/// フォーム全体の有効性
@riverpod
bool isLoginFormValid(Ref ref) {
  final email = ref.watch(loginEmailProvider);
  final error = ref.watch(loginEmailErrorProvider);

  return email.isNotEmpty && error == null;
}
