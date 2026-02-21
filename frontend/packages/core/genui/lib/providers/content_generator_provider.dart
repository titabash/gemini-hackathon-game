import 'package:core_api/core_api.dart';
import 'package:genui/genui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../content_generator/content_generator_config.dart';
import '../content_generator/sse_content_generator.dart';

part 'content_generator_provider.g.dart';

const _defaultGenuiUrl = String.fromEnvironment(
  'GENUI_SERVER_URL',
  defaultValue: 'http://localhost:8000/api/genui/chat',
);

/// Provides a [ContentGenerator] backed by the SSE content generator.
///
/// Override [contentGeneratorConfigProvider] to customise the endpoint.
@Riverpod(keepAlive: true)
ContentGeneratorConfig contentGeneratorConfig(Ref ref) {
  return ContentGeneratorConfig(serverUrl: _defaultGenuiUrl);
}

/// Provides the [SseContentGenerator] instance.
@Riverpod(keepAlive: true)
ContentGenerator contentGenerator(Ref ref) {
  final config = ref.watch(contentGeneratorConfigProvider);
  final sseFactory = ref.watch(sseClientFactoryProvider);

  final generator = SseContentGenerator(
    config: config,
    sseClientFactory: sseFactory,
  );

  ref.onDispose(generator.dispose);

  return generator;
}
