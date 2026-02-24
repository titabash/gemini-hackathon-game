import 'dart:async';
import 'dart:convert';

import 'package:core_api/core_api.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

/// GM turn endpoint URL derived from BACKEND_URL.
const _backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:4040',
);
const _gmServerUrl = '$_backendUrl/api/gm/turn';

/// A [ContentGenerator] for the TRPG game that handles both A2UI messages
/// and game-specific SSE events (text, stateUpdate, imageUpdate, nodesReady).
class GameContentGenerator implements ContentGenerator {
  GameContentGenerator({required this.sseClientFactory});

  final SseClientFactory sseClientFactory;

  final StreamController<A2uiMessage> _a2uiController =
      StreamController<A2uiMessage>.broadcast();
  final StreamController<ContentGeneratorError> _errorController =
      StreamController<ContentGeneratorError>.broadcast();
  final StreamController<String> _textController =
      StreamController<String>.broadcast();
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);

  // Game-specific streams
  final StreamController<Map<String, dynamic>> _gameStateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _gameImageController =
      StreamController<String>.broadcast();
  final StreamController<void> _doneController =
      StreamController<void>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _nodesReadyController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> _assetReadyController =
      StreamController<Map<String, dynamic>>.broadcast();

  SseConnection? _activeConnection;
  StreamSubscription<SseMessage>? _activeSubscription;

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  Stream<String> get textResponseStream => _textController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  /// Stream of game state updates (location, HP, NPC visual data, scene).
  Stream<Map<String, dynamic>> get gameStateStream =>
      _gameStateController.stream;

  /// Stream of background image paths ({bucket}/{objectPath}).
  Stream<String> get gameImageStream => _gameImageController.stream;

  /// Stream that emits when the GM turn is complete.
  Stream<void> get doneStream => _doneController.stream;

  /// Stream of scene node lists for visual novel page-by-page playback.
  Stream<List<Map<String, dynamic>>> get nodesReadyStream =>
      _nodesReadyController.stream;

  /// Stream of individual asset completion events (background, NPC image).
  Stream<Map<String, dynamic>> get assetReadyStream =>
      _assetReadyController.stream;

  /// Send a game turn to the GM backend via SSE.
  Future<void> sendTurn({
    required String sessionId,
    required String inputType,
    required String inputText,
    String? authToken,
  }) async {
    _isProcessing.value = true;

    try {
      _activeSubscription?.cancel();
      _activeConnection?.close();

      final payload = <String, dynamic>{
        'session_id': sessionId,
        'input_type': inputType,
        'input_text': inputText,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final connection = await sseClientFactory.connect(
        serverUrl: Uri.parse(_gmServerUrl),
        initialPayload: payload,
        headers: headers,
      );

      _activeConnection = connection;

      _activeSubscription = connection.messages.listen(
        _handleSseMessage,
        onError: (Object error) {
          Logger.error('GM SSE stream error', error);
          _errorController.add(ContentGeneratorError(error));
          _isProcessing.value = false;
        },
        onDone: () {
          _isProcessing.value = false;
        },
      );
    } catch (error, stackTrace) {
      Logger.error('Failed to send GM turn', error, stackTrace);
      _errorController.add(ContentGeneratorError(error, stackTrace));
      _isProcessing.value = false;
    }
  }

  /// [ContentGenerator.sendRequest] delegates to [sendTurn].
  ///
  /// Note: This is a compatibility shim for the genui interface. In practice,
  /// callers should use [sendTurn] directly to provide a session ID.
  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) async {
    final text = switch (message) {
      UserMessage(:final text) => text,
      AiTextMessage(:final text) => text,
      UserUiInteractionMessage(:final text) => text,
      InternalMessage(:final text) => text,
      AiUiMessage() => '',
      ToolResponseMessage() => '',
    };
    if (text.isEmpty) return;
    await sendTurn(sessionId: '', inputType: 'do', inputText: text);
  }

  void _handleSseMessage(SseMessage sseMessage) {
    if (sseMessage.isDone) {
      _isProcessing.value = false;
      _doneController.add(null);
      return;
    }

    if (sseMessage.isError) {
      _errorController.add(
        ContentGeneratorError(sseMessage.error ?? 'Unknown SSE error'),
      );
      _isProcessing.value = false;
      return;
    }

    final raw = sseMessage.raw;
    if (raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final type = decoded['type'] as String?;

      // Game-specific events
      if (type == 'text') {
        _textController.add(decoded['content'] as String? ?? '');
        return;
      }
      if (type == 'nodesReady') {
        final nodes =
            (decoded['nodes'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .toList() ??
            [];
        _nodesReadyController.add(nodes);
        return;
      }
      if (type == 'assetReady') {
        final data = <String, dynamic>{
          'key': decoded['key'] as String? ?? '',
          'path': decoded['path'] as String? ?? '',
        };
        _assetReadyController.add(data);
        return;
      }
      if (type == 'stateUpdate') {
        final data = decoded['data'] as Map<String, dynamic>? ?? {};
        _gameStateController.add(data);
        return;
      }
      if (type == 'imageUpdate') {
        _gameImageController.add(decoded['path'] as String? ?? '');
        return;
      }
      if (type == 'done') {
        _isProcessing.value = false;
        _doneController.add(null);
        return;
      }
      if (type == 'error') {
        _errorController.add(
          ContentGeneratorError(decoded['content'] as String? ?? 'Unknown'),
        );
        return;
      }

      // A2UI protocol messages (surfaceUpdate, beginRendering, deleteSurface)
      final a2uiMessage = A2uiMessage.fromJson(decoded);
      _a2uiController.add(a2uiMessage);
    } catch (error, stackTrace) {
      Logger.warning(
        'Failed to parse GM SSE message: raw=$raw',
        error,
        stackTrace,
      );
    }
  }

  @override
  void dispose() {
    _activeSubscription?.cancel();
    _activeConnection?.close();
    _a2uiController.close();
    _errorController.close();
    _textController.close();
    _gameStateController.close();
    _gameImageController.close();
    _doneController.close();
    _nodesReadyController.close();
    _assetReadyController.close();
    _isProcessing.dispose();
  }
}
