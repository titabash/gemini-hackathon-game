import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// Order status
enum OrderStatus {
  @JsonValue('paid')
  paid,
  @JsonValue('refunded')
  refunded,
  @JsonValue('partially_refunded')
  partiallyRefunded,
}

/// Order
///
/// Represents a one-time purchase order in Polar.sh.
@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required DateTime createdAt,
    DateTime? modifiedAt,
    required OrderStatus status,
    required int amount,
    required String currency,
    required String productId,
    required String productPriceId,
    required String customerId,
    String? checkoutId,
    Map<String, dynamic>? metadata,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
