import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

/// Game lifecycle state represented as a Freezed union type.
///
/// Bridges Flame engine state to Riverpod by exposing a [ValueNotifier]
/// from [BaseGame].
@freezed
sealed class GameState with _$GameState {
  const factory GameState.initial() = GameStateInitial;
  const factory GameState.loading({String? message}) = GameStateLoading;
  const factory GameState.playing() = GameStatePlaying;
  const factory GameState.paused() = GameStatePaused;
  const factory GameState.gameOver({
    @Default(0) int score,
    Map<String, dynamic>? metadata,
  }) = GameStateGameOver;
  const factory GameState.error({required String message, Object? error}) =
      GameStateError;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
}
