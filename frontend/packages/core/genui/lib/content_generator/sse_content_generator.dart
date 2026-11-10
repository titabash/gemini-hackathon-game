import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:core_api/core_api.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/foundation.dart';

import '../models/genui_message.dart';
import 'content_generator_config.dart';
import 'content_generator_error.dart';

/// A content generator that connects to a Python FastAPI backend via SSE.
///
/// Uses [SseClientFactory] from core_api to establish the connection and
/// streams A2UI protocol messages back to the caller.
class SseContentGenerator {
  SseContentGenerator({required this.config, required this.sseClientFactory});

  final ContentGeneratorConfig config;
  final SseClientFactory sseClientFactory;

  final StreamController<AgentToRendererMessage> _a2uiController =
      StreamController<AgentToRendererMessage>.broadcast();
  final StreamController<ContentGeneratorError> _errorController =
      StreamController<ContentGeneratorError>.broadcast();
  final StreamController<String> _textController =
      StreamController<String>.broadcast();
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);

  SseConnection? _activeConnection;

  /// A stream of A2UI messages received from the backend.
  Stream<AgentToRendererMessage> get a2uiMessageStream =>
      _a2uiController.stream;

  /// A stream of errors from the backend or the SSE connection.
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  /// A stream of text responses from the backend.
  Stream<String> get textResponseStream => _textController.stream;

  /// Whether a request is currently being processed.
  ValueListenable<bool> get isProcessing => _isProcessing;

  /// Sends [message] to the backend, with the previous conversation [history]
  /// and the renderer's A2UI [clientCapabilities] JSON.
  Future<void> sendRequest(
    String message, {
    Iterable<GenuiMessage>? history,
    Map<String, Object?>? clientCapabilities,
  }) async {
    _isProcessing.value = true;

    try {
      _activeConnection?.close();

      final payload = <String, dynamic>{
        'message': message,
        if (history != null)
          'history': history
              .map(
                (m) => {
                  'role': m is GenuiMessageUser ? 'user' : 'model',
                  'text': m.text,
                },
              )
              .toList(),
        if (clientCapabilities != null)
          'client_capabilities': clientCapabilities,
      };

      final headers = <String, String>{
        ...config.headers,
        if (config.authToken != null)
          'Authorization': 'Bearer ${config.authToken}',
      };

      final connection = await sseClientFactory.connect(
        serverUrl: Uri.parse(config.serverUrl),
        initialPayload: payload,
        headers: headers,
      );

      _activeConnection = connection;

      connection.messages.listen(
        (sseMessage) {
          _handleSseMessage(sseMessage);
        },
        onError: (Object error) {
          Logger.error('SSE stream error', error);
          _errorController.add(ContentGeneratorError(error.toString()));
          _isProcessing.value = false;
        },
        onDone: () {
          _isProcessing.value = false;
        },
      );
    } catch (error, stackTrace) {
      Logger.error('Failed to send genui request', error, stackTrace);
      _errorController.add(ContentGeneratorError(error.toString()));
      _isProcessing.value = false;
    }
  }

  void _handleSseMessage(SseMessage sseMessage) {
    if (sseMessage.isDone) {
      _isProcessing.value = false;
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

      if (type == 'text') {
        final text = decoded['content'] as String? ?? '';
        _textController.add(text);
        return;
      }

      // Parse as A2UI message
      final a2uiMessage = AgentToRendererMessage.fromJson(decoded);
      _a2uiController.add(a2uiMessage);
    } catch (error, stackTrace) {
      Logger.debug(
        'Non-A2UI SSE message, forwarding as text',
        error,
        stackTrace,
      );
      _textController.add(raw);
    }
  }

  /// Closes the connection and the streams.
  void dispose() {
    _activeConnection?.close();
    _a2uiController.close();
    _errorController.close();
    _textController.close();
    _isProcessing.dispose();
  }
}
