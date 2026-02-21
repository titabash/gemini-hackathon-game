import 'package:core_api/core_api.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SseMessage', () {
    test('parses JSON payloads safely', () {
      const raw = '{"type":"data","data":{"value":1},"code":200}';

      final message = SseMessage.fromRaw(raw);

      expect(message.type, 'data');
      expect(message.payload, isNotNull);
      expect(message.payload?['value'], 1);
      expect(message.code, 200);
      expect(message.isError, isFalse);
      expect(message.isDone, isFalse);
    });

    test('falls back to raw string when JSON decoding fails', () {
      const raw = 'not-json';

      final message = SseMessage.fromRaw(raw);

      expect(message.raw, raw);
      expect(message.payload, isNull);
      expect(message.type, isNull);
      expect(message.isError, isFalse);
    });

    test('enriches messages created from SSEModel metadata', () {
      const raw = '{"type":"done","data":{"result":"ok"}}';
      final model = SSEModel(data: raw, id: 'evt-1', event: 'stream');

      final message = SseMessage.fromModel(model);

      expect(message.event, 'stream');
      expect(message.id, 'evt-1');
      expect(message.isDone, isTrue);
      expect(message.payload?['result'], 'ok');
    });
  });
}
