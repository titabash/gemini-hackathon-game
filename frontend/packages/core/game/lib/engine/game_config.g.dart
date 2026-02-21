// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameConfig _$GameConfigFromJson(Map<String, dynamic> json) => _GameConfig(
  targetFps: (json['targetFps'] as num?)?.toInt() ?? 60,
  pauseWhenBackgrounded: json['pauseWhenBackgrounded'] as bool? ?? true,
  debugMode: json['debugMode'] as bool? ?? false,
  customSettings: json['customSettings'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$GameConfigToJson(_GameConfig instance) =>
    <String, dynamic>{
      'targetFps': instance.targetFps,
      'pauseWhenBackgrounded': instance.pauseWhenBackgrounded,
      'debugMode': instance.debugMode,
      'customSettings': instance.customSettings,
    };
