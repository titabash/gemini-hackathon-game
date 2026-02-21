import 'package:freezed_annotation/freezed_annotation.dart';

part 'scenario.freezed.dart';
part 'scenario.g.dart';

/// シナリオテンプレート（DB scenarios テーブルに対応）
@freezed
sealed class Scenario with _$Scenario {
  const factory Scenario({
    required String id,
    required String title,
    @Default('') String description,
    @JsonKey(name: 'initial_state') required Map<String, dynamic> initialState,
    @JsonKey(name: 'win_conditions') required List<dynamic> winConditions,
    @JsonKey(name: 'fail_conditions') required List<dynamic> failConditions,
    @JsonKey(name: 'thumbnail_path') String? thumbnailPath,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'is_public') @Default(true) bool isPublic,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Scenario;

  factory Scenario.fromJson(Map<String, dynamic> json) =>
      _$ScenarioFromJson(json);
}
