import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core_polar/clients/polar_api_client.dart';
import 'package:core_polar/models/customer.dart';
import 'package:core_polar/models/order.dart';
import 'package:core_polar/providers/polar_client_provider.dart';

part 'customer_provider.g.dart';

/// Get customer by ID
@riverpod
Future<Customer> customer(CustomerRef ref, String customerId) async {
  final client = ref.watch(polarApiClientProvider);
  return await client.getCustomer(id: customerId);
}

/// Get customer orders
@riverpod
Future<List<Order>> customerOrders(
  CustomerOrdersRef ref,
  String customerId,
) async {
  final client = ref.watch(polarApiClientProvider);
  return await client.getCustomerOrders(customerId: customerId);
}

/// Customer portal URL provider
///
/// Generates a URL for the customer to manage their subscriptions and billing.
@riverpod
Future<String> customerPortalUrl(
  CustomerPortalUrlRef ref,
  String customerId,
) async {
  final client = ref.watch(polarApiClientProvider);
  final response = await client.getCustomerPortalUrl(customerId: customerId);
  return response.url;
}
