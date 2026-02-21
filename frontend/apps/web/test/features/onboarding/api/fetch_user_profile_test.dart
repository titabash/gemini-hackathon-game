import 'package:flutter_test/flutter_test.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:supabase/supabase.dart';
import 'package:web_app/features/onboarding/api/fetch_user_profile.dart';

void main() {
  late MockSupabaseHttpClient mockHttpClient;
  late SupabaseClient supabase;

  setUp(() {
    mockHttpClient = MockSupabaseHttpClient();
    supabase = SupabaseClient(
      'https://mock.supabase.co',
      'fakeAnonKey',
      httpClient: mockHttpClient,
    );
  });

  tearDown(() {
    mockHttpClient.reset();
    mockHttpClient.close();
  });

  group('fetchUserProfile', () {
    test('ユーザーが存在する場合はUserProfileを返す', () async {
      await supabase.from('users').insert({
        'id': 'user-1',
        'account_name': 'alice_smith',
        'display_name': 'Alice Smith',
        'avatar_path': '/avatars/alice.png',
      });

      final result = await fetchUserProfile(
        supabase: supabase,
        userId: 'user-1',
      );

      expect(result, isNotNull);
      expect(result!.id, 'user-1');
      expect(result.accountName, 'alice_smith');
      expect(result.displayName, 'Alice Smith');
    });

    test('ユーザーが存在しない場合はnullを返す', () async {
      final result = await fetchUserProfile(
        supabase: supabase,
        userId: 'nonexistent',
      );

      expect(result, isNull);
    });
  });
}
