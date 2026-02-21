import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_state.freezed.dart';

/// State of a genui conversation session.
@freezed
sealed class ConversationState with _$ConversationState {
  const factory ConversationState.idle() = ConversationStateIdle;
  const factory ConversationState.processing() = ConversationStateProcessing;
  const factory ConversationState.error({required String message}) =
      ConversationStateError;
}
