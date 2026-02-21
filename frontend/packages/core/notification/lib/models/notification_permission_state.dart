import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_permission_state.freezed.dart';
part 'notification_permission_state.g.dart';

/// 通知パーミッション状態
@freezed
class NotificationPermissionState with _$NotificationPermissionState {
  const factory NotificationPermissionState({
    /// パーミッションが許可されているか
    required bool areNotificationsEnabled,

    /// プッシュ通知が許可されているか
    required bool isPushDisabled,

    /// プッシュトークン（デバイストークン）
    String? pushToken,

    /// OneSignal Player ID (Subscription ID)
    String? subscriptionId,
  }) = _NotificationPermissionState;

  factory NotificationPermissionState.fromJson(Map<String, dynamic> json) =>
      _$NotificationPermissionStateFromJson(json);

  /// 初期状態（未許可）
  factory NotificationPermissionState.initial() =>
      const NotificationPermissionState(
        areNotificationsEnabled: false,
        isPushDisabled: true,
        pushToken: null,
        subscriptionId: null,
      );
}
