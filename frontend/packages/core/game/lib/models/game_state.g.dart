// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameStateInitial _$GameStateInitialFromJson(Map<String, dynamic> json) =>
    GameStateInitial($type: json['runtimeType'] as String?);

Map<String, dynamic> _$GameStateInitialToJson(GameStateInitial instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

GameStateLoading _$GameStateLoadingFromJson(Map<String, dynamic> json) =>
    GameStateLoading(
      message: json['message'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GameStateLoadingToJson(GameStateLoading instance) =>
    <String, dynamic>{
      'message': instance.message,
      'runtimeType': instance.$type,
    };

GameStatePlaying _$GameStatePlayingFromJson(Map<String, dynamic> json) =>
    GameStatePlaying($type: json['runtimeType'] as String?);

Map<String, dynamic> _$GameStatePlayingToJson(GameStatePlaying instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

GameStatePaused _$GameStatePausedFromJson(Map<String, dynamic> json) =>
    GameStatePaused($type: json['runtimeType'] as String?);

Map<String, dynamic> _$GameStatePausedToJson(GameStatePaused instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

GameStateGameOver _$GameStateGameOverFromJson(Map<String, dynamic> json) =>
    GameStateGameOver(
      score: (json['score'] as num?)?.toInt() ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GameStateGameOverToJson(GameStateGameOver instance) =>
    <String, dynamic>{
      'score': instance.score,
      'metadata': instance.metadata,
      'runtimeType': instance.$type,
    };

GameStateError _$GameStateErrorFromJson(Map<String, dynamic> json) =>
    GameStateError(
      message: json['message'] as String,
      error: json['error'],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GameStateErrorToJson(GameStateError instance) =>
    <String, dynamic>{
      'message': instance.message,
      'error': instance.error,
      'runtimeType': instance.$type,
    };
