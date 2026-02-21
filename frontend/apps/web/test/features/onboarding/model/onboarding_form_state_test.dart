import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_app/features/onboarding/model/onboarding_form_state.dart';

void main() {
  group('OnboardingAccountName', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初期値は空文字', () {
      expect(container.read(onboardingAccountNameProvider), '');
    });

    test('updateで値を更新できる', () {
      container.read(onboardingAccountNameProvider.notifier).update('alice');
      expect(container.read(onboardingAccountNameProvider), 'alice');
    });

    test('clearで空文字にリセットされる', () {
      container.read(onboardingAccountNameProvider.notifier).update('alice');
      container.read(onboardingAccountNameProvider.notifier).clear();
      expect(container.read(onboardingAccountNameProvider), '');
    });
  });

  group('OnboardingDisplayName', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初期値は空文字', () {
      expect(container.read(onboardingDisplayNameProvider), '');
    });

    test('updateで値を更新できる', () {
      container
          .read(onboardingDisplayNameProvider.notifier)
          .update('Alice Smith');
      expect(container.read(onboardingDisplayNameProvider), 'Alice Smith');
    });
  });

  group('onboardingAccountNameError', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('空文字の場合はnull（バリデーション対象外）', () {
      expect(container.read(onboardingAccountNameErrorProvider), isNull);
    });

    test('有効なアカウント名の場合はnull', () {
      container
          .read(onboardingAccountNameProvider.notifier)
          .update('alice_smith');
      expect(container.read(onboardingAccountNameErrorProvider), isNull);
    });

    test('3文字未満の場合はエラー', () {
      container.read(onboardingAccountNameProvider.notifier).update('ab');
      expect(container.read(onboardingAccountNameErrorProvider), isNotNull);
    });

    test('20文字超の場合はエラー', () {
      container.read(onboardingAccountNameProvider.notifier).update('a' * 21);
      expect(container.read(onboardingAccountNameErrorProvider), isNotNull);
    });

    test('大文字を含む場合はエラー', () {
      container.read(onboardingAccountNameProvider.notifier).update('Alice');
      expect(container.read(onboardingAccountNameErrorProvider), isNotNull);
    });

    test('スペースを含む場合はエラー', () {
      container
          .read(onboardingAccountNameProvider.notifier)
          .update('alice smith');
      expect(container.read(onboardingAccountNameErrorProvider), isNotNull);
    });

    test('ハイフンを含む場合はエラー', () {
      container
          .read(onboardingAccountNameProvider.notifier)
          .update('alice-smith');
      expect(container.read(onboardingAccountNameErrorProvider), isNotNull);
    });

    test('仮名パターン user_[hex8桁] の場合はエラー', () {
      container
          .read(onboardingAccountNameProvider.notifier)
          .update('user_550e8400');
      expect(container.read(onboardingAccountNameErrorProvider), isNotNull);
    });

    test('数字のみのアカウント名は有効', () {
      container.read(onboardingAccountNameProvider.notifier).update('123');
      expect(container.read(onboardingAccountNameErrorProvider), isNull);
    });

    test('アンダースコアを含むアカウント名は有効', () {
      container
          .read(onboardingAccountNameProvider.notifier)
          .update('alice_123');
      expect(container.read(onboardingAccountNameErrorProvider), isNull);
    });
  });

  group('isOnboardingFormValid', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('空文字の場合は無効', () {
      expect(container.read(isOnboardingFormValidProvider), isFalse);
    });

    test('有効なアカウント名の場合は有効', () {
      container
          .read(onboardingAccountNameProvider.notifier)
          .update('alice_smith');
      expect(container.read(isOnboardingFormValidProvider), isTrue);
    });

    test('無効な形式の場合は無効', () {
      container.read(onboardingAccountNameProvider.notifier).update('Alice');
      expect(container.read(isOnboardingFormValidProvider), isFalse);
    });

    test('仮名パターンの場合は無効', () {
      container
          .read(onboardingAccountNameProvider.notifier)
          .update('user_abcdef12');
      expect(container.read(isOnboardingFormValidProvider), isFalse);
    });
  });
}
