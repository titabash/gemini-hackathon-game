// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 現在のユーザープロフィールを取得するProvider

@ProviderFor(currentUserProfile)
final currentUserProfileProvider = CurrentUserProfileProvider._();

/// 現在のユーザープロフィールを取得するProvider

final class CurrentUserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          FutureOr<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $FutureProvider<UserProfile?> {
  /// 現在のユーザープロフィールを取得するProvider
  CurrentUserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserProfileHash();

  @$internal
  @override
  $FutureProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfile?> create(Ref ref) {
    return currentUserProfile(ref);
  }
}

String _$currentUserProfileHash() =>
    r'966277d52369e1af9774c128fbf27f115f729681';

/// オンボーディングが必要かどうかを判定するProvider

@ProviderFor(needsOnboarding)
final needsOnboardingProvider = NeedsOnboardingProvider._();

/// オンボーディングが必要かどうかを判定するProvider

final class NeedsOnboardingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// オンボーディングが必要かどうかを判定するProvider
  NeedsOnboardingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'needsOnboardingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$needsOnboardingHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return needsOnboarding(ref);
  }
}

String _$needsOnboardingHash() => r'dcd3b452b7b914abe1916861b0f9a62dbb527942';
