import 'dart:async';

import '../models/notification_event.dart';
import '../models/notification_permission_state.dart';

/// 通知サービスの抽象インターフェース
///
/// プラットフォーム固有の実装を抽象化し、
/// Web（スタブ）とモバイル（OneSignal）で異なる実装を提供
abstract class NotificationService {
  /// 通知受信イベントストリーム
  Stream<NotificationEvent> get onNotificationReceived;

  /// 通知オープンイベントストリーム
  Stream<NotificationEvent> get onNotificationOpened;

  /// パーミッション状態変更ストリーム
  Stream<NotificationPermissionState> get onPermissionStateChanged;

  /// サービスを初期化
  Future<void> initialize();

  /// 通知パーミッションをリクエスト
  Future<bool> requestPermission();

  /// 現在のパーミッション状態を取得
  NotificationPermissionState getPermissionState();

  /// 外部ユーザーIDを設定（Supabase User IDなど）
  Future<void> setExternalUserId(String externalUserId);

  /// 外部ユーザーIDを削除（ログアウト時）
  Future<void> removeExternalUserId();

  /// タグを設定（カスタムデータ）
  Future<void> setTags(Map<String, String> tags);

  /// タグを削除
  Future<void> deleteTags(List<String> keys);

  /// リソースを解放
  void dispose();
}
