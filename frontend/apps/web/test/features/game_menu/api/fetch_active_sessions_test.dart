import 'package:core_auth/core_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_app/features/game_menu/api/fetch_active_sessions.dart';

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

  group('fetchActiveSessions', () {
    test('returns only active sessions for the given scenario', () async {
      // Arrange
      await mockSupabase.from('sessions').insert([
        {
          'id': 'session-1',
          'user_id': 'user-1',
          'scenario_id': 'scenario-1',
          'title': 'Active Session',
          'status': 'active',
          'current_state': {'hp': 100},
          'current_turn_number': 5,
          'updated_at': '2024-01-15T10:00:00Z',
        },
        {
          'id': 'session-2',
          'user_id': 'user-1',
          'scenario_id': 'scenario-1',
          'title': 'Completed Session',
          'status': 'completed',
          'current_state': {'hp': 0},
          'current_turn_number': 20,
          'updated_at': '2024-01-14T10:00:00Z',
        },
        {
          'id': 'session-3',
          'user_id': 'user-1',
          'scenario_id': 'scenario-1',
          'title': 'Abandoned Session',
          'status': 'abandoned',
          'current_state': {'hp': 50},
          'current_turn_number': 3,
          'updated_at': '2024-01-13T10:00:00Z',
        },
      ]);

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(mockSupabase)],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(
        fetchActiveSessionsProvider(scenarioId: 'scenario-1').future,
      );

      // Assert
      expect(result.length, 1);
      expect(result.first.id, 'session-1');
      expect(result.first.status.name, 'active');
    });

    test('returns only sessions for the specified scenario', () async {
      // Arrange
      await mockSupabase.from('sessions').insert([
        {
          'id': 'session-1',
          'user_id': 'user-1',
          'scenario_id': 'scenario-1',
          'title': 'Scenario 1 Session',
          'status': 'active',
          'current_state': {'hp': 100},
          'current_turn_number': 5,
        },
        {
          'id': 'session-2',
          'user_id': 'user-1',
          'scenario_id': 'scenario-2',
          'title': 'Scenario 2 Session',
          'status': 'active',
          'current_state': {'hp': 80},
          'current_turn_number': 3,
        },
      ]);

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(mockSupabase)],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(
        fetchActiveSessionsProvider(scenarioId: 'scenario-1').future,
      );

      // Assert
      expect(result.length, 1);
      expect(result.first.scenarioId, 'scenario-1');
    });

    test('returns sessions ordered by updated_at descending', () async {
      // Arrange
      await mockSupabase.from('sessions').insert([
        {
          'id': 'session-old',
          'user_id': 'user-1',
          'scenario_id': 'scenario-1',
          'title': 'Old Session',
          'status': 'active',
          'current_state': {'hp': 100},
          'current_turn_number': 1,
          'updated_at': '2024-01-10T10:00:00Z',
        },
        {
          'id': 'session-new',
          'user_id': 'user-1',
          'scenario_id': 'scenario-1',
          'title': 'New Session',
          'status': 'active',
          'current_state': {'hp': 90},
          'current_turn_number': 3,
          'updated_at': '2024-01-15T10:00:00Z',
        },
      ]);

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(mockSupabase)],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(
        fetchActiveSessionsProvider(scenarioId: 'scenario-1').future,
      );

      // Assert
      expect(result.length, 2);
      expect(result.first.id, 'session-new');
      expect(result.last.id, 'session-old');
    });

    test('returns empty list when no active sessions exist', () async {
      // Arrange: no sessions inserted

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(mockSupabase)],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(
        fetchActiveSessionsProvider(scenarioId: 'scenario-1').future,
      );

      // Assert
      expect(result, isEmpty);
    });
  });
}
