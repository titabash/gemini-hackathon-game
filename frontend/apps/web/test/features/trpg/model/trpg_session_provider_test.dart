// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:core_api/core_api.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_genui/core_genui.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_app/features/trpg/model/bgm_player_notifier.dart';
import 'package:web_app/features/trpg/model/game_genui_providers.dart';
import 'package:web_app/features/trpg/model/trpg_session_provider.dart';

// ---------------------------------------------------------------------------
// Test infrastructure
// ---------------------------------------------------------------------------

/// A [GameContentGenerator] subclass that records [sendTurn] calls without
/// actually opening an SSE connection.
class _TrackingGenerator extends GameContentGenerator {
  _TrackingGenerator() : super(sseClientFactory: const SseClientFactory());

  String? lastSessionId;
  String? lastInputType;
  String? lastInputText;

  final _sendTurnCompleter = Completer<void>();

  /// Resolves the first time [sendTurn] is called.
  Future<void> get sendTurnCalled => _sendTurnCompleter.future;

  @override
  Future<void> sendTurn({
    required String sessionId,
    required String inputType,
    required String inputText,
    String? authToken,
  }) async {
    lastSessionId = sessionId;
    lastInputType = inputType;
    lastInputText = inputText;
    if (!_sendTurnCompleter.isCompleted) _sendTurnCompleter.complete();
  }
}

/// Builds a [Dio] whose interceptor immediately resolves or rejects requests.
///
/// [onRequest] is called (synchronously, inside the interceptor) whenever any
/// request is attempted – useful for asserting Dio was or was not called.
Dio _mockDio({
  required bool fail,
  Map<String, dynamic>? responseData,
  void Function()? onRequest,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call();
        if (fail) {
          handler.reject(
            DioException(
              requestOptions: options,
              message: 'simulated network error',
            ),
          );
        } else {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: responseData,
              statusCode: 200,
            ),
          );
        }
      },
    ),
  );
  return dio;
}

/// Builds a [ProviderContainer] with all providers used by
/// [TrpgSessionNotifier] replaced with lightweight test doubles.
ProviderContainer _makeContainer({
  required _TrackingGenerator gen,
  required Dio mockDio,
  SupabaseClient? supabase,
}) {
  return ProviderContainer(
    overrides: [
      backendDioProvider.overrideWithValue(mockDio),
      gameContentGeneratorProvider.overrideWith((ref) {
        ref.onDispose(gen.dispose);
        return gen;
      }),
      gameProcessorProvider.overrideWith((ref) {
        final proc = A2uiMessageProcessor(catalogs: []);
        ref.onDispose(proc.dispose);
        return proc;
      }),
      bgmPlayerProvider.overrideWith((ref) {
        final notifier = BgmPlayerNotifier();
        ref.onDispose(notifier.dispose);
        return notifier;
      }),
      accessTokenProvider.overrideWith((_) => null),
      if (supabase != null) supabaseClientProvider.overrideWithValue(supabase),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('resolvePostPagingMode', () {
    test('returns processing when isProcessing=true and hasSurface=false', () {
      final result = TrpgSessionNotifier.resolvePostPagingMode(
        isProcessing: true,
        hasSurface: false,
      );
      expect(result, NovelDisplayMode.processing);
    });

    test('returns surface when isProcessing=true and hasSurface=true', () {
      // hasSurface=true は isProcessing より優先される（choice surfaceなど）
      final result = TrpgSessionNotifier.resolvePostPagingMode(
        isProcessing: true,
        hasSurface: true,
      );
      expect(result, NovelDisplayMode.surface);
    });

    test('returns surface when isProcessing=false and hasSurface=true', () {
      final result = TrpgSessionNotifier.resolvePostPagingMode(
        isProcessing: false,
        hasSurface: true,
      );
      expect(result, NovelDisplayMode.surface);
    });

    test('returns input when isProcessing=false and hasSurface=false', () {
      final result = TrpgSessionNotifier.resolvePostPagingMode(
        isProcessing: false,
        hasSurface: false,
      );
      expect(result, NovelDisplayMode.input);
    });
  });

  group('_onError SSE recovery', () {
    const sessionId = 'aaaaaaaa-0000-0000-0000-000000000001';

    // -----------------------------------------------------------------------
    // Case A: SSE stream ended without a done event
    // -----------------------------------------------------------------------

    test(
      'Case A + Dio success: nodesReadyStream emits the recovered nodes',
      () async {
        final gen = _TrackingGenerator();
        final mockDio = _mockDio(
          fail: false,
          responseData: {
            'turn_number': 7,
            'nodes': [
              {'type': 'narration', 'text': 'The hero steps forward.'},
              {'type': 'narration', 'text': 'A light shines ahead.'},
            ],
            'requires_user_action': false,
            'is_ending': false,
          },
        );
        final container = _makeContainer(gen: gen, mockDio: mockDio);
        addTearDown(container.dispose);

        final session = container.read(trpgSessionProvider);
        session.subscribeForTest(sessionId);

        // Listen to the broadcast nodesReadyStream before triggering recovery.
        final nodesCompleter = Completer<List<Map<String, dynamic>>>();
        gen.nodesReadyStream.listen((nodes) {
          if (!nodesCompleter.isCompleted) nodesCompleter.complete(nodes);
        });

        // Trigger "SSE stream ended without done event" error path.
        gen.simulateStreamEnd();

        // Wait for _attemptSseRecovery → replayNodesReady → stream event.
        final nodes = await nodesCompleter.future.timeout(
          const Duration(seconds: 5),
        );

        expect(nodes.length, 2);
        expect(nodes[0]['type'], 'narration');
        expect(nodes[0]['text'], 'The hero steps forward.');
        expect(nodes[1]['text'], 'A light shines ahead.');
      },
    );

    test('Case A + Dio success: doneStream emits correct doneData', () async {
      final gen = _TrackingGenerator();
      final mockDio = _mockDio(
        fail: false,
        responseData: {
          'turn_number': 7,
          'nodes': <Map<String, dynamic>>[],
          'requires_user_action': true,
          'is_ending': false,
        },
      );
      final container = _makeContainer(gen: gen, mockDio: mockDio);
      addTearDown(container.dispose);

      final session = container.read(trpgSessionProvider);
      session.subscribeForTest(sessionId);

      final doneCompleter = Completer<Map<String, dynamic>>();
      gen.doneStream.listen((data) {
        if (!doneCompleter.isCompleted) doneCompleter.complete(data);
      });

      gen.simulateStreamEnd();

      final doneData = await doneCompleter.future.timeout(
        const Duration(seconds: 5),
      );

      expect(doneData['turn_number'], 7);
      expect(doneData['requires_user_action'], true);
      expect(doneData['is_ending'], false);
      // Recovery always sets will_continue=false and stop_reason='completed'.
      expect(doneData['will_continue'], false);
      expect(doneData['stop_reason'], 'completed');
    });

    test(
      'Case A + Dio success: stop_reason is "ending" when is_ending=true',
      () async {
        final gen = _TrackingGenerator();
        final mockDio = _mockDio(
          fail: false,
          responseData: {
            'turn_number': 3,
            'nodes': <Map<String, dynamic>>[],
            'requires_user_action': false,
            'is_ending': true,
          },
        );
        final container = _makeContainer(gen: gen, mockDio: mockDio);
        addTearDown(container.dispose);

        final session = container.read(trpgSessionProvider);
        session.subscribeForTest(sessionId);

        final doneCompleter = Completer<Map<String, dynamic>>();
        gen.doneStream.listen((data) {
          if (!doneCompleter.isCompleted) doneCompleter.complete(data);
        });

        gen.simulateStreamEnd();

        final doneData = await doneCompleter.future.timeout(
          const Duration(seconds: 5),
        );

        expect(doneData['is_ending'], true);
        // is_ending=true → stop_reason must be 'ending', not 'completed'.
        expect(doneData['stop_reason'], 'ending');
        expect(doneData['will_continue'], false);
        expect(doneData['turn_number'], 3);
      },
    );

    test(
      'Case A + Dio failure: falls back to sendTurn("do", "continue")',
      () async {
        final gen = _TrackingGenerator();
        final mockDio = _mockDio(fail: true);
        final container = _makeContainer(gen: gen, mockDio: mockDio);
        addTearDown(container.dispose);

        final session = container.read(trpgSessionProvider);
        session.subscribeForTest(sessionId);

        gen.simulateStreamEnd();

        // _fallbackToContinue → TrpgSessionNotifier.sendTurn →
        // _TrackingGenerator.sendTurn completes sendTurnCalled.
        await gen.sendTurnCalled.timeout(const Duration(seconds: 5));

        expect(gen.lastSessionId, sessionId);
        expect(gen.lastInputType, 'do');
        expect(gen.lastInputText, 'continue');
      },
    );

    test(
      'Case A + Dio null response: displayMode and isProcessing reset to idle',
      () async {
        final gen = _TrackingGenerator();
        // Dio succeeds but the backend returns no body (data == null).
        final mockDio = _mockDio(fail: false, responseData: null);
        final container = _makeContainer(gen: gen, mockDio: mockDio);
        addTearDown(container.dispose);

        final session = container.read(trpgSessionProvider);
        session.subscribeForTest(sessionId);

        gen.simulateStreamEnd();

        // Drain microtask queue so the async Dio → _fallbackToInputMode chain
        // has time to complete before we assert.
        await pumpEventQueue();

        expect(session.displayMode.value, NovelDisplayMode.input);
        expect(session.isProcessing.value, isFalse);
      },
    );

    // -----------------------------------------------------------------------
    // Case B: any error that is NOT the SSE-ended sentinel
    // -----------------------------------------------------------------------

    test(
      'Case B (non-SSE error): resets to input mode and never calls Dio',
      () async {
        var dioCalled = false;
        final gen = _TrackingGenerator();
        final mockDio = _mockDio(
          fail: false,
          onRequest: () => dioCalled = true,
        );
        final container = _makeContainer(gen: gen, mockDio: mockDio);
        addTearDown(container.dispose);

        final session = container.read(trpgSessionProvider);
        session.subscribeForTest(sessionId);

        // Inject an SSE error whose message does NOT match the SSE-ended
        // sentinel, triggering Case B in _onError.
        gen.injectSseMessage(
          SseMessage(raw: 'error-event', error: 'connection lost'),
        );

        await pumpEventQueue();

        expect(session.displayMode.value, NovelDisplayMode.input);
        expect(session.isProcessing.value, isFalse);
        // _attemptSseRecovery must NOT have been called.
        expect(dioCalled, isFalse);
      },
    );
  });

  group('stateUpdate new_items imagePath resolution', () {
    const sessionId = 'cccccccc-0000-0000-0000-000000000001';

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

    test('resolves imagePath from image_path in new_items SSE event', () async {
      final gen = _TrackingGenerator();
      final mockDio = _mockDio(fail: false);
      final container = _makeContainer(
        gen: gen,
        mockDio: mockDio,
        supabase: mockSupabase,
      );
      addTearDown(container.dispose);

      final session = container.read(trpgSessionProvider);
      session.subscribeForTest(sessionId);

      // Inject stateUpdate SSE event with new_items containing image_path
      gen.injectSseMessage(
        SseMessage.fromRaw(
          '{"type":"stateUpdate","data":{"new_items":['
          '{"name":"Magic Staff","description":"A glowing staff",'
          '"item_type":"weapon","quantity":1,'
          '"image_path":"item-assets/magic-staff.png"}'
          ']}}',
        ),
      );

      await pumpEventQueue();

      final items = session.visualState.value.items;
      expect(items.length, 1);
      final staff = items.first;
      expect(staff.name, 'Magic Staff');
      expect(staff.imagePath, isNotNull);
      expect(staff.imagePath, contains('magic-staff.png'));
    });

    test('imagePath is null when image_path is absent in new_items', () async {
      final gen = _TrackingGenerator();
      final mockDio = _mockDio(fail: false);
      final container = _makeContainer(gen: gen, mockDio: mockDio);
      addTearDown(container.dispose);

      final session = container.read(trpgSessionProvider);
      session.subscribeForTest(sessionId);

      // image_path キー自体が存在しない場合
      gen.injectSseMessage(
        SseMessage.fromRaw(
          '{"type":"stateUpdate","data":{"new_items":['
          '{"name":"Plain Sword","description":"An ordinary sword",'
          '"item_type":"weapon","quantity":1}'
          ']}}',
        ),
      );

      await pumpEventQueue();

      final items = session.visualState.value.items;
      expect(items.length, 1);
      expect(items.first.imagePath, isNull);
    });

    test(
      'imagePath is null when image_path is empty string in new_items',
      () async {
        final gen = _TrackingGenerator();
        final mockDio = _mockDio(fail: false);
        final container = _makeContainer(gen: gen, mockDio: mockDio);
        addTearDown(container.dispose);

        final session = container.read(trpgSessionProvider);
        session.subscribeForTest(sessionId);

        // image_path が空文字の場合
        gen.injectSseMessage(
          SseMessage.fromRaw(
            '{"type":"stateUpdate","data":{"new_items":['
            '{"name":"Broken Sword","description":"A broken sword",'
            '"item_type":"weapon","quantity":1,"image_path":""}'
            ']}}',
          ),
        );

        await pumpEventQueue();

        final items = session.visualState.value.items;
        expect(items.length, 1);
        expect(items.first.imagePath, isNull);
      },
    );
  });

  group('initSession item restoration', () {
    const sessionId = 'bbbbbbbb-0000-0000-0000-000000000001';

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

    test('restores items from items table on session init', () async {
      // Arrange: seed sessions, turns, and items tables
      await mockSupabase.from('sessions').insert({
        'id': sessionId,
        'current_state': {'hp': 80, 'location': 'Forest'},
        'current_turn_number': 2,
        'title': 'Test Session',
        'scenario_id': null,
        'current_node_index': 0,
        'status': 'active',
      });

      await mockSupabase.from('turns').insert([
        {
          'session_id': sessionId,
          'turn_number': 1,
          'input_type': 'start',
          'input_text': 'start',
          'output': {
            'nodes': [
              {'type': 'narration', 'text': 'You enter the forest.'},
            ],
          },
        },
        {
          'session_id': sessionId,
          'turn_number': 2,
          'input_type': 'do',
          'input_text': 'look around',
          'output': {
            'nodes': [
              {'type': 'narration', 'text': 'You find a sword.'},
            ],
          },
        },
      ]);

      await mockSupabase.from('items').insert([
        {
          'session_id': sessionId,
          'name': 'Iron Sword',
          'description': 'A basic sword',
          'type': 'weapon',
          'quantity': 1,
          'is_equipped': true,
        },
        {
          'session_id': sessionId,
          'name': 'Health Potion',
          'description': 'Restores 50 HP',
          'type': 'consumable',
          'quantity': 3,
          'is_equipped': false,
        },
      ]);

      final gen = _TrackingGenerator();
      final mockDio = _mockDio(fail: false);
      final container = _makeContainer(
        gen: gen,
        mockDio: mockDio,
        supabase: mockSupabase,
      );
      addTearDown(container.dispose);

      final session = container.read(trpgSessionProvider);

      // Act
      await session.initSession(sessionId);

      // Assert: items are reflected in visualState
      final items = session.visualState.value.items;
      expect(items.length, 2);

      final sword = items.firstWhere((i) => i.name == 'Iron Sword');
      expect(sword.description, 'A basic sword');
      expect(sword.itemType, 'weapon');
      expect(sword.quantity, 1);
      expect(sword.isEquipped, isTrue);

      final potion = items.firstWhere((i) => i.name == 'Health Potion');
      expect(potion.quantity, 3);
      expect(potion.isEquipped, isFalse);
    });

    test('restores imagePath from image_path column', () async {
      // Arrange: seed session, turn, and item with image_path
      await mockSupabase.from('sessions').insert({
        'id': sessionId,
        'current_state': {'hp': 100},
        'current_turn_number': 1,
        'title': 'Image Path Session',
        'scenario_id': null,
        'current_node_index': 0,
        'status': 'active',
      });

      await mockSupabase.from('turns').insert({
        'session_id': sessionId,
        'turn_number': 1,
        'input_type': 'start',
        'input_text': 'start',
        'output': {
          'nodes': [
            {'type': 'narration', 'text': 'You find a staff.'},
          ],
        },
      });

      await mockSupabase.from('items').insert({
        'session_id': sessionId,
        'name': 'Magic Staff',
        'description': 'A glowing staff',
        'type': 'weapon',
        'quantity': 1,
        'is_equipped': false,
        'image_path': 'item-assets/magic-staff.png',
      });

      final gen = _TrackingGenerator();
      final mockDio = _mockDio(fail: false);
      final container = _makeContainer(
        gen: gen,
        mockDio: mockDio,
        supabase: mockSupabase,
      );
      addTearDown(container.dispose);

      final session = container.read(trpgSessionProvider);

      // Act
      await session.initSession(sessionId);

      // Assert: imagePath is resolved (non-null) and contains the filename
      final items = session.visualState.value.items;
      expect(items.length, 1);
      final staff = items.firstWhere((i) => i.name == 'Magic Staff');
      expect(staff.imagePath, isNotNull);
      expect(staff.imagePath, contains('magic-staff.png'));
    });

    test('imagePath is null when image_path column is null', () async {
      // Arrange: item without image_path
      await mockSupabase.from('sessions').insert({
        'id': sessionId,
        'current_state': {'hp': 100},
        'current_turn_number': 1,
        'title': 'No Image Session',
        'scenario_id': null,
        'current_node_index': 0,
        'status': 'active',
      });

      await mockSupabase.from('turns').insert({
        'session_id': sessionId,
        'turn_number': 1,
        'input_type': 'start',
        'input_text': 'start',
        'output': {
          'nodes': [
            {'type': 'narration', 'text': 'You start.'},
          ],
        },
      });

      await mockSupabase.from('items').insert({
        'session_id': sessionId,
        'name': 'Plain Sword',
        'description': 'An ordinary sword',
        'type': 'weapon',
        'quantity': 1,
        'is_equipped': false,
        'image_path': null,
      });

      final gen = _TrackingGenerator();
      final mockDio = _mockDio(fail: false);
      final container = _makeContainer(
        gen: gen,
        mockDio: mockDio,
        supabase: mockSupabase,
      );
      addTearDown(container.dispose);

      final session = container.read(trpgSessionProvider);
      await session.initSession(sessionId);

      final items = session.visualState.value.items;
      expect(items.length, 1);
      expect(items.first.imagePath, isNull);
    });

    test(
      'leaves items empty when items table has no rows for session',
      () async {
        // Arrange: session with turns but no items
        await mockSupabase.from('sessions').insert({
          'id': sessionId,
          'current_state': {'hp': 100},
          'current_turn_number': 1,
          'title': 'Empty Inventory Session',
          'scenario_id': null,
          'current_node_index': 0,
          'status': 'active',
        });

        await mockSupabase.from('turns').insert({
          'session_id': sessionId,
          'turn_number': 1,
          'input_type': 'start',
          'input_text': 'start',
          'output': {
            'nodes': [
              {'type': 'narration', 'text': 'You wake up.'},
            ],
          },
        });

        final gen = _TrackingGenerator();
        final mockDio = _mockDio(fail: false);
        final container = _makeContainer(
          gen: gen,
          mockDio: mockDio,
          supabase: mockSupabase,
        );
        addTearDown(container.dispose);

        final session = container.read(trpgSessionProvider);

        // Act
        await session.initSession(sessionId);

        // Assert: items list is empty
        expect(session.visualState.value.items, isEmpty);
      },
    );
  });
}
