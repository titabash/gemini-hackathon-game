import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_config.freezed.dart';
part 'game_config.g.dart';

/// Configuration for the game engine.
@freezed
sealed class GameConfig with _$GameConfig {
  const factory GameConfig({
    @Default(60) int targetFps,
    @Default(true) bool pauseWhenBackgrounded,
    @Default(false) bool debugMode,
    Map<String, dynamic>? customSettings,
  }) = _GameConfig;

  factory GameConfig.fromJson(Map<String, dynamic> json) =>
      _$GameConfigFromJson(json);
}
