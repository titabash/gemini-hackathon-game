import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:core_polar/models/subscription.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// Product price type
enum ProductPriceType {
  @JsonValue('one_time')
  oneTime,
  @JsonValue('recurring')
  recurring,
}

/// Product price
///
/// Represents pricing information for a Polar.sh product.
@freezed
class ProductPrice with _$ProductPrice {
  const factory ProductPrice({
    required String id,
    required DateTime createdAt,
    DateTime? modifiedAt,
    required ProductPriceType type,
    required int priceAmount,
    required String priceCurrency,
    RecurringInterval? recurringInterval,
  }) = _ProductPrice;

  factory ProductPrice.fromJson(Map<String, dynamic> json) =>
      _$ProductPriceFromJson(json);
}

/// Product benefit
@freezed
class ProductBenefit with _$ProductBenefit {
  const factory ProductBenefit({required String id, required String type}) =
      _ProductBenefit;

  factory ProductBenefit.fromJson(Map<String, dynamic> json) =>
      _$ProductBenefitFromJson(json);
}

/// Product media
@freezed
class ProductMedia with _$ProductMedia {
  const factory ProductMedia({required String id, required String publicUrl}) =
      _ProductMedia;

  factory ProductMedia.fromJson(Map<String, dynamic> json) =>
      _$ProductMediaFromJson(json);
}

/// Product
///
/// Represents a Polar.sh product with pricing and benefits.
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required DateTime createdAt,
    DateTime? modifiedAt,
    required String name,
    String? description,
    required bool isArchived,
    required String organizationId,
    required List<ProductPrice> prices,
    required List<ProductBenefit> benefits,
    required List<ProductMedia> medias,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
