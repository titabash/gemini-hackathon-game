import 'package:flutter_test/flutter_test.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:supabase/supabase.dart';
import 'package:web_app/features/onboarding/api/check_account_name_availability.dart';

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

  group('checkAccountNameAvailability', () {
    test('使用されていないアカウント名の場合は true を返す', () async {
      final result = await checkAccountNameAvailability(
        supabase: supabase,
        accountName: 'new_user',
      );

      expect(result, isTrue);
    });

    test('既に使用されているアカウント名の場合は false を返す', () async {
      await supabase.from('users').insert({
        'id': 'user-1',
        'account_name': 'existing_user',
      });

      final result = await checkAccountNameAvailability(
        supabase: supabase,
        accountName: 'existing_user',
      );

      expect(result, isFalse);
    });
  });
}
