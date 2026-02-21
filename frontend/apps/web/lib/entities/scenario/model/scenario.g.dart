// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Scenario _$ScenarioFromJson(Map<String, dynamic> json) => _Scenario(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  initialState: json['initial_state'] as Map<String, dynamic>,
  winConditions: json['win_conditions'] as List<dynamic>,
  failConditions: json['fail_conditions'] as List<dynamic>,
  thumbnailPath: json['thumbnail_path'] as String?,
  createdBy: json['created_by'] as String?,
  isPublic: json['is_public'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ScenarioToJson(_Scenario instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'initial_state': instance.initialState,
  'win_conditions': instance.winConditions,
  'fail_conditions': instance.failConditions,
  'thumbnail_path': instance.thumbnailPath,
  'created_by': instance.createdBy,
  'is_public': instance.isPublic,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
