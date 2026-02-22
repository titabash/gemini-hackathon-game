import 'package:core_auth/core_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_app/features/scenario_detail/api/fetch_scenario.dart';

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

  group('fetchScenario', () {
    test('returns scenario by ID', () async {
      // Arrange
      await mockSupabase.from('scenarios').insert({
        'id': 'scenario-1',
        'title': 'Test Scenario',
        'description': 'Test description',
        'initial_state': {'hp': 100},
        'win_conditions': [
          {'boss_defeated': true},
        ],
        'fail_conditions': [
          {'hp_zero': true},
        ],
        'is_public': true,
      });

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(mockSupabase)],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(
        fetchScenarioProvider(scenarioId: 'scenario-1').future,
      );

      // Assert
      expect(result.id, 'scenario-1');
      expect(result.title, 'Test Scenario');
      expect(result.description, 'Test description');
      expect(result.initialState, {'hp': 100});
    });
  });
}
