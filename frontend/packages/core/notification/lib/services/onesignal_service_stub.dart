import 'dart:async';

import '../models/notification_event.dart';
import '../models/notification_permission_state.dart';
import 'notification_service_interface.dart';

/// OneSignal通知サービス（Web向けスタブ実装）
///
/// Webプラットフォームでは OneSignal Flutter SDK が利用できないため、
/// このスタブ実装が使用される。
/// Web向けプッシュ通知が必要な場合は、OneSignal Web SDKを別途統合する必要がある。
class OneSignalService implements NotificationService {
  OneSignalService({required String appId}) : _appId = appId;

  // ignore: unused_field
  final String _appId;

  /// 通知受信イベントストリーム（Webでは空）
  @override
  Stream<NotificationEvent> get onNotificationReceived =>
      _notificationReceivedController.stream;

  /// 通知オープンイベントストリーム（Webでは空）
  @override
  Stream<NotificationEvent> get onNotificationOpened =>
      _notificationOpenedController.stream;

  /// パーミッション状態変更ストリーム（Webでは空）
  @override
  Stream<NotificationPermissionState> get onPermissionStateChanged =>
      _permissionStateController.stream;

  final _notificationReceivedController =
      StreamController<NotificationEvent>.broadcast();
  final _notificationOpenedController =
      StreamController<NotificationEvent>.broadcast();
  final _permissionStateController =
      StreamController<NotificationPermissionState>.broadcast();

  /// Webでは初期化は何もしない
  @override
  Future<void> initialize() async {
    // Web platform does not support OneSignal Flutter SDK
    // Emit initial permission state (disabled)
    _permissionStateController.add(NotificationPermissionState.initial());
  }

  /// Webでは常にfalseを返す
  @override
  Future<bool> requestPermission() async {
    // Web platform does not support OneSignal Flutter SDK
    return false;
  }

  /// Webでは常に初期状態を返す
  @override
  NotificationPermissionState getPermissionState() {
    // Web platform does not support OneSignal Flutter SDK
    return NotificationPermissionState.initial();
  }

  /// Webでは何もしない
  @override
  Future<void> setExternalUserId(String externalUserId) async {
    // Web platform does not support OneSignal Flutter SDK
  }

  /// Webでは何もしない
  @override
  Future<void> removeExternalUserId() async {
    // Web platform does not support OneSignal Flutter SDK
  }

  /// Webでは何もしない
  @override
  Future<void> setTags(Map<String, String> tags) async {
    // Web platform does not support OneSignal Flutter SDK
  }

  /// Webでは何もしない
  @override
  Future<void> deleteTags(List<String> keys) async {
    // Web platform does not support OneSignal Flutter SDK
  }

  /// リソースを解放
  @override
  void dispose() {
    _notificationReceivedController.close();
    _notificationOpenedController.close();
    _permissionStateController.close();
  }
}

/// OneSignalServiceのファクトリ関数（Webスタブ版）
NotificationService createNotificationService({required String appId}) {
  return OneSignalService(appId: appId);
}
