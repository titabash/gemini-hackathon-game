import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// 仮アカウント名のパターン（auth hook で自動生成: user_[hex8桁]）
final _temporaryAccountNamePattern = RegExp(r'^user_[0-9a-f]{8}$');

/// ユーザープロフィール（DB users テーブルに対応）
@freezed
sealed class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String id,
    @JsonKey(name: 'account_name') required String accountName,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @JsonKey(name: 'avatar_path') String? avatarPath,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  /// オンボーディングが必要かどうか（仮アカウント名パターンに一致する場合 true）
  bool get needsOnboarding =>
      _temporaryAccountNamePattern.hasMatch(accountName);
}
