// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationEvent _$NotificationEventFromJson(Map<String, dynamic> json) =>
    _NotificationEvent(
      notificationId: json['notificationId'] as String,
      title: json['title'] as String?,
      body: json['body'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      isAction: json['isAction'] as bool,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
    );

Map<String, dynamic> _$NotificationEventToJson(_NotificationEvent instance) =>
    <String, dynamic>{
      'notificationId': instance.notificationId,
      'title': instance.title,
      'body': instance.body,
      'additionalData': instance.additionalData,
      'isAction': instance.isAction,
      'receivedAt': instance.receivedAt.toIso8601String(),
    };
