import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_app/entities/user/model/user_profile.dart';
import 'package:web_app/features/onboarding/model/onboarding_status_provider.dart';

void main() {
  group('needsOnboardingProvider', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('仮アカウント名の場合は true を返す', () async {
      container = ProviderContainer(
        overrides: [
          currentUserProfileProvider.overrideWith(
            (ref) async =>
                const UserProfile(id: '1', accountName: 'user_550e8400'),
          ),
        ],
      );

      final result = await container.read(needsOnboardingProvider.future);
      expect(result, isTrue);
    });

    test('正式なアカウント名の場合は false を返す', () async {
      container = ProviderContainer(
        overrides: [
          currentUserProfileProvider.overrideWith(
            (ref) async =>
                const UserProfile(id: '1', accountName: 'alice_smith'),
          ),
        ],
      );

      final result = await container.read(needsOnboardingProvider.future);
      expect(result, isFalse);
    });

    test('プロフィールが null の場合は false を返す', () async {
      container = ProviderContainer(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) async => null),
        ],
      );

      final result = await container.read(needsOnboardingProvider.future);
      expect(result, isFalse);
    });
  });
}
