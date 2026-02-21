import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core_polar/clients/polar_api_client.dart';
import 'package:core_polar/models/product.dart';
import 'package:core_polar/providers/polar_client_provider.dart';

part 'product_provider.g.dart';

/// Get product by ID
@riverpod
Future<Product> product(ProductRef ref, String productId) async {
  final client = ref.watch(polarApiClientProvider);
  return await client.getProduct(id: productId);
}

/// List all products
@riverpod
Future<List<Product>> products(ProductsRef ref) async {
  final client = ref.watch(polarApiClientProvider);
  return await client.listProducts();
}
