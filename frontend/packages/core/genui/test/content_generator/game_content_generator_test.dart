// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:core_api/core_api.dart';
import 'package:core_genui/content_generator/game_content_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

/// Tests for [GameContentGenerator] SSE message handling.
///
/// These tests verify:
/// 1. Game backend {"type":"done"} JSON messages correctly emit to [doneStream]
///    (not intercepted by SSE protocol isDone check).
/// 2. SSE stream ending without a done event emits to [errorStream] as a safety
///    net to prevent perpetual loading state.
void main() {
  group('GameContentGenerator', () {
    late GameContentGenerator generator;

    setUp(() {
      generator = GameContentGenerator(
        sseClientFactory: const SseClientFactory(),
      );
    });

    tearDown(() {
      generator.dispose();
    });

    // ---- done JSON event handling ----------------------------------------

    group('done JSON event handling', () {
      test('doneStream emits when {"type":"done"} JSON is received', () async {
        final doneCompleter = Completer<Map<String, dynamic>>();
        final sub = generator.doneStream.listen(doneCompleter.complete);

        generator.injectSseMessage(
          SseMessage.fromRaw(
            '{"type":"done","turn_number":1,'
            '"requires_user_action":false,'
            '"is_ending":false,"will_continue":true}',
          ),
        );

        final data = await doneCompleter.future.timeout(
          const Duration(seconds: 1),
        );
        expect(data['turn_number'], 1);
        expect(data['requires_user_action'], false);
        expect(data['is_ending'], false);
        expect(data['will_continue'], true);

        await sub.cancel();
      });

      test(
        'isProcessing becomes true when will_continue=true in done event',
        () async {
          final sub = generator.doneStream.listen((_) {});

          generator.injectSseMessage(
            SseMessage.fromRaw(
              '{"type":"done","turn_number":1,'
              '"requires_user_action":false,'
              '"is_ending":false,"will_continue":true}',
            ),
          );

          // Give stream time to process
          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(generator.isProcessing.value, true);

          await sub.cancel();
        },
      );

      test(
        'isProcessing becomes false when will_continue=false in done event',
        () async {
          final sub = generator.doneStream.listen((_) {});

          generator.injectSseMessage(
            SseMessage.fromRaw(
              '{"type":"done","turn_number":7,'
              '"requires_user_action":false,'
              '"is_ending":true,"will_continue":false}',
            ),
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(generator.isProcessing.value, false);

          await sub.cancel();
        },
      );

      test(
        'doneStream emits with is_ending=true for session-ending done event',
        () async {
          final doneCompleter = Completer<Map<String, dynamic>>();
          final sub = generator.doneStream.listen(doneCompleter.complete);

          generator.injectSseMessage(
            SseMessage.fromRaw(
              '{"type":"done","turn_number":7,'
              '"requires_user_action":false,'
              '"is_ending":true,"will_continue":false}',
            ),
          );

          final data = await doneCompleter.future.timeout(
            const Duration(seconds: 1),
          );
          expect(data['is_ending'], true);
          expect(data['will_continue'], false);

          await sub.cancel();
        },
      );
    });

    // ---- empty SSE message (protocol-level done) --------------------------

    group('SSE protocol-level empty message', () {
      test('doneStream does NOT emit for empty raw SSE message', () async {
        var doneCount = 0;
        final sub = generator.doneStream.listen((_) => doneCount++);

        // Empty raw = SSE protocol-level synthetic event (no game data)
        generator.injectSseMessage(SseMessage.fromRaw(''));

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(doneCount, 0);

        await sub.cancel();
      });

      test('isProcessing becomes false for empty SSE message', () async {
        // Simulate processing state by directly injecting a will_continue done
        generator.injectSseMessage(
          SseMessage.fromRaw(
            '{"type":"done","will_continue":true,'
            '"requires_user_action":false,"is_ending":false}',
          ),
        );
        expect(generator.isProcessing.value, true);

        // Empty SSE message should clear isProcessing
        generator.injectSseMessage(SseMessage.fromRaw(''));
        expect(generator.isProcessing.value, false);
      });
    });

    // ---- safety net: stream ending without done ---------------------------

    group('SSE stream ending without done event (safety net)', () {
      test(
        'errorStream emits when stream ends without prior done event',
        () async {
          final errorCompleter = Completer<ContentGeneratorError>();
          final sub = generator.errorStream.listen(errorCompleter.complete);

          // Simulate stream ending WITHOUT receiving a done event
          generator.simulateStreamEnd();

          final error = await errorCompleter.future.timeout(
            const Duration(seconds: 1),
          );
          expect(error.error.toString(), contains('done'));

          await sub.cancel();
        },
      );

      test(
        'isProcessing becomes false when stream ends without done event',
        () async {
          final sub = generator.errorStream.listen((_) {});

          generator.simulateStreamEnd();
          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(generator.isProcessing.value, false);

          await sub.cancel();
        },
      );

      test(
        'errorStream does NOT emit when stream ends after done was received',
        () async {
          var errorCount = 0;
          final sub = generator.errorStream.listen((_) => errorCount++);

          // First receive a done event
          generator.injectSseMessage(
            SseMessage.fromRaw(
              '{"type":"done","turn_number":1,'
              '"requires_user_action":false,'
              '"is_ending":false,"will_continue":false}',
            ),
          );

          // Then simulate stream end
          generator.simulateStreamEnd();

          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(errorCount, 0);

          await sub.cancel();
        },
      );
    });

    // ---- other game events ------------------------------------------------

    group('other game events pass through correctly', () {
      test('nodesReadyStream emits for nodesReady event', () async {
        final completer = Completer<List<Map<String, dynamic>>>();
        final sub = generator.nodesReadyStream.listen(completer.complete);

        generator.injectSseMessage(
          SseMessage.fromRaw(
            '{"type":"nodesReady","nodes":[{"id":"n1","type":"text"}]}',
          ),
        );

        final nodes = await completer.future.timeout(
          const Duration(seconds: 1),
        );
        expect(nodes.length, 1);
        expect(nodes.first['id'], 'n1');

        await sub.cancel();
      });

      test('gameStateStream emits for stateUpdate event', () async {
        final completer = Completer<Map<String, dynamic>>();
        final sub = generator.gameStateStream.listen(completer.complete);

        generator.injectSseMessage(
          SseMessage.fromRaw(
            '{"type":"stateUpdate","data":{"location":"Town"}}',
          ),
        );

        final data = await completer.future.timeout(const Duration(seconds: 1));
        expect(data['location'], 'Town');

        await sub.cancel();
      });
    });

    // ---- replayNodesReady (SSE recovery) -----------------------------------

    group('replayNodesReady for SSE error recovery', () {
      test('nodesReadyStream emits with provided nodes', () async {
        final completer = Completer<List<Map<String, dynamic>>>();
        final sub = generator.nodesReadyStream.listen(completer.complete);

        final nodes = [
          {'type': 'narration', 'text': 'The story continues...'},
        ];
        generator.replayNodesReady(
          nodes: nodes,
          doneData: {
            'turn_number': 7,
            'requires_user_action': false,
            'is_ending': true,
            'will_continue': false,
            'stop_reason': 'ending',
          },
        );

        final received = await completer.future.timeout(
          const Duration(seconds: 1),
        );
        expect(received.length, 1);
        expect(received.first['text'], 'The story continues...');

        await sub.cancel();
      });

      test('doneStream emits with provided done data', () async {
        final completer = Completer<Map<String, dynamic>>();
        final sub = generator.doneStream.listen(completer.complete);

        generator.replayNodesReady(
          nodes: [
            {'type': 'narration', 'text': 'Final scene.'},
          ],
          doneData: {
            'turn_number': 5,
            'requires_user_action': false,
            'is_ending': false,
            'will_continue': false,
            'stop_reason': 'completed',
          },
        );

        final data = await completer.future.timeout(const Duration(seconds: 1));
        expect(data['turn_number'], 5);
        expect(data['is_ending'], false);

        await sub.cancel();
      });

      test('isProcessing stays false after replayNodesReady', () async {
        final sub = generator.doneStream.listen((_) {});

        generator.replayNodesReady(
          nodes: [
            {'type': 'narration', 'text': 'Recovery node.'},
          ],
          doneData: {
            'turn_number': 3,
            'requires_user_action': true,
            'is_ending': false,
            'will_continue': false,
            'stop_reason': 'requires_user_action',
          },
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(generator.isProcessing.value, false);

        await sub.cancel();
      });
    });
  });
}
