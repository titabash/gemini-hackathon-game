import 'package:freezed_annotation/freezed_annotation.dart';

part 'genui_message.freezed.dart';
part 'genui_message.g.dart';

/// Wrapper around messages exchanged in a genui conversation.
@freezed
sealed class GenuiMessage with _$GenuiMessage {
  const factory GenuiMessage.user({required String text}) = GenuiMessageUser;
  const factory GenuiMessage.assistant({
    required String text,
    List<String>? surfaceIds,
  }) = GenuiMessageAssistant;
  const factory GenuiMessage.system({required String text}) =
      GenuiMessageSystem;

  factory GenuiMessage.fromJson(Map<String, dynamic> json) =>
      _$GenuiMessageFromJson(json);
}
