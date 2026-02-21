// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Get customer by ID

@ProviderFor(customer)
final customerProvider = CustomerFamily._();

/// Get customer by ID

final class CustomerProvider
    extends
        $FunctionalProvider<AsyncValue<Customer>, Customer, FutureOr<Customer>>
    with $FutureModifier<Customer>, $FutureProvider<Customer> {
  /// Get customer by ID
  CustomerProvider._({
    required CustomerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerHash();

  @override
  String toString() {
    return r'customerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Customer> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Customer> create(Ref ref) {
    final argument = this.argument as String;
    return customer(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerHash() => r'023f98f50e1b48343bd585ec3a0ddb3f9d99162e';

/// Get customer by ID

final class CustomerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Customer>, String> {
  CustomerFamily._()
    : super(
        retry: null,
        name: r'customerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get customer by ID

  CustomerProvider call(String customerId) =>
      CustomerProvider._(argument: customerId, from: this);

  @override
  String toString() => r'customerProvider';
}

/// Get customer orders

@ProviderFor(customerOrders)
final customerOrdersProvider = CustomerOrdersFamily._();

/// Get customer orders

final class CustomerOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Order>>,
          List<Order>,
          FutureOr<List<Order>>
        >
    with $FutureModifier<List<Order>>, $FutureProvider<List<Order>> {
  /// Get customer orders
  CustomerOrdersProvider._({
    required CustomerOrdersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerOrdersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerOrdersHash();

  @override
  String toString() {
    return r'customerOrdersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Order>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Order>> create(Ref ref) {
    final argument = this.argument as String;
    return customerOrders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerOrdersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerOrdersHash() => r'3bebbb108f2448fea71145f2f5831272318e866e';

/// Get customer orders

final class CustomerOrdersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Order>>, String> {
  CustomerOrdersFamily._()
    : super(
        retry: null,
        name: r'customerOrdersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get customer orders

  CustomerOrdersProvider call(String customerId) =>
      CustomerOrdersProvider._(argument: customerId, from: this);

  @override
  String toString() => r'customerOrdersProvider';
}

/// Customer portal URL provider
///
/// Generates a URL for the customer to manage their subscriptions and billing.

@ProviderFor(customerPortalUrl)
final customerPortalUrlProvider = CustomerPortalUrlFamily._();

/// Customer portal URL provider
///
/// Generates a URL for the customer to manage their subscriptions and billing.

final class CustomerPortalUrlProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Customer portal URL provider
  ///
  /// Generates a URL for the customer to manage their subscriptions and billing.
  CustomerPortalUrlProvider._({
    required CustomerPortalUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerPortalUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerPortalUrlHash();

  @override
  String toString() {
    return r'customerPortalUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return customerPortalUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerPortalUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerPortalUrlHash() => r'83de0fd3ea4d8e855636d2c9aeaa99904e423cf3';

/// Customer portal URL provider
///
/// Generates a URL for the customer to manage their subscriptions and billing.

final class CustomerPortalUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  CustomerPortalUrlFamily._()
    : super(
        retry: null,
        name: r'customerPortalUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Customer portal URL provider
  ///
  /// Generates a URL for the customer to manage their subscriptions and billing.

  CustomerPortalUrlProvider call(String customerId) =>
      CustomerPortalUrlProvider._(argument: customerId, from: this);

  @override
  String toString() => r'customerPortalUrlProvider';
}
