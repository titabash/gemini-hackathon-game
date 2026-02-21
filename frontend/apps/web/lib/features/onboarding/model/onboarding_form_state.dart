import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_form_state.g.dart';

/// 仮アカウント名のパターン（auth hook で自動生成: user_[hex8桁]）
final _temporaryAccountNamePattern = RegExp(r'^user_[0-9a-f]{8}$');

/// アカウント名の有効パターン（小文字英数字とアンダースコア、3〜20文字）
final _validAccountNamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

/// オンボーディングフォームのアカウント名状態管理
@riverpod
class OnboardingAccountName extends _$OnboardingAccountName {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

/// オンボーディングフォームの表示名状態管理
@riverpod
class OnboardingDisplayName extends _$OnboardingDisplayName {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

/// アカウント名のバリデーションエラー
@riverpod
String? onboardingAccountNameError(Ref ref) {
  final name = ref.watch(onboardingAccountNameProvider);

  if (name.isEmpty) return null;

  if (name.length < 3) return 'tooShort';

  if (name.length > 20) return 'tooLong';

  if (!_validAccountNamePattern.hasMatch(name)) return 'invalidFormat';

  if (_temporaryAccountNamePattern.hasMatch(name)) return 'temporary';

  return null;
}

/// フォーム全体の有効性
@riverpod
bool isOnboardingFormValid(Ref ref) {
  final name = ref.watch(onboardingAccountNameProvider);
  final error = ref.watch(onboardingAccountNameErrorProvider);

  return name.isNotEmpty && error == null;
}
