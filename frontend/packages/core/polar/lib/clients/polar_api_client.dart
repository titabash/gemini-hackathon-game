import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:core_polar/models/checkout.dart';
import 'package:core_polar/models/subscription.dart';
import 'package:core_polar/models/customer.dart';
import 'package:core_polar/models/order.dart';
import 'package:core_polar/models/product.dart';

part 'polar_api_client.g.dart';

/// Polar.sh API client
///
/// Type-safe HTTP client for Polar.sh backend API integration.
/// All requests go through the backend API which wraps Polar.sh SDK calls.
@RestApi()
abstract class PolarApiClient {
  factory PolarApiClient(Dio dio, {String? baseUrl}) = _PolarApiClient;

  // ============================================================================
  // Checkout Endpoints
  // ============================================================================

  /// Create a new checkout session
  @POST('/api/polar/checkouts')
  Future<Checkout> createCheckout({
    @Field('productId') required String productId,
    @Field('productPriceId') required String productPriceId,
    @Field('customerId') String? customerId,
    @Field('customerEmail') String? customerEmail,
    @Field('successUrl') String? successUrl,
    @Field('cancelUrl') String? cancelUrl,
    @Field('metadata') Map<String, dynamic>? metadata,
  });

  /// Get checkout session by ID
  @GET('/api/polar/checkouts/{id}')
  Future<Checkout> getCheckout({@Path('id') required String id});

  // ============================================================================
  // Subscription Endpoints
  // ============================================================================

  /// List customer subscriptions
  @GET('/api/polar/subscriptions/customer/{customerId}')
  Future<List<Subscription>> getCustomerSubscriptions({
    @Path('customerId') required String customerId,
  });

  /// Get subscription by ID
  @GET('/api/polar/subscriptions/{id}')
  Future<Subscription> getSubscription({@Path('id') required String id});

  /// Cancel subscription
  @POST('/api/polar/subscriptions/{id}/cancel')
  Future<Subscription> cancelSubscription({@Path('id') required String id});

  // ============================================================================
  // Customer Endpoints
  // ============================================================================

  /// Get customer by ID
  @GET('/api/polar/customers/{id}')
  Future<Customer> getCustomer({@Path('id') required String id});

  /// Get customer portal URL
  @GET('/api/polar/customer-portal/{customerId}')
  Future<CustomerPortalResponse> getCustomerPortalUrl({
    @Path('customerId') required String customerId,
  });

  // ============================================================================
  // Order Endpoints
  // ============================================================================

  /// List customer orders
  @GET('/api/polar/orders/customer/{customerId}')
  Future<List<Order>> getCustomerOrders({
    @Path('customerId') required String customerId,
  });

  /// Get order by ID
  @GET('/api/polar/orders/{id}')
  Future<Order> getOrder({@Path('id') required String id});

  // ============================================================================
  // Product Endpoints
  // ============================================================================

  /// List all products
  @GET('/api/polar/products')
  Future<List<Product>> listProducts();

  /// Get product by ID
  @GET('/api/polar/products/{id}')
  Future<Product> getProduct({@Path('id') required String id});
}

/// Customer portal URL response
class CustomerPortalResponse {
  final String url;

  CustomerPortalResponse({required this.url});

  factory CustomerPortalResponse.fromJson(Map<String, dynamic> json) =>
      CustomerPortalResponse(url: json['url'] as String);

  Map<String, dynamic> toJson() => {'url': url};
}
