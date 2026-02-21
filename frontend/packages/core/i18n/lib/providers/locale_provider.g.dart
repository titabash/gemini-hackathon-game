// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocaleNotifier)
final localeProvider = LocaleNotifierProvider._();

final class LocaleNotifierProvider
    extends $NotifierProvider<LocaleNotifier, AppLocale> {
  LocaleNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'localeProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$localeNotifierHash();

  @$internal
  @override
  LocaleNotifier create() => LocaleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLocale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLocale>(value),
    );
  }
}

String _$localeNotifierHash() => r'd80c23668eb08f224afd00bce0f4770b28c3ce0f';

abstract class _$LocaleNotifier extends $Notifier<AppLocale> {
  AppLocale build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppLocale, AppLocale>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AppLocale, AppLocale>, AppLocale, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(currentLocale)
final currentLocaleProvider = CurrentLocaleProvider._();

final class CurrentLocaleProvider
    extends $FunctionalProvider<Locale, Locale, Locale> with $Provider<Locale> {
  CurrentLocaleProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentLocaleProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentLocaleHash();

  @$internal
  @override
  $ProviderElement<Locale> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Locale create(Ref ref) {
    return currentLocale(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$currentLocaleHash() => r'5bd343ba928a7517b8acef2bfc903340b01611d7';

@ProviderFor(currentLanguageCode)
final currentLanguageCodeProvider = CurrentLanguageCodeProvider._();

final class CurrentLanguageCodeProvider
    extends $FunctionalProvider<String, String, String> with $Provider<String> {
  CurrentLanguageCodeProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentLanguageCodeProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentLanguageCodeHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return currentLanguageCode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$currentLanguageCodeHash() =>
    r'0cbc95719bd6ce5487058efdabf123127a38342f';

@ProviderFor(isCurrentLanguage)
final isCurrentLanguageProvider = IsCurrentLanguageFamily._();

final class IsCurrentLanguageProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  IsCurrentLanguageProvider._(
      {required IsCurrentLanguageFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'isCurrentLanguageProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isCurrentLanguageHash();

  @override
  String toString() {
    return r'isCurrentLanguageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isCurrentLanguage(
      ref,
      argument,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsCurrentLanguageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isCurrentLanguageHash() => r'66982bcbdb8c64ad38b3c27e64407b49dafb4c56';

final class IsCurrentLanguageFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsCurrentLanguageFamily._()
      : super(
          retry: null,
          name: r'isCurrentLanguageProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  IsCurrentLanguageProvider call(
    String languageCode,
  ) =>
      IsCurrentLanguageProvider._(argument: languageCode, from: this);

  @override
  String toString() => r'isCurrentLanguageProvider';
}
