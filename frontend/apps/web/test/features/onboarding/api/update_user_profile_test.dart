import 'package:flutter_test/flutter_test.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:supabase/supabase.dart';
import 'package:web_app/features/onboarding/api/update_user_profile.dart';

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

  group('updateUserProfile', () {
    test('account_name と display_name を更新できる', () async {
      await supabase.from('users').insert({
        'id': 'user-1',
        'account_name': 'user_550e8400',
        'display_name': '',
      });

      await updateUserProfile(
        supabase: supabase,
        userId: 'user-1',
        accountName: 'alice_smith',
        displayName: 'Alice Smith',
      );

      final updated = await supabase
          .from('users')
          .select()
          .eq('id', 'user-1')
          .single();

      expect(updated['account_name'], 'alice_smith');
      expect(updated['display_name'], 'Alice Smith');
    });

    test('display_name が空の場合も更新できる', () async {
      await supabase.from('users').insert({
        'id': 'user-2',
        'account_name': 'user_abcdef12',
        'display_name': '',
      });

      await updateUserProfile(
        supabase: supabase,
        userId: 'user-2',
        accountName: 'bob',
        displayName: '',
      );

      final updated = await supabase
          .from('users')
          .select()
          .eq('id', 'user-2')
          .single();

      expect(updated['account_name'], 'bob');
      expect(updated['display_name'], '');
    });
  });
}
