// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameSession _$GameSessionFromJson(Map<String, dynamic> json) => _GameSession(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  scenarioId: json['scenario_id'] as String,
  title: json['title'] as String? ?? '',
  status: json['status'] == null
      ? SessionStatus.active
      : _statusFromJson(json['status'] as String),
  currentState: json['current_state'] as Map<String, dynamic>,
  currentTurnNumber: (json['current_turn_number'] as num?)?.toInt() ?? 0,
  endingSummary: json['ending_summary'] as String?,
  endingType: json['ending_type'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$GameSessionToJson(_GameSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'scenario_id': instance.scenarioId,
      'title': instance.title,
      'status': _statusToJson(instance.status),
      'current_state': instance.currentState,
      'current_turn_number': instance.currentTurnNumber,
      'ending_summary': instance.endingSummary,
      'ending_type': instance.endingType,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
