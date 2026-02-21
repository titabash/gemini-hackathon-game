// core_polar - Polar.sh 統合パッケージ
//
// 決済・サブスクリプション管理のための共通パッケージ
//
// Example:
// ```dart
// // Models
// import 'package:core_polar/polar.dart';
//
// // Providers
// final checkout = ref.watch(checkoutProvider(checkoutId));
// final subscriptions = ref.watch(customerSubscriptionsProvider(customerId));
// final portalUrl = ref.watch(customerPortalUrlProvider(customerId));
//
// // Create checkout
// await ref.read(checkoutCreatorProvider.notifier).createCheckout(
//   productId: 'prod_123',
//   productPriceId: 'price_456',
// );
// ```

// ============================================================================
// Models
// ============================================================================
export 'models/checkout.dart';
export 'models/customer.dart';
export 'models/order.dart';
export 'models/product.dart';
export 'models/subscription.dart';

// ============================================================================
// Clients
// ============================================================================
export 'clients/polar_api_client.dart';

// ============================================================================
// Providers
// ============================================================================
export 'providers/polar_client_provider.dart';
export 'providers/checkout_provider.dart';
export 'providers/customer_provider.dart';
export 'providers/product_provider.dart';
export 'providers/subscription_provider.dart';
