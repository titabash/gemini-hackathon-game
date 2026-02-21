import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/entities/user/model/user_profile.dart';

void main() {
  group('UserProfile', () {
    group('fromJson / toJson', () {
      test('正しいJSONからUserProfileを生成できる', () {
        final json = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'account_name': 'alice_smith',
          'display_name': 'Alice Smith',
          'avatar_path': '/avatars/alice.png',
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-15T10:30:00.000Z',
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.id, '550e8400-e29b-41d4-a716-446655440000');
        expect(profile.accountName, 'alice_smith');
        expect(profile.displayName, 'Alice Smith');
        expect(profile.avatarPath, '/avatars/alice.png');
        expect(profile.createdAt, isNotNull);
        expect(profile.updatedAt, isNotNull);
      });

      test('最小限のフィールドでUserProfileを生成できる', () {
        final json = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'account_name': 'bob',
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.id, '550e8400-e29b-41d4-a716-446655440000');
        expect(profile.accountName, 'bob');
        expect(profile.displayName, '');
        expect(profile.avatarPath, isNull);
        expect(profile.createdAt, isNull);
        expect(profile.updatedAt, isNull);
      });

      test('toJsonでsnake_case形式のJSONに変換される', () {
        const profile = UserProfile(
          id: '550e8400-e29b-41d4-a716-446655440000',
          accountName: 'alice_smith',
          displayName: 'Alice Smith',
          avatarPath: '/avatars/alice.png',
        );

        final json = profile.toJson();

        expect(json['id'], '550e8400-e29b-41d4-a716-446655440000');
        expect(json['account_name'], 'alice_smith');
        expect(json['display_name'], 'Alice Smith');
        expect(json['avatar_path'], '/avatars/alice.png');
      });
    });

    group('equality', () {
      test('同じ値のUserProfileは等値', () {
        const profile1 = UserProfile(
          id: '1',
          accountName: 'alice',
          displayName: 'Alice',
        );
        const profile2 = UserProfile(
          id: '1',
          accountName: 'alice',
          displayName: 'Alice',
        );

        expect(profile1, equals(profile2));
      });

      test('異なる値のUserProfileは非等値', () {
        const profile1 = UserProfile(
          id: '1',
          accountName: 'alice',
          displayName: 'Alice',
        );
        const profile2 = UserProfile(
          id: '1',
          accountName: 'bob',
          displayName: 'Bob',
        );

        expect(profile1, isNot(equals(profile2)));
      });
    });

    group('copyWith', () {
      test('copyWithでフィールドを変更できる', () {
        const original = UserProfile(
          id: '1',
          accountName: 'alice',
          displayName: 'Alice',
        );

        final updated = original.copyWith(
          accountName: 'alice_smith',
          displayName: 'Alice Smith',
        );

        expect(updated.id, '1');
        expect(updated.accountName, 'alice_smith');
        expect(updated.displayName, 'Alice Smith');
      });
    });

    group('needsOnboarding', () {
      test('仮名パターン user_[hex8桁] は true を返す', () {
        const profile = UserProfile(id: '1', accountName: 'user_550e8400');

        expect(profile.needsOnboarding, isTrue);
      });

      test('別の仮名パターンも true を返す', () {
        const profile = UserProfile(id: '1', accountName: 'user_abcdef12');

        expect(profile.needsOnboarding, isTrue);
      });

      test('正式なアカウント名は false を返す', () {
        const profile = UserProfile(id: '1', accountName: 'alice_smith');

        expect(profile.needsOnboarding, isFalse);
      });

      test('user_ で始まるが8桁hexでない場合は false', () {
        const profile = UserProfile(id: '1', accountName: 'user_alice');

        expect(profile.needsOnboarding, isFalse);
      });

      test('user_ で始まるが文字数が異なる場合は false', () {
        const profile = UserProfile(id: '1', accountName: 'user_550e84');

        expect(profile.needsOnboarding, isFalse);
      });

      test('空文字の account_name は false', () {
        const profile = UserProfile(id: '1', accountName: '');

        expect(profile.needsOnboarding, isFalse);
      });
    });
  });
}
