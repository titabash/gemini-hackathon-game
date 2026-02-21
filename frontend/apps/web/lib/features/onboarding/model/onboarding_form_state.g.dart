// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_form_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// オンボーディングフォームのアカウント名状態管理

@ProviderFor(OnboardingAccountName)
final onboardingAccountNameProvider = OnboardingAccountNameProvider._();

/// オンボーディングフォームのアカウント名状態管理
final class OnboardingAccountNameProvider
    extends $NotifierProvider<OnboardingAccountName, String> {
  /// オンボーディングフォームのアカウント名状態管理
  OnboardingAccountNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingAccountNameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingAccountNameHash();

  @$internal
  @override
  OnboardingAccountName create() => OnboardingAccountName();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$onboardingAccountNameHash() =>
    r'34da4474e5e0dee91652f64666d9e64e1fa726f1';

/// オンボーディングフォームのアカウント名状態管理

abstract class _$OnboardingAccountName extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// オンボーディングフォームの表示名状態管理

@ProviderFor(OnboardingDisplayName)
final onboardingDisplayNameProvider = OnboardingDisplayNameProvider._();

/// オンボーディングフォームの表示名状態管理
final class OnboardingDisplayNameProvider
    extends $NotifierProvider<OnboardingDisplayName, String> {
  /// オンボーディングフォームの表示名状態管理
  OnboardingDisplayNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingDisplayNameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingDisplayNameHash();

  @$internal
  @override
  OnboardingDisplayName create() => OnboardingDisplayName();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$onboardingDisplayNameHash() =>
    r'b311e29fc596d238ea34b971d7c13420d59d2060';

/// オンボーディングフォームの表示名状態管理

abstract class _$OnboardingDisplayName extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// アカウント名のバリデーションエラー

@ProviderFor(onboardingAccountNameError)
final onboardingAccountNameErrorProvider =
    OnboardingAccountNameErrorProvider._();

/// アカウント名のバリデーションエラー

final class OnboardingAccountNameErrorProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// アカウント名のバリデーションエラー
  OnboardingAccountNameErrorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingAccountNameErrorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingAccountNameErrorHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return onboardingAccountNameError(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$onboardingAccountNameErrorHash() =>
    r'43acaa1f3413725d330869d4b3ef4bff9671b014';

/// フォーム全体の有効性

@ProviderFor(isOnboardingFormValid)
final isOnboardingFormValidProvider = IsOnboardingFormValidProvider._();

/// フォーム全体の有効性

final class IsOnboardingFormValidProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// フォーム全体の有効性
  IsOnboardingFormValidProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isOnboardingFormValidProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isOnboardingFormValidHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isOnboardingFormValid(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isOnboardingFormValidHash() =>
    r'cce95e5584ae63ba173d9a6ebdf9f48847ac2c90';
