// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameEventStarted _$GameEventStartedFromJson(Map<String, dynamic> json) =>
    GameEventStarted($type: json['runtimeType'] as String?);

Map<String, dynamic> _$GameEventStartedToJson(GameEventStarted instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

GameEventPaused _$GameEventPausedFromJson(Map<String, dynamic> json) =>
    GameEventPaused($type: json['runtimeType'] as String?);

Map<String, dynamic> _$GameEventPausedToJson(GameEventPaused instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

GameEventResumed _$GameEventResumedFromJson(Map<String, dynamic> json) =>
    GameEventResumed($type: json['runtimeType'] as String?);

Map<String, dynamic> _$GameEventResumedToJson(GameEventResumed instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

GameEventScored _$GameEventScoredFromJson(Map<String, dynamic> json) =>
    GameEventScored(
      points: (json['points'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GameEventScoredToJson(GameEventScored instance) =>
    <String, dynamic>{'points': instance.points, 'runtimeType': instance.$type};

GameEventEnded _$GameEventEndedFromJson(Map<String, dynamic> json) =>
    GameEventEnded(
      finalScore: (json['finalScore'] as num).toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GameEventEndedToJson(GameEventEnded instance) =>
    <String, dynamic>{
      'finalScore': instance.finalScore,
      'metadata': instance.metadata,
      'runtimeType': instance.$type,
    };

GameEventCustom _$GameEventCustomFromJson(Map<String, dynamic> json) =>
    GameEventCustom(
      name: json['name'] as String,
      data: json['data'] as Map<String, dynamic>?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GameEventCustomToJson(GameEventCustom instance) =>
    <String, dynamic>{
      'name': instance.name,
      'data': instance.data,
      'runtimeType': instance.$type,
    };
