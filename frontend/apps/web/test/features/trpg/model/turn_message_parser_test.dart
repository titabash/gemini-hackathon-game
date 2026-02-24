import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/features/trpg/model/turn_message_parser.dart';

void main() {
  group('parseTurnsToMessages', () {
    test('empty list returns empty', () {
      final result = parseTurnsToMessages([]);
      expect(result, isEmpty);
    });

    test('start turn has no user message, only GM node messages', () {
      final turnRows = [
        {
          'turn_number': 0,
          'input_type': 'start',
          'input_text': 'start',
          'output': {
            'nodes': [
              {'type': 'narration', 'text': 'The adventure begins.'},
            ],
          },
        },
      ];

      final result = parseTurnsToMessages(turnRows);

      expect(result.length, 1);
      expect(result[0].role, 'gm');
      expect(result[0].text, 'The adventure begins.');
      expect(result[0].turnNumber, 0);
      expect(result[0].speaker, isNull);
    });

    test('do turn produces user message + GM node messages', () {
      final turnRows = [
        {
          'turn_number': 1,
          'input_type': 'do',
          'input_text': 'I open the door.',
          'output': {
            'nodes': [
              {'type': 'narration', 'text': 'The door creaks open.'},
              {
                'type': 'dialogue',
                'text': 'Welcome, traveler.',
                'speaker': 'Innkeeper',
              },
            ],
          },
        },
      ];

      final result = parseTurnsToMessages(turnRows);

      expect(result.length, 3);
      // User message
      expect(result[0].role, 'user');
      expect(result[0].text, 'I open the door.');
      expect(result[0].turnNumber, 1);
      // GM narration
      expect(result[1].role, 'gm');
      expect(result[1].text, 'The door creaks open.');
      expect(result[1].turnNumber, 1);
      expect(result[1].speaker, isNull);
      // GM dialogue
      expect(result[2].role, 'gm');
      expect(result[2].text, 'Welcome, traveler.');
      expect(result[2].turnNumber, 1);
      expect(result[2].speaker, 'Innkeeper');
    });

    test('say turn produces user message + GM node messages', () {
      final turnRows = [
        {
          'turn_number': 2,
          'input_type': 'say',
          'input_text': 'Hello!',
          'output': {
            'nodes': [
              {
                'type': 'dialogue',
                'text': 'Nice to meet you!',
                'speaker': 'Merchant',
              },
            ],
          },
        },
      ];

      final result = parseTurnsToMessages(turnRows);

      expect(result.length, 2);
      expect(result[0].role, 'user');
      expect(result[0].text, 'Hello!');
      expect(result[1].role, 'gm');
      expect(result[1].speaker, 'Merchant');
    });

    test('dialogue node has speaker field set', () {
      final turnRows = [
        {
          'turn_number': 0,
          'input_type': 'start',
          'input_text': 'start',
          'output': {
            'nodes': [
              {'type': 'dialogue', 'text': 'Greetings!', 'speaker': 'Elder'},
            ],
          },
        },
      ];

      final result = parseTurnsToMessages(turnRows);

      expect(result.length, 1);
      expect(result[0].speaker, 'Elder');
    });

    test('legacy turn without nodes falls back to narration_text', () {
      final turnRows = [
        {
          'turn_number': 0,
          'input_type': 'start',
          'input_text': 'start',
          'output': {'narration_text': 'A long time ago...'},
        },
      ];

      final result = parseTurnsToMessages(turnRows);

      expect(result.length, 1);
      expect(result[0].role, 'gm');
      expect(result[0].text, 'A long time ago...');
      expect(result[0].turnNumber, 0);
    });

    test('turn with empty nodes falls back to narration_text', () {
      final turnRows = [
        {
          'turn_number': 1,
          'input_type': 'do',
          'input_text': 'Look around',
          'output': {
            'nodes': <Map<String, dynamic>>[],
            'narration_text': 'You see a dark room.',
          },
        },
      ];

      final result = parseTurnsToMessages(turnRows);

      expect(result.length, 2);
      expect(result[0].role, 'user');
      expect(result[0].text, 'Look around');
      expect(result[1].role, 'gm');
      expect(result[1].text, 'You see a dark room.');
    });

    test('turn with null output produces only user message', () {
      final turnRows = [
        {
          'turn_number': 1,
          'input_type': 'do',
          'input_text': 'Run away',
          'output': null,
        },
      ];

      final result = parseTurnsToMessages(turnRows);

      expect(result.length, 1);
      expect(result[0].role, 'user');
      expect(result[0].text, 'Run away');
    });

    test('multiple turns are in correct order with correct turnNumbers', () {
      final turnRows = [
        {
          'turn_number': 0,
          'input_type': 'start',
          'input_text': 'start',
          'output': {
            'nodes': [
              {'type': 'narration', 'text': 'Opening narration.'},
            ],
          },
        },
        {
          'turn_number': 1,
          'input_type': 'do',
          'input_text': 'Go north.',
          'output': {
            'nodes': [
              {'type': 'narration', 'text': 'You head north.'},
              {
                'type': 'dialogue',
                'text': 'Stop right there!',
                'speaker': 'Guard',
              },
            ],
          },
        },
        {
          'turn_number': 2,
          'input_type': 'say',
          'input_text': 'I come in peace.',
          'output': {
            'nodes': [
              {
                'type': 'dialogue',
                'text': 'Very well, pass.',
                'speaker': 'Guard',
              },
            ],
          },
        },
      ];

      final result = parseTurnsToMessages(turnRows);

      // Turn 0: 1 GM node
      // Turn 1: 1 user + 2 GM nodes
      // Turn 2: 1 user + 1 GM node
      expect(result.length, 6);

      // Turn 0
      expect(result[0].role, 'gm');
      expect(result[0].text, 'Opening narration.');
      expect(result[0].turnNumber, 0);

      // Turn 1
      expect(result[1].role, 'user');
      expect(result[1].text, 'Go north.');
      expect(result[1].turnNumber, 1);

      expect(result[2].role, 'gm');
      expect(result[2].text, 'You head north.');
      expect(result[2].turnNumber, 1);

      expect(result[3].role, 'gm');
      expect(result[3].text, 'Stop right there!');
      expect(result[3].turnNumber, 1);
      expect(result[3].speaker, 'Guard');

      // Turn 2
      expect(result[4].role, 'user');
      expect(result[4].text, 'I come in peace.');
      expect(result[4].turnNumber, 2);

      expect(result[5].role, 'gm');
      expect(result[5].text, 'Very well, pass.');
      expect(result[5].turnNumber, 2);
      expect(result[5].speaker, 'Guard');
    });

    test('start turn with non-start input_text still has no user message', () {
      final turnRows = [
        {
          'turn_number': 0,
          'input_type': 'start',
          'input_text': 'anything',
          'output': {
            'nodes': [
              {'type': 'narration', 'text': 'Begin.'},
            ],
          },
        },
      ];

      final result = parseTurnsToMessages(turnRows);

      expect(result.length, 1);
      expect(result[0].role, 'gm');
    });

    test(
      'turn with no narration_text and no nodes produces only user message',
      () {
        final turnRows = [
          {
            'turn_number': 1,
            'input_type': 'do',
            'input_text': 'Wait',
            'output': <String, dynamic>{},
          },
        ];

        final result = parseTurnsToMessages(turnRows);

        expect(result.length, 1);
        expect(result[0].role, 'user');
        expect(result[0].text, 'Wait');
      },
    );
  });
}
