import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_generator_config.freezed.dart';
part 'content_generator_config.g.dart';

/// Configuration for the SSE-based content generator.
@freezed
sealed class ContentGeneratorConfig with _$ContentGeneratorConfig {
  const factory ContentGeneratorConfig({
    /// The SSE endpoint URL for the genui chat API.
    required String serverUrl,

    /// Optional authorization token.
    String? authToken,

    /// Additional headers to include in SSE requests.
    @Default({}) Map<String, String> headers,
  }) = _ContentGeneratorConfig;

  factory ContentGeneratorConfig.fromJson(Map<String, dynamic> json) =>
      _$ContentGeneratorConfigFromJson(json);
}
