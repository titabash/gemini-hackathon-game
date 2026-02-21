// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Checkout _$CheckoutFromJson(Map<String, dynamic> json) => _Checkout(
  id: json['id'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  modifiedAt: json['modifiedAt'] == null
      ? null
      : DateTime.parse(json['modifiedAt'] as String),
  status: $enumDecode(_$CheckoutStatusEnumMap, json['status']),
  clientSecret: json['clientSecret'] as String,
  url: json['url'] as String,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  successUrl: json['successUrl'] as String,
  amount: (json['amount'] as num?)?.toInt(),
  currency: json['currency'] as String?,
  productId: json['productId'] as String,
  productPriceId: json['productPriceId'] as String,
  customerId: json['customerId'] as String?,
  customerEmail: json['customerEmail'] as String?,
  customerName: json['customerName'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$CheckoutToJson(_Checkout instance) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt.toIso8601String(),
  'modifiedAt': instance.modifiedAt?.toIso8601String(),
  'status': _$CheckoutStatusEnumMap[instance.status]!,
  'clientSecret': instance.clientSecret,
  'url': instance.url,
  'expiresAt': instance.expiresAt.toIso8601String(),
  'successUrl': instance.successUrl,
  'amount': instance.amount,
  'currency': instance.currency,
  'productId': instance.productId,
  'productPriceId': instance.productPriceId,
  'customerId': instance.customerId,
  'customerEmail': instance.customerEmail,
  'customerName': instance.customerName,
  'metadata': instance.metadata,
};

const _$CheckoutStatusEnumMap = {
  CheckoutStatus.open: 'open',
  CheckoutStatus.expired: 'expired',
  CheckoutStatus.confirmed: 'confirmed',
  CheckoutStatus.succeeded: 'succeeded',
  CheckoutStatus.failed: 'failed',
};
