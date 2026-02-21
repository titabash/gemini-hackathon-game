import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/entities/session/model/game_session.dart';
import 'package:web_app/entities/session/model/session_status.dart';

void main() {
  group('GameSession', () {
    test('fromJson creates GameSession from valid JSON', () {
      final json = <String, dynamic>{
        'id': 'session-123',
        'user_id': 'user-456',
        'scenario_id': 'scenario-789',
        'title': 'Test Session',
        'status': 'active',
        'current_state': {'hp': 100},
        'current_turn_number': 5,
        'ending_summary': null,
        'ending_type': null,
        'created_at': '2024-01-15T10:30:00.000Z',
        'updated_at': '2024-01-15T10:30:00.000Z',
      };

      final session = GameSession.fromJson(json);

      expect(session.id, 'session-123');
      expect(session.userId, 'user-456');
      expect(session.scenarioId, 'scenario-789');
      expect(session.title, 'Test Session');
      expect(session.status, SessionStatus.active);
      expect(session.currentState, {'hp': 100});
      expect(session.currentTurnNumber, 5);
      expect(session.endingSummary, isNull);
      expect(session.endingType, isNull);
    });

    test('fromJson handles minimal required fields', () {
      final json = <String, dynamic>{
        'id': 'session-123',
        'user_id': 'user-456',
        'scenario_id': 'scenario-789',
        'current_state': <String, dynamic>{},
      };

      final session = GameSession.fromJson(json);

      expect(session.id, 'session-123');
      expect(session.title, '');
      expect(session.status, SessionStatus.active);
      expect(session.currentTurnNumber, 0);
    });

    test('fromJson parses all session statuses', () {
      for (final status in SessionStatus.values) {
        final json = <String, dynamic>{
          'id': 'id',
          'user_id': 'uid',
          'scenario_id': 'sid',
          'status': status.name,
          'current_state': <String, dynamic>{},
        };

        final session = GameSession.fromJson(json);
        expect(session.status, status);
      }
    });

    test('toJson produces correct snake_case keys', () {
      const session = GameSession(
        id: 'session-123',
        userId: 'user-456',
        scenarioId: 'scenario-789',
        title: 'Test',
        currentState: {'hp': 100},
        currentTurnNumber: 3,
      );

      final json = session.toJson();

      expect(json['id'], 'session-123');
      expect(json['user_id'], 'user-456');
      expect(json['scenario_id'], 'scenario-789');
      expect(json['status'], 'active');
      expect(json['current_state'], {'hp': 100});
      expect(json['current_turn_number'], 3);
    });

    test('equality works correctly', () {
      const session1 = GameSession(
        id: 'id',
        userId: 'uid',
        scenarioId: 'sid',
        currentState: {},
      );
      const session2 = GameSession(
        id: 'id',
        userId: 'uid',
        scenarioId: 'sid',
        currentState: {},
      );

      expect(session1, equals(session2));
    });
  });

  group('SessionStatus', () {
    test('fromString parses valid values', () {
      expect(SessionStatus.fromString('active'), SessionStatus.active);
      expect(SessionStatus.fromString('completed'), SessionStatus.completed);
      expect(SessionStatus.fromString('abandoned'), SessionStatus.abandoned);
    });

    test('fromString returns active for unknown values', () {
      expect(SessionStatus.fromString('unknown'), SessionStatus.active);
    });
  });
}
