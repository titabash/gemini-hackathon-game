import 'dart:async';
import 'dart:convert';

import 'package:core_api/core_api.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import 'content_generator_config.dart';

/// Extracts text content from a [ChatMessage].
String _extractText(ChatMessage message) {
  return switch (message) {
    UserMessage(:final text) => text,
    AiTextMessage(:final text) => text,
    UserUiInteractionMessage(:final text) => text,
    InternalMessage(:final text) => text,
    AiUiMessage() => '',
    ToolResponseMessage() => '',
  };
}

/// A [ContentGenerator] that connects to a Python FastAPI backend via SSE.
///
/// Uses [SseClientFactory] from core_api to establish the connection and
/// streams A2UI protocol messages back to the genui SDK.
class SseContentGenerator implements ContentGenerator {
  SseContentGenerator({required this.config, required this.sseClientFactory});

  final ContentGeneratorConfig config;
  final SseClientFactory sseClientFactory;

  final StreamController<A2uiMessage> _a2uiController =
      StreamController<A2uiMessage>.broadcast();
  final StreamController<ContentGeneratorError> _errorController =
      StreamController<ContentGeneratorError>.broadcast();
  final StreamController<String> _textController =
      StreamController<String>.broadcast();
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);

  SseConnection? _activeConnection;

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  Stream<String> get textResponseStream => _textController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) async {
    _isProcessing.value = true;

    try {
      _activeConnection?.close();

      final payload = <String, dynamic>{
        'message': _extractText(message),
        if (history != null)
          'history': history
              .map(
                (m) => {
                  'role': m is UserMessage ? 'user' : 'model',
                  'text': _extractText(m),
                },
              )
              .toList(),
        if (clientCapabilities != null)
          'client_capabilities': clientCapabilities.toJson(),
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
      final a2uiMessage = A2uiMessage.fromJson(decoded);
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

  @override
  void dispose() {
    _activeConnection?.close();
    _a2uiController.close();
    _errorController.close();
    _textController.close();
    _isProcessing.dispose();
  }
}
