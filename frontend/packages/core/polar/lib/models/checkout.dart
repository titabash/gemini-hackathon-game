import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkout.freezed.dart';
part 'checkout.g.dart';

/// Checkout session status
enum CheckoutStatus {
  @JsonValue('open')
  open,
  @JsonValue('expired')
  expired,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('succeeded')
  succeeded,
  @JsonValue('failed')
  failed,
}

/// Checkout session
///
/// Represents a Polar.sh checkout session for completing a purchase.
@freezed
class Checkout with _$Checkout {
  const factory Checkout({
    required String id,
    required DateTime createdAt,
    DateTime? modifiedAt,
    required CheckoutStatus status,
    required String clientSecret,
    required String url,
    required DateTime expiresAt,
    required String successUrl,
    int? amount,
    String? currency,
    required String productId,
    required String productPriceId,
    String? customerId,
    String? customerEmail,
    String? customerName,
    Map<String, dynamic>? metadata,
  }) = _Checkout;

  factory Checkout.fromJson(Map<String, dynamic> json) =>
      _$CheckoutFromJson(json);
}
