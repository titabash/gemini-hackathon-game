import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

/// Subscription status
enum SubscriptionStatus {
  @JsonValue('incomplete')
  incomplete,
  @JsonValue('incomplete_expired')
  incompleteExpired,
  @JsonValue('trialing')
  trialing,
  @JsonValue('active')
  active,
  @JsonValue('past_due')
  pastDue,
  @JsonValue('canceled')
  canceled,
  @JsonValue('unpaid')
  unpaid,
}

/// Recurring interval
enum RecurringInterval {
  @JsonValue('day')
  day,
  @JsonValue('week')
  week,
  @JsonValue('month')
  month,
  @JsonValue('year')
  year,
}

/// Subscription
///
/// Represents a recurring subscription to a Polar.sh product.
@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required DateTime createdAt,
    DateTime? modifiedAt,
    required SubscriptionStatus status,
    required int amount,
    required String currency,
    required RecurringInterval recurringInterval,
    required DateTime currentPeriodStart,
    DateTime? currentPeriodEnd,
    required bool cancelAtPeriodEnd,
    DateTime? canceledAt,
    DateTime? startedAt,
    DateTime? endsAt,
    DateTime? endedAt,
    required String productId,
    required String priceId,
    required String customerId,
    Map<String, dynamic>? metadata,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}
