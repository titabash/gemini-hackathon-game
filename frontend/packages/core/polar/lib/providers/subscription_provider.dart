import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core_polar/clients/polar_api_client.dart';
import 'package:core_polar/models/subscription.dart';
import 'package:core_polar/providers/polar_client_provider.dart';

part 'subscription_provider.g.dart';

/// Get subscription by ID
@riverpod
Future<Subscription> subscription(
  SubscriptionRef ref,
  String subscriptionId,
) async {
  final client = ref.watch(polarApiClientProvider);
  return await client.getSubscription(id: subscriptionId);
}

/// Get customer subscriptions
@riverpod
Future<List<Subscription>> customerSubscriptions(
  CustomerSubscriptionsRef ref,
  String customerId,
) async {
  final client = ref.watch(polarApiClientProvider);
  return await client.getCustomerSubscriptions(customerId: customerId);
}

/// Subscription cancellation notifier
///
/// Manages the state of canceling a subscription.
@riverpod
class SubscriptionCanceller extends _$SubscriptionCanceller {
  @override
  FutureOr<Subscription?> build() {
    return null;
  }

  /// Cancel a subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(polarApiClientProvider);
      final canceledSubscription = await client.cancelSubscription(
        id: subscriptionId,
      );

      // Invalidate cached subscription data
      ref.invalidate(subscriptionProvider(subscriptionId));
      // Note: customerId is needed to invalidate customerSubscriptions
      // You might want to keep track of customerId in state or pass it as parameter

      return canceledSubscription;
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncData(null);
  }
}
