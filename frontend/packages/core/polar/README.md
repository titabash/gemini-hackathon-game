# core_polar

Polar.sh payment and subscription integration package for Flutter applications.

## Overview

This package provides type-safe integration with Polar.sh payment and subscription services through a backend API layer. It includes:

- **Freezed Models**: Immutable data classes for Checkout, Subscription, Customer, Order, and Product
- **HTTP Client**: Dio + Retrofit client for backend API communication
- **Riverpod Providers**: State management for checkout, subscriptions, and customer portal

## Architecture

```
Flutter App → Backend API → Polar.sh SDK
```

**Why not direct Polar.sh SDK access?**
- Polar.sh access tokens are server-side only (security)
- Frontend calls backend API endpoints that wrap Polar.sh SDK calls

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  core_polar:
    path: packages/core/polar
```

## Usage

### Import

```dart
import 'package:core_polar/polar.dart';
```

### Create Checkout Session

```dart
@riverpod
class CheckoutNotifier extends _$CheckoutNotifier {
  @override
  Future<Checkout?> build() async {
    return null;
  }

  Future<void> createCheckout({
    required String productId,
    required String productPriceId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(polarApiClientProvider);
      return await client.createCheckout(
        productId: productId,
        productPriceId: productPriceId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );
    });
  }
}
```

### Access Customer Subscriptions

```dart
@riverpod
Future<List<Subscription>> customerSubscriptions(
  CustomerSubscriptionsRef ref,
  String customerId,
) async {
  final client = ref.read(polarApiClientProvider);
  return await client.getCustomerSubscriptions(customerId: customerId);
}
```

### Open Customer Portal

```dart
// Navigate to customer portal for subscription management
final portalUrl = await ref.read(polarApiClientProvider).getCustomerPortalUrl(
  customerId: customerId,
);
// Use url_launcher or webview to open portalUrl
```

## Models

All models are Freezed-based immutable data classes:

- `Checkout` - Checkout session with status and payment details
- `Subscription` - Subscription with status, billing cycle, and cancellation info
- `Customer` - Customer account information
- `Order` - One-time purchase order
- `Product` - Product with prices and benefits
- `ProductPrice` - Pricing information (one-time or recurring)

## Code Generation

After modifying models or providers, run:

```bash
cd frontend/packages/core/polar
flutter pub run build_runner build --delete-conflicting-outputs
```

Or use the project-level command:

```bash
make frontend-generate
```

## Testing

```bash
cd frontend/packages/core/polar
flutter test
```

## Backend API Integration

This package communicates with Supabase Edge Functions (`polar-api`) that wrap Polar.sh SDK calls.

### Backend API URL Configuration

**Local Development** (default):
```
http://localhost:54321/functions/v1
```

**Production** (via `--dart-define`):
```bash
flutter run --dart-define=POLAR_API_BASE_URL=https://your-project.supabase.co/functions/v1
```

Or override the provider in your app initialization:
```dart
ProviderScope(
  overrides: [
    backendBaseUrlProvider.overrideWithValue('https://your-project.supabase.co/functions/v1'),
  ],
  child: MyApp(),
)
```

### API Endpoints

All endpoints are prefixed with `/polar-api` for the Edge Function.

#### Checkout Endpoints

- `POST /polar-api/api/polar/checkouts` - Create checkout session
- `GET /polar-api/api/polar/checkouts/:id` - Get checkout session

#### Subscription Endpoints

- `GET /polar-api/api/polar/subscriptions/customer/:customerId` - List customer subscriptions
- `GET /polar-api/api/polar/subscriptions/:id` - Get subscription details
- `POST /polar-api/api/polar/subscriptions/:id/cancel` - Cancel subscription

#### Customer Endpoints

- `GET /polar-api/api/polar/customers/:id` - Get customer details
- `GET /polar-api/api/polar/customer-portal/:customerId` - Get customer portal URL

#### Order Endpoints

- `GET /polar-api/api/polar/orders/customer/:customerId` - List customer orders
- `GET /polar-api/api/polar/orders/:id` - Get order details

#### Product Endpoints

- `GET /polar-api/api/polar/products` - List all products
- `GET /polar-api/api/polar/products/:id` - Get product details

## Environment Configuration

### Edge Function Environment Variables

Configure in `env/secrets.env` or Supabase Dashboard:

```env
POLAR_ACCESS_TOKEN=your_access_token_here
POLAR_ORGANIZATION_ID=your_org_id_here
POLAR_SERVER=sandbox  # or 'production'
POLAR_WEBHOOK_SECRET=your_webhook_secret_here
```

See `supabase/functions/polar-api/README.md` for detailed setup instructions.

## License

MIT License
