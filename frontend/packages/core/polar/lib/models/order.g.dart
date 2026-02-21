// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: json['id'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  modifiedAt: json['modifiedAt'] == null
      ? null
      : DateTime.parse(json['modifiedAt'] as String),
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  amount: (json['amount'] as num).toInt(),
  currency: json['currency'] as String,
  productId: json['productId'] as String,
  productPriceId: json['productPriceId'] as String,
  customerId: json['customerId'] as String,
  checkoutId: json['checkoutId'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt.toIso8601String(),
  'modifiedAt': instance.modifiedAt?.toIso8601String(),
  'status': _$OrderStatusEnumMap[instance.status]!,
  'amount': instance.amount,
  'currency': instance.currency,
  'productId': instance.productId,
  'productPriceId': instance.productPriceId,
  'customerId': instance.customerId,
  'checkoutId': instance.checkoutId,
  'metadata': instance.metadata,
};

const _$OrderStatusEnumMap = {
  OrderStatus.paid: 'paid',
  OrderStatus.refunded: 'refunded',
  OrderStatus.partiallyRefunded: 'partially_refunded',
};
