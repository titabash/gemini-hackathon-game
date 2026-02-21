// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_permission_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationPermissionState _$NotificationPermissionStateFromJson(
  Map<String, dynamic> json,
) => _NotificationPermissionState(
  areNotificationsEnabled: json['areNotificationsEnabled'] as bool,
  isPushDisabled: json['isPushDisabled'] as bool,
  pushToken: json['pushToken'] as String?,
  subscriptionId: json['subscriptionId'] as String?,
);

Map<String, dynamic> _$NotificationPermissionStateToJson(
  _NotificationPermissionState instance,
) => <String, dynamic>{
  'areNotificationsEnabled': instance.areNotificationsEnabled,
  'isPushDisabled': instance.isPushDisabled,
  'pushToken': instance.pushToken,
  'subscriptionId': instance.subscriptionId,
};
