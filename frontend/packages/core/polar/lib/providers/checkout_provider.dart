import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core_polar/clients/polar_api_client.dart';
import 'package:core_polar/models/checkout.dart';
import 'package:core_polar/providers/polar_client_provider.dart';

part 'checkout_provider.g.dart';

/// Get checkout session by ID
@riverpod
Future<Checkout> checkout(CheckoutRef ref, String checkoutId) async {
  final client = ref.watch(polarApiClientProvider);
  return await client.getCheckout(id: checkoutId);
}

/// Checkout session creation notifier
///
/// Manages the state of creating a new checkout session.
@riverpod
class CheckoutCreator extends _$CheckoutCreator {
  @override
  FutureOr<Checkout?> build() {
    return null;
  }

  /// Create a new checkout session
  Future<void> createCheckout({
    required String productId,
    required String productPriceId,
    String? customerId,
    String? customerEmail,
    String? successUrl,
    String? cancelUrl,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(polarApiClientProvider);
      return await client.createCheckout(
        productId: productId,
        productPriceId: productPriceId,
        customerId: customerId,
        customerEmail: customerEmail,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
        metadata: metadata,
      );
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncData(null);
  }
}
