// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_generator_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContentGeneratorConfig _$ContentGeneratorConfigFromJson(
  Map<String, dynamic> json,
) => _ContentGeneratorConfig(
  serverUrl: json['serverUrl'] as String,
  authToken: json['authToken'] as String?,
  headers:
      (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
);

Map<String, dynamic> _$ContentGeneratorConfigToJson(
  _ContentGeneratorConfig instance,
) => <String, dynamic>{
  'serverUrl': instance.serverUrl,
  'authToken': instance.authToken,
  'headers': instance.headers,
};
