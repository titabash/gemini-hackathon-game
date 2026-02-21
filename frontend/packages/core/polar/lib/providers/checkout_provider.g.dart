// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Get checkout session by ID

@ProviderFor(checkout)
final checkoutProvider = CheckoutFamily._();

/// Get checkout session by ID

final class CheckoutProvider
    extends
        $FunctionalProvider<AsyncValue<Checkout>, Checkout, FutureOr<Checkout>>
    with $FutureModifier<Checkout>, $FutureProvider<Checkout> {
  /// Get checkout session by ID
  CheckoutProvider._({
    required CheckoutFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'checkoutProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$checkoutHash();

  @override
  String toString() {
    return r'checkoutProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Checkout> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Checkout> create(Ref ref) {
    final argument = this.argument as String;
    return checkout(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CheckoutProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checkoutHash() => r'a0214a77ae4659c8a9317643e68b4a34c6fcd916';

/// Get checkout session by ID

final class CheckoutFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Checkout>, String> {
  CheckoutFamily._()
    : super(
        retry: null,
        name: r'checkoutProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get checkout session by ID

  CheckoutProvider call(String checkoutId) =>
      CheckoutProvider._(argument: checkoutId, from: this);

  @override
  String toString() => r'checkoutProvider';
}

/// Checkout session creation notifier
///
/// Manages the state of creating a new checkout session.

@ProviderFor(CheckoutCreator)
final checkoutCreatorProvider = CheckoutCreatorProvider._();

/// Checkout session creation notifier
///
/// Manages the state of creating a new checkout session.
final class CheckoutCreatorProvider
    extends $AsyncNotifierProvider<CheckoutCreator, Checkout?> {
  /// Checkout session creation notifier
  ///
  /// Manages the state of creating a new checkout session.
  CheckoutCreatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkoutCreatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkoutCreatorHash();

  @$internal
  @override
  CheckoutCreator create() => CheckoutCreator();
}

String _$checkoutCreatorHash() => r'b79633970f12a4b99290bf7b5ccdab77f136b457';

/// Checkout session creation notifier
///
/// Manages the state of creating a new checkout session.

abstract class _$CheckoutCreator extends $AsyncNotifier<Checkout?> {
  FutureOr<Checkout?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Checkout?>, Checkout?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Checkout?>, Checkout?>,
              AsyncValue<Checkout?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
