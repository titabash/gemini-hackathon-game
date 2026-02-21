import 'package:freezed_annotation/freezed_annotation.dart';
import 'session_status.dart';

part 'game_session.freezed.dart';
part 'game_session.g.dart';

/// ゲームセッション（DB sessions テーブルに対応）
@freezed
sealed class GameSession with _$GameSession {
  const factory GameSession({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'scenario_id') required String scenarioId,
    @Default('') String title,
    @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
    @Default(SessionStatus.active)
    SessionStatus status,
    @JsonKey(name: 'current_state') required Map<String, dynamic> currentState,
    @JsonKey(name: 'current_turn_number') @Default(0) int currentTurnNumber,
    @JsonKey(name: 'ending_summary') String? endingSummary,
    @JsonKey(name: 'ending_type') String? endingType,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _GameSession;

  factory GameSession.fromJson(Map<String, dynamic> json) =>
      _$GameSessionFromJson(json);
}

SessionStatus _statusFromJson(String value) => SessionStatus.fromString(value);

String _statusToJson(SessionStatus status) => status.name;
