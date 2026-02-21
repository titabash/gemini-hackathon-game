// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Get subscription by ID

@ProviderFor(subscription)
final subscriptionProvider = SubscriptionFamily._();

/// Get subscription by ID

final class SubscriptionProvider
    extends
        $FunctionalProvider<
          AsyncValue<Subscription>,
          Subscription,
          FutureOr<Subscription>
        >
    with $FutureModifier<Subscription>, $FutureProvider<Subscription> {
  /// Get subscription by ID
  SubscriptionProvider._({
    required SubscriptionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'subscriptionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$subscriptionHash();

  @override
  String toString() {
    return r'subscriptionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Subscription> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Subscription> create(Ref ref) {
    final argument = this.argument as String;
    return subscription(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subscriptionHash() => r'bac63fdb62e79130b2b1622ff9ac738dab7a3962';

/// Get subscription by ID

final class SubscriptionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Subscription>, String> {
  SubscriptionFamily._()
    : super(
        retry: null,
        name: r'subscriptionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get subscription by ID

  SubscriptionProvider call(String subscriptionId) =>
      SubscriptionProvider._(argument: subscriptionId, from: this);

  @override
  String toString() => r'subscriptionProvider';
}

/// Get customer subscriptions

@ProviderFor(customerSubscriptions)
final customerSubscriptionsProvider = CustomerSubscriptionsFamily._();

/// Get customer subscriptions

final class CustomerSubscriptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subscription>>,
          List<Subscription>,
          FutureOr<List<Subscription>>
        >
    with
        $FutureModifier<List<Subscription>>,
        $FutureProvider<List<Subscription>> {
  /// Get customer subscriptions
  CustomerSubscriptionsProvider._({
    required CustomerSubscriptionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerSubscriptionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerSubscriptionsHash();

  @override
  String toString() {
    return r'customerSubscriptionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Subscription>> create(Ref ref) {
    final argument = this.argument as String;
    return customerSubscriptions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerSubscriptionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerSubscriptionsHash() =>
    r'd5cd6a329530eaefb6ad69a073a94a72b1f01e95';

/// Get customer subscriptions

final class CustomerSubscriptionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Subscription>>, String> {
  CustomerSubscriptionsFamily._()
    : super(
        retry: null,
        name: r'customerSubscriptionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get customer subscriptions

  CustomerSubscriptionsProvider call(String customerId) =>
      CustomerSubscriptionsProvider._(argument: customerId, from: this);

  @override
  String toString() => r'customerSubscriptionsProvider';
}

/// Subscription cancellation notifier
///
/// Manages the state of canceling a subscription.

@ProviderFor(SubscriptionCanceller)
final subscriptionCancellerProvider = SubscriptionCancellerProvider._();

/// Subscription cancellation notifier
///
/// Manages the state of canceling a subscription.
final class SubscriptionCancellerProvider
    extends $AsyncNotifierProvider<SubscriptionCanceller, Subscription?> {
  /// Subscription cancellation notifier
  ///
  /// Manages the state of canceling a subscription.
  SubscriptionCancellerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionCancellerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionCancellerHash();

  @$internal
  @override
  SubscriptionCanceller create() => SubscriptionCanceller();
}

String _$subscriptionCancellerHash() =>
    r'24ec904a0c8c367991d514cf18892caffbd5440a';

/// Subscription cancellation notifier
///
/// Manages the state of canceling a subscription.

abstract class _$SubscriptionCanceller extends $AsyncNotifier<Subscription?> {
  FutureOr<Subscription?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Subscription?>, Subscription?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Subscription?>, Subscription?>,
              AsyncValue<Subscription?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
