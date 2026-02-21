import 'dart:async';
import 'dart:convert';

import 'package:core_api/core_api.dart';
import 'package:core_utils/core_utils.dart';

/// GM turn endpoint URL derived from BACKEND_URL.
const _backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:4040',
);
const gmServerUrl = '$_backendUrl/api/gm/turn';

/// Parsed SSE event from the GM backend.
sealed class GmEvent {
  const GmEvent();
}

/// Text chunk for typewriter streaming.
class GmTextEvent extends GmEvent {
  const GmTextEvent(this.content);
  final String content;
}

/// Surface update with a TRPG component.
class GmSurfaceUpdateEvent extends GmEvent {
  const GmSurfaceUpdateEvent({required this.component, required this.data});
  final String component;
  final Map<String, dynamic> data;
}

/// Game state update for Flame canvas (location, HP, NPCs, scene).
class GmStateUpdateEvent extends GmEvent {
  const GmStateUpdateEvent(this.data);
  final Map<String, dynamic> data;
}

/// GM stream is done.
class GmDoneEvent extends GmEvent {
  const GmDoneEvent();
}

/// Error from GM.
class GmErrorEvent extends GmEvent {
  const GmErrorEvent(this.message);
  final String message;
}

/// Background image path from storage ({bucket}/{objectPath}).
class GmImageEvent extends GmEvent {
  const GmImageEvent(this.path);
  final String path;
}

/// Sends a GM turn request and returns a stream of [GmEvent].
Stream<GmEvent> sendGmTurn({
  required SseClientFactory sseFactory,
  required String sessionId,
  required String inputType,
  required String inputText,
  String? authToken,
}) async* {
  final payload = <String, dynamic>{
    'session_id': sessionId,
    'input_type': inputType,
    'input_text': inputText,
  };

  final headers = <String, String>{
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  final connection = await sseFactory.connect(
    serverUrl: Uri.parse(gmServerUrl),
    initialPayload: payload,
    headers: headers,
  );

  var done = false;
  await for (final sseMessage in connection.messages) {
    final event = _parseSseMessage(sseMessage);
    if (event == null) continue;

    yield event;

    if (event is GmDoneEvent) {
      done = true;
      continue;
    }

    // After done, close once imageUpdate is received
    if (done && event is GmImageEvent) break;
  }
}

GmEvent? _parseSseMessage(SseMessage message) {
  if (message.isDone) return const GmDoneEvent();
  if (message.isError) {
    return GmErrorEvent(message.error ?? 'Unknown SSE error');
  }

  final raw = message.raw;
  if (raw.isEmpty) return null;

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;

    final type = decoded['type'] as String?;

    return switch (type) {
      'text' => GmTextEvent(decoded['content'] as String? ?? ''),
      'surfaceUpdate' => GmSurfaceUpdateEvent(
        component: decoded['component'] as String? ?? '',
        data: decoded['data'] as Map<String, dynamic>? ?? {},
      ),
      'stateUpdate' => GmStateUpdateEvent(
        decoded['data'] as Map<String, dynamic>? ?? {},
      ),
      'imageUpdate' => GmImageEvent(decoded['path'] as String? ?? ''),
      'done' => const GmDoneEvent(),
      'error' => GmErrorEvent(decoded['content'] as String? ?? 'Unknown'),
      _ => null,
    };
  } catch (e, st) {
    Logger.debug('Failed to parse GM SSE message', e, st);
    return null;
  }
}
