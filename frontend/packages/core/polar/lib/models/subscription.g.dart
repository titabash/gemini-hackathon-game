// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    _Subscription(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      status: $enumDecode(_$SubscriptionStatusEnumMap, json['status']),
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      recurringInterval: $enumDecode(
        _$RecurringIntervalEnumMap,
        json['recurringInterval'],
      ),
      currentPeriodStart: DateTime.parse(json['currentPeriodStart'] as String),
      currentPeriodEnd: json['currentPeriodEnd'] == null
          ? null
          : DateTime.parse(json['currentPeriodEnd'] as String),
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool,
      canceledAt: json['canceledAt'] == null
          ? null
          : DateTime.parse(json['canceledAt'] as String),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      endsAt: json['endsAt'] == null
          ? null
          : DateTime.parse(json['endsAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      productId: json['productId'] as String,
      priceId: json['priceId'] as String,
      customerId: json['customerId'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SubscriptionToJson(
  _Subscription instance,
) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt.toIso8601String(),
  'modifiedAt': instance.modifiedAt?.toIso8601String(),
  'status': _$SubscriptionStatusEnumMap[instance.status]!,
  'amount': instance.amount,
  'currency': instance.currency,
  'recurringInterval': _$RecurringIntervalEnumMap[instance.recurringInterval]!,
  'currentPeriodStart': instance.currentPeriodStart.toIso8601String(),
  'currentPeriodEnd': instance.currentPeriodEnd?.toIso8601String(),
  'cancelAtPeriodEnd': instance.cancelAtPeriodEnd,
  'canceledAt': instance.canceledAt?.toIso8601String(),
  'startedAt': instance.startedAt?.toIso8601String(),
  'endsAt': instance.endsAt?.toIso8601String(),
  'endedAt': instance.endedAt?.toIso8601String(),
  'productId': instance.productId,
  'priceId': instance.priceId,
  'customerId': instance.customerId,
  'metadata': instance.metadata,
};

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.incomplete: 'incomplete',
  SubscriptionStatus.incompleteExpired: 'incomplete_expired',
  SubscriptionStatus.trialing: 'trialing',
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.pastDue: 'past_due',
  SubscriptionStatus.canceled: 'canceled',
  SubscriptionStatus.unpaid: 'unpaid',
};

const _$RecurringIntervalEnumMap = {
  RecurringInterval.day: 'day',
  RecurringInterval.week: 'week',
  RecurringInterval.month: 'month',
  RecurringInterval.year: 'year',
};
