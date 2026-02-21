// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'genui_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenuiMessageUser _$GenuiMessageUserFromJson(Map<String, dynamic> json) =>
    GenuiMessageUser(
      text: json['text'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GenuiMessageUserToJson(GenuiMessageUser instance) =>
    <String, dynamic>{'text': instance.text, 'runtimeType': instance.$type};

GenuiMessageAssistant _$GenuiMessageAssistantFromJson(
  Map<String, dynamic> json,
) => GenuiMessageAssistant(
  text: json['text'] as String,
  surfaceIds: (json['surfaceIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$GenuiMessageAssistantToJson(
  GenuiMessageAssistant instance,
) => <String, dynamic>{
  'text': instance.text,
  'surfaceIds': instance.surfaceIds,
  'runtimeType': instance.$type,
};

GenuiMessageSystem _$GenuiMessageSystemFromJson(Map<String, dynamic> json) =>
    GenuiMessageSystem(
      text: json['text'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GenuiMessageSystemToJson(GenuiMessageSystem instance) =>
    <String, dynamic>{'text': instance.text, 'runtimeType': instance.$type};
