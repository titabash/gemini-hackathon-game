import 'package:core_auth/core_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:web_app/entities/session/model/session_status.dart';
import 'package:web_app/features/start_game/api/create_session.dart';

/// Fake User for testing (from supabase_flutter)
class FakeUser extends Fake implements User {
  FakeUser({required this.id});

  @override
  final String id;

  @override
  String? get email => 'test@example.com';
}

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

  group('CreateSession', () {
    test('creates a new session from scenario', () async {
      // Arrange: insert scenario
      await mockSupabase.from('scenarios').insert({
        'id': 'scenario-1',
        'title': 'Test Scenario',
        'description': 'Test',
        'initial_state': {'hp': 100, 'location': 'start'},
        'win_conditions': <String, dynamic>{},
        'fail_conditions': <String, dynamic>{},
        'is_public': true,
      });

      final fakeUser = FakeUser(id: 'user-123');

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
          currentUserProvider.overrideWithValue(fakeUser),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final session = await container
          .read(createSessionProvider.notifier)
          .create(scenarioId: 'scenario-1');

      // Assert
      expect(session.scenarioId, 'scenario-1');
      expect(session.userId, 'user-123');
      expect(session.title, 'Test Scenario');
      expect(session.status, SessionStatus.active);
      expect(session.currentTurnNumber, 0);
    });
  });
}
