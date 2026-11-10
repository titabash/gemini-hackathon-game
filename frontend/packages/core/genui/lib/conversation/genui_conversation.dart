import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/foundation.dart';

import '../content_generator/content_generator_error.dart';
import '../content_generator/sse_content_generator.dart';
import '../models/genui_message.dart';

/// Connects an [SseContentGenerator] to an A2UI [MessageProcessor] and keeps
/// the conversation history.
///
/// Replaces genui's `GenUiConversation`: A2UI messages from the generator go
/// to [processor], user actions on its surfaces are sent back as requests,
/// and text, surfaces and errors are recorded in [conversation].
class GenuiConversation {
  GenuiConversation({required this.contentGenerator, required this.processor}) {
    _a2uiSubscription = contentGenerator.a2uiMessageStream.listen(
      processor.processMessages,
    );
    _textResponseSubscription = contentGenerator.textResponseStream.listen(
      _handleTextResponse,
    );
    _errorSubscription = contentGenerator.errorStream.listen(_handleError);
    _modelSubscriptions = [
      processor.model.onSurfaceCreated.subscribe(_handleSurfaceCreated),
      processor.model.onSurfaceDeleted.subscribe(_handleSurfaceDeleted),
      processor.model.onAction.subscribe(_handleAction),
      processor.model.onError.subscribe(_handleRendererError),
    ];
  }

  /// The generator that talks to the backend.
  final SseContentGenerator contentGenerator;

  /// The processor that holds the surfaces.
  final MessageProcessor<ComponentImplementation> processor;

  late final StreamSubscription<AgentToRendererMessage> _a2uiSubscription;
  late final StreamSubscription<String> _textResponseSubscription;
  late final StreamSubscription<ContentGeneratorError> _errorSubscription;
  late final List<Subscription> _modelSubscriptions;

  final ValueNotifier<List<GenuiMessage>> _conversation =
      ValueNotifier<List<GenuiMessage>>([]);

  /// The conversation history.
  ValueListenable<List<GenuiMessage>> get conversation => _conversation;

  /// Whether the generator is currently processing a request.
  ValueListenable<bool> get isProcessing => contentGenerator.isProcessing;

  /// Sends a user message, with the history and the renderer capabilities.
  Future<void> sendRequest(String text) {
    final List<GenuiMessage> history = _conversation.value;
    _conversation.value = [...history, GenuiMessage.user(text: text)];
    return _send(text, history);
  }

  Future<void> _send(String text, List<GenuiMessage> history) {
    final capabilities = processor
        .getRendererCapabilities(
          const CapabilitiesOptions(versions: [A2uiProtocolVersion.v0_9]),
        )
        .toJson();
    return contentGenerator.sendRequest(
      text,
      history: history,
      clientCapabilities: capabilities,
    );
  }

  void _handleAction(A2uiRendererAction action) {
    // As with genui, a user action is sent as a message whose text is the
    // action JSON, and it is not added to the history.
    unawaited(
      _send(jsonEncode({'userAction': action.toJson()}), _conversation.value),
    );
  }

  void _handleSurfaceCreated(SurfaceModel<ComponentImplementation> surface) {
    _conversation.value = [
      ..._conversation.value,
      GenuiMessage.assistant(text: '', surfaceIds: [surface.id]),
    ];
  }

  void _handleSurfaceDeleted(String surfaceId) {
    _conversation.value = [
      for (final message in _conversation.value)
        if (message is! GenuiMessageAssistant ||
            !(message.surfaceIds?.contains(surfaceId) ?? false))
          message,
    ];
  }

  void _handleTextResponse(String text) {
    _conversation.value = [
      ..._conversation.value,
      GenuiMessage.assistant(text: text),
    ];
  }

  void _handleError(ContentGeneratorError error) {
    _conversation.value = [
      ..._conversation.value,
      GenuiMessage.assistant(text: 'An error occurred: ${error.error}'),
    ];
  }

  void _handleRendererError(A2uiRendererError error) {
    Logger.warning('A2UI error ${error.code}: ${error.message}');
  }

  /// Cancels the subscriptions and disposes of the generator and the
  /// processor.
  void dispose() {
    _a2uiSubscription.cancel();
    _textResponseSubscription.cancel();
    _errorSubscription.cancel();
    for (final subscription in _modelSubscriptions) {
      subscription.unsubscribe();
    }
    contentGenerator.dispose();
    processor.dispose();
    _conversation.dispose();
  }
}
