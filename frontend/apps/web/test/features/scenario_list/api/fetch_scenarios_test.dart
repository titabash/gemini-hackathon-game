import 'package:core_auth/core_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_app/features/scenario_list/api/fetch_scenarios.dart';

void main() {
  late MockSupabaseHttpClient mockHttpClient;
  late SupabaseClient mockSupabase;

  setUp(() {
    mockHttpClient = MockSupabaseHttpClient();
    mockSupabase = SupabaseClient(
      'https://mock.supabase.co',
      'fakeAnonKey',
      httpClient: mockHttpClient,
    );
  });

  tearDown(() {
    mockHttpClient.reset();
  });

  tearDownAll(() {
    mockHttpClient.close();
  });

  group('FetchScenarios', () {
    test('returns list of public scenarios', () async {
      // Arrange
      await mockSupabase.from('scenarios').insert([
        {
          'id': 'scenario-1',
          'title': 'Scenario 1',
          'description': 'Description 1',
          'initial_state': <String, dynamic>{},
          'win_conditions': <String, dynamic>{},
          'fail_conditions': <String, dynamic>{},
          'is_public': true,
          'created_at': '2024-01-15T10:30:00.000Z',
        },
        {
          'id': 'scenario-2',
          'title': 'Scenario 2',
          'description': 'Description 2',
          'initial_state': <String, dynamic>{},
          'win_conditions': <String, dynamic>{},
          'fail_conditions': <String, dynamic>{},
          'is_public': true,
          'created_at': '2024-01-16T10:30:00.000Z',
        },
      ]);

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(mockSupabase)],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(fetchScenariosProvider.future);

      // Assert
      expect(result.length, 2);
      expect(result[0].title, isA<String>());
    });

    test('returns empty list when no scenarios exist', () async {
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(mockSupabase)],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(fetchScenariosProvider.future);

      // Assert
      expect(result, isEmpty);
    });
  });
}
