import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_event.freezed.dart';
part 'game_event.g.dart';

/// Events emitted by the game engine for consumption by the app layer.
@freezed
sealed class GameEvent with _$GameEvent {
  const factory GameEvent.started() = GameEventStarted;
  const factory GameEvent.paused() = GameEventPaused;
  const factory GameEvent.resumed() = GameEventResumed;
  const factory GameEvent.scored({required int points}) = GameEventScored;
  const factory GameEvent.ended({
    required int finalScore,
    Map<String, dynamic>? metadata,
  }) = GameEventEnded;
  const factory GameEvent.custom({
    required String name,
    Map<String, dynamic>? data,
  }) = GameEventCustom;

  factory GameEvent.fromJson(Map<String, dynamic> json) =>
      _$GameEventFromJson(json);
}
