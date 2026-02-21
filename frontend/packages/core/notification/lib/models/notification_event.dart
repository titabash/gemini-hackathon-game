import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_event.freezed.dart';
part 'notification_event.g.dart';

/// 通知イベント（受信した通知データ）
@freezed
class NotificationEvent with _$NotificationEvent {
  const factory NotificationEvent({
    /// 通知ID
    required String notificationId,

    /// 通知タイトル
    String? title,

    /// 通知本文
    String? body,

    /// 追加データ
    Map<String, dynamic>? additionalData,

    /// アクション可能か（タップされたか）
    required bool isAction,

    /// 受信時刻
    required DateTime receivedAt,
  }) = _NotificationEvent;

  factory NotificationEvent.fromJson(Map<String, dynamic> json) =>
      _$NotificationEventFromJson(json);
}
