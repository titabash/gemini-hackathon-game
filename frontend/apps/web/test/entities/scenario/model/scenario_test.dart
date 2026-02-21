import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/entities/scenario/model/scenario.dart';

void main() {
  group('Scenario', () {
    test('fromJson creates Scenario from valid JSON', () {
      final json = <String, dynamic>{
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'title': 'Test Scenario',
        'description': 'A test description',
        'initial_state': {'hp': 100, 'mp': 50},
        'win_conditions': [
          {'id': 'boss_defeated', 'description': 'Defeat the boss'},
        ],
        'fail_conditions': [
          {'id': 'hp_zero', 'description': 'HP reached zero'},
        ],
        'thumbnail_path': '/images/test.png',
        'created_by': '987fcdeb-51a2-3b4c-d567-890123456789',
        'is_public': true,
        'created_at': '2024-01-15T10:30:00.000Z',
        'updated_at': '2024-01-15T10:30:00.000Z',
      };

      final scenario = Scenario.fromJson(json);

      expect(scenario.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(scenario.title, 'Test Scenario');
      expect(scenario.description, 'A test description');
      expect(scenario.initialState, {'hp': 100, 'mp': 50});
      expect(scenario.winConditions, [
        {'id': 'boss_defeated', 'description': 'Defeat the boss'},
      ]);
      expect(scenario.failConditions, [
        {'id': 'hp_zero', 'description': 'HP reached zero'},
      ]);
      expect(scenario.thumbnailPath, '/images/test.png');
      expect(scenario.createdBy, '987fcdeb-51a2-3b4c-d567-890123456789');
      expect(scenario.isPublic, true);
      expect(scenario.createdAt, isA<DateTime>());
      expect(scenario.updatedAt, isA<DateTime>());
    });

    test('fromJson handles minimal required fields', () {
      final json = <String, dynamic>{
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'title': 'Minimal Scenario',
        'initial_state': <String, dynamic>{},
        'win_conditions': <dynamic>[],
        'fail_conditions': <dynamic>[],
      };

      final scenario = Scenario.fromJson(json);

      expect(scenario.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(scenario.title, 'Minimal Scenario');
      expect(scenario.description, '');
      expect(scenario.thumbnailPath, isNull);
      expect(scenario.createdBy, isNull);
      expect(scenario.isPublic, true);
      expect(scenario.createdAt, isNull);
      expect(scenario.updatedAt, isNull);
    });

    test('toJson produces correct snake_case keys', () {
      const scenario = Scenario(
        id: 'test-id',
        title: 'Test',
        initialState: {'key': 'value'},
        winConditions: [
          {'win': true},
        ],
        failConditions: [
          {'fail': true},
        ],
        isPublic: false,
      );

      final json = scenario.toJson();

      expect(json['id'], 'test-id');
      expect(json['title'], 'Test');
      expect(json['initial_state'], {'key': 'value'});
      expect(json['win_conditions'], [
        {'win': true},
      ]);
      expect(json['fail_conditions'], [
        {'fail': true},
      ]);
      expect(json['is_public'], false);
      expect(json['thumbnail_path'], isNull);
      expect(json['created_by'], isNull);
    });

    test('equality works correctly', () {
      const scenario1 = Scenario(
        id: 'id-1',
        title: 'Title',
        initialState: {},
        winConditions: [],
        failConditions: [],
      );
      const scenario2 = Scenario(
        id: 'id-1',
        title: 'Title',
        initialState: {},
        winConditions: [],
        failConditions: [],
      );

      expect(scenario1, equals(scenario2));
    });

    test('copyWith works correctly', () {
      const scenario = Scenario(
        id: 'id-1',
        title: 'Original',
        initialState: {},
        winConditions: [],
        failConditions: [],
      );

      final updated = scenario.copyWith(title: 'Updated');

      expect(updated.title, 'Updated');
      expect(updated.id, 'id-1');
    });
  });
}
