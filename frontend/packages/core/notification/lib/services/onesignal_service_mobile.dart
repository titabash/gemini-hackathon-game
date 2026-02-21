import 'dart:async';

import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../models/notification_event.dart';
import '../models/notification_permission_state.dart';
import 'notification_service_interface.dart';

/// OneSignal通知サービス（iOS/Android向け実装）
///
/// OneSignal SDKのラッパーとして機能し、
/// 通知の初期化、パーミッション管理、イベント処理を担当
class OneSignalService implements NotificationService {
  OneSignalService({required String appId}) : _appId = appId;

  final String _appId;

  /// 通知受信イベントストリーム
  @override
  Stream<NotificationEvent> get onNotificationReceived =>
      _notificationReceivedController.stream;

  /// 通知オープンイベントストリーム
  @override
  Stream<NotificationEvent> get onNotificationOpened =>
      _notificationOpenedController.stream;

  /// パーミッション状態変更ストリーム
  @override
  Stream<NotificationPermissionState> get onPermissionStateChanged =>
      _permissionStateController.stream;

  final _notificationReceivedController =
      StreamController<NotificationEvent>.broadcast();
  final _notificationOpenedController =
      StreamController<NotificationEvent>.broadcast();
  final _permissionStateController =
      StreamController<NotificationPermissionState>.broadcast();

  bool _isInitialized = false;

  /// OneSignalを初期化
  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    // OneSignalの初期化
    OneSignal.initialize(_appId);

    // 通知受信リスナー
    OneSignal.Notifications.addForegroundWillDisplayListener((
      OSNotificationWillDisplayEvent event,
    ) {
      // フォアグラウンドで通知を表示
      event.notification.display();

      _notificationReceivedController.add(
        NotificationEvent(
          notificationId: event.notification.notificationId,
          title: event.notification.title,
          body: event.notification.body,
          additionalData: event.notification.additionalData,
          isAction: false,
          receivedAt: DateTime.now(),
        ),
      );
    });

    // 通知クリックリスナー
    OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
      _notificationOpenedController.add(
        NotificationEvent(
          notificationId: event.notification.notificationId,
          title: event.notification.title,
          body: event.notification.body,
          additionalData: event.notification.additionalData,
          isAction: true,
          receivedAt: DateTime.now(),
        ),
      );
    });

    // パーミッション状態リスナー
    OneSignal.Notifications.addPermissionObserver((bool isGranted) {
      _updatePermissionState();
    });

    _isInitialized = true;

    // 初期パーミッション状態を取得
    await _updatePermissionState();
  }

  /// パーミッション状態を更新
  Future<void> _updatePermissionState() async {
    final permission = OneSignal.Notifications.permission;
    final pushToken = OneSignal.User.pushSubscription.token;
    final subscriptionId = OneSignal.User.pushSubscription.id;

    _permissionStateController.add(
      NotificationPermissionState(
        areNotificationsEnabled: permission,
        isPushDisabled: !permission,
        pushToken: pushToken,
        subscriptionId: subscriptionId,
      ),
    );
  }

  /// 通知パーミッションをリクエスト
  @override
  Future<bool> requestPermission() async {
    return OneSignal.Notifications.requestPermission(true);
  }

  /// 現在のパーミッション状態を取得
  @override
  NotificationPermissionState getPermissionState() {
    final permission = OneSignal.Notifications.permission;
    final pushToken = OneSignal.User.pushSubscription.token;
    final subscriptionId = OneSignal.User.pushSubscription.id;

    return NotificationPermissionState(
      areNotificationsEnabled: permission,
      isPushDisabled: !permission,
      pushToken: pushToken,
      subscriptionId: subscriptionId,
    );
  }

  /// 外部ユーザーIDを設定（Supabase User IDなど）
  @override
  Future<void> setExternalUserId(String externalUserId) async {
    await OneSignal.login(externalUserId);
  }

  /// 外部ユーザーIDを削除（ログアウト時）
  @override
  Future<void> removeExternalUserId() async {
    await OneSignal.logout();
  }

  /// タグを設定（カスタムデータ）
  @override
  Future<void> setTags(Map<String, String> tags) async {
    await OneSignal.User.addTags(tags);
  }

  /// タグを削除
  @override
  Future<void> deleteTags(List<String> keys) async {
    await OneSignal.User.removeTags(keys);
  }

  /// リソースを解放
  @override
  void dispose() {
    _notificationReceivedController.close();
    _notificationOpenedController.close();
    _permissionStateController.close();
  }
}

/// OneSignalServiceのファクトリ関数
NotificationService createNotificationService({required String appId}) {
  return OneSignalService(appId: appId);
}
