// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductPrice _$ProductPriceFromJson(Map<String, dynamic> json) =>
    _ProductPrice(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      type: $enumDecode(_$ProductPriceTypeEnumMap, json['type']),
      priceAmount: (json['priceAmount'] as num).toInt(),
      priceCurrency: json['priceCurrency'] as String,
      recurringInterval: $enumDecodeNullable(
        _$RecurringIntervalEnumMap,
        json['recurringInterval'],
      ),
    );

Map<String, dynamic> _$ProductPriceToJson(
  _ProductPrice instance,
) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt.toIso8601String(),
  'modifiedAt': instance.modifiedAt?.toIso8601String(),
  'type': _$ProductPriceTypeEnumMap[instance.type]!,
  'priceAmount': instance.priceAmount,
  'priceCurrency': instance.priceCurrency,
  'recurringInterval': _$RecurringIntervalEnumMap[instance.recurringInterval],
};

const _$ProductPriceTypeEnumMap = {
  ProductPriceType.oneTime: 'one_time',
  ProductPriceType.recurring: 'recurring',
};

const _$RecurringIntervalEnumMap = {
  RecurringInterval.day: 'day',
  RecurringInterval.week: 'week',
  RecurringInterval.month: 'month',
  RecurringInterval.year: 'year',
};

_ProductBenefit _$ProductBenefitFromJson(Map<String, dynamic> json) =>
    _ProductBenefit(id: json['id'] as String, type: json['type'] as String);

Map<String, dynamic> _$ProductBenefitToJson(_ProductBenefit instance) =>
    <String, dynamic>{'id': instance.id, 'type': instance.type};

_ProductMedia _$ProductMediaFromJson(Map<String, dynamic> json) =>
    _ProductMedia(
      id: json['id'] as String,
      publicUrl: json['publicUrl'] as String,
    );

Map<String, dynamic> _$ProductMediaToJson(_ProductMedia instance) =>
    <String, dynamic>{'id': instance.id, 'publicUrl': instance.publicUrl};

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: json['id'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  modifiedAt: json['modifiedAt'] == null
      ? null
      : DateTime.parse(json['modifiedAt'] as String),
  name: json['name'] as String,
  description: json['description'] as String?,
  isArchived: json['isArchived'] as bool,
  organizationId: json['organizationId'] as String,
  prices: (json['prices'] as List<dynamic>)
      .map((e) => ProductPrice.fromJson(e as Map<String, dynamic>))
      .toList(),
  benefits: (json['benefits'] as List<dynamic>)
      .map((e) => ProductBenefit.fromJson(e as Map<String, dynamic>))
      .toList(),
  medias: (json['medias'] as List<dynamic>)
      .map((e) => ProductMedia.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt.toIso8601String(),
  'modifiedAt': instance.modifiedAt?.toIso8601String(),
  'name': instance.name,
  'description': instance.description,
  'isArchived': instance.isArchived,
  'organizationId': instance.organizationId,
  'prices': instance.prices,
  'benefits': instance.benefits,
  'medias': instance.medias,
};
