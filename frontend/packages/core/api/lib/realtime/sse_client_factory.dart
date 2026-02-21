import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sse_client_factory.g.dart';

const _defaultSseUrl = String.fromEnvironment(
  'SSE_SERVER_URL',
  defaultValue: 'http://localhost:4040/sse',
);

const _defaultSseDebugKey = String.fromEnvironment(
  'SSE_DEBUG_KEY',
  defaultValue: '',
);

@Riverpod(keepAlive: true)
SseClientConfig sseClientConfig(Ref ref) {
  final defaultUri = Uri.tryParse(_defaultSseUrl);
  final debugKey = _defaultSseDebugKey.isEmpty
      ? null
      : _defaultSseDebugKey.trim();

  final defaultHeaders = <String, String>{
    if (debugKey != null) 'X-Debug-Key': debugKey,
  };

  return SseClientConfig(
    serverUrl: defaultUri,
    headers: defaultHeaders.isEmpty ? null : defaultHeaders,
  );
}

@Riverpod(keepAlive: true)
SseClientFactory sseClientFactory(Ref ref) {
  final config = ref.watch(sseClientConfigProvider);
  return SseClientFactory(
    defaultServerUrl: config.serverUrl,
    defaultHeaders: config.headers,
  );
}

/// SSE client configuration resolved from Dart defines.
class SseClientConfig {
  const SseClientConfig({this.serverUrl, this.headers});

  final Uri? serverUrl;
  final Map<String, String>? headers;
}

/// Factory that builds SSE connections backed by flutter_client_sse.
class SseClientFactory {
  const SseClientFactory({this.defaultServerUrl, this.defaultHeaders});

  final Uri? defaultServerUrl;
  final Map<String, String>? defaultHeaders;

  /// Establishes a new SSE connection.
  ///
  /// When [serverUrl] is omitted, [defaultServerUrl] is used. The
  /// optional [initialPayload] is sent as the POST body before the
  /// stream starts. Set [method] to [SSERequestType.GET] when the SSE
  /// endpoint does not accept a body.
  Future<SseConnection> connect({
    Uri? serverUrl,
    Map<String, dynamic>? initialPayload,
    Map<String, String>? headers,
    SSERequestType method = SSERequestType.POST,
  }) async {
    final target = serverUrl ?? defaultServerUrl;
    if (target == null) {
      throw ArgumentError(
        'SSE server URL is required. Provide one via connect() or SSE_SERVER_URL.',
      );
    }

    if (method == SSERequestType.GET && initialPayload != null) {
      throw ArgumentError('GET SSE requests cannot include a body.');
    }

    final mergedHeaders = <String, String>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      if (initialPayload != null) 'Content-Type': 'application/json',
      ...?defaultHeaders,
      ...?headers,
    };

    final rawStream = SSEClient.subscribeToSSE(
      method: method,
      url: target.toString(),
      header: mergedHeaders,
      body: initialPayload,
    ).asBroadcastStream();

    return SseConnection._(rawStream);
  }
}

/// Represents an active SSE connection.
class SseConnection {
  SseConnection._(Stream<SSEModel> source)
    : _rawStream = source,
      _messages = source.map(SseMessage.fromModel).asBroadcastStream();

  final Stream<SSEModel> _rawStream;
  final Stream<SseMessage> _messages;

  /// Raw `flutter_client_sse` events.
  Stream<SSEModel> get rawEvents => _rawStream;

  /// Parsed representation exposed to feature code.
  Stream<SseMessage> get messages => _messages;

  /// Shutdown the underlying SSE HTTP client. Note: This affects all
  /// connections opened via `flutter_client_sse` because it maintains a
  /// single shared HTTP client.
  void close() {
    SSEClient.unsubscribeFromSSE();
  }
}

/// Parsed representation of an SSE message payload.
class SseMessage {
  SseMessage({
    required this.raw,
    this.type,
    this.payload,
    this.error,
    this.code,
    this.event,
    this.id,
  });

  factory SseMessage.fromModel(SSEModel model) {
    final rawData = model.data ?? '';
    final parsed = _ParsedSsePayload.parse(rawData);
    return SseMessage(
      raw: parsed.raw,
      type: parsed.type ?? model.event,
      payload: parsed.payload,
      error: parsed.error,
      code: parsed.code,
      event: model.event,
      id: model.id,
    );
  }

  factory SseMessage.fromRaw(String raw) {
    final parsed = _ParsedSsePayload.parse(raw);
    return SseMessage(
      raw: parsed.raw,
      type: parsed.type,
      payload: parsed.payload,
      error: parsed.error,
      code: parsed.code,
    );
  }

  final String raw;
  final String? type;
  final Map<String, dynamic>? payload;
  final String? error;
  final int? code;
  final String? event;
  final String? id;

  bool get isError => type == 'error' || error != null;

  bool get isDone => type == 'done';
}

class _ParsedSsePayload {
  _ParsedSsePayload({
    required this.raw,
    this.type,
    this.payload,
    this.error,
    this.code,
  });

  final String raw;
  final String? type;
  final Map<String, dynamic>? payload;
  final String? error;
  final int? code;

  static _ParsedSsePayload parse(String rawInput) {
    final trimmed = rawInput.trim();

    if (trimmed.isEmpty) {
      return _ParsedSsePayload(raw: '');
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return _ParsedSsePayload(
          raw: trimmed,
          type: decoded['type'] as String?,
          payload: _castPayload(decoded['data']),
          error: decoded['error'] as String?,
          code: (decoded['code'] as num?)?.toInt(),
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to decode SSE payload. Forwarding as raw string.',
        name: 'core_api.sse',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return _ParsedSsePayload(raw: trimmed);
  }
}

Map<String, dynamic>? _castPayload(dynamic candidate) {
  if (candidate is Map<String, dynamic>) {
    return candidate;
  }

  if (candidate is Map) {
    return candidate.map((key, value) => MapEntry(key.toString(), value));
  }

  return null;
}
