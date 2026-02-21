import '../generated/strings.g.dart';

/// Configuration for supported locales in the application
class SupportedLocales {
  static const List<LocaleInfo> locales = [
    LocaleInfo(
      locale: AppLocale.en,
      displayName: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    LocaleInfo(
      locale: AppLocale.ja,
      displayName: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
    ),
  ];

  /// Get locale info by AppLocale
  static LocaleInfo? getLocaleInfo(AppLocale locale) {
    try {
      return locales.firstWhere((info) => info.locale == locale);
    } catch (e) {
      return null;
    }
  }

  /// Get all supported language codes
  static List<String> get languageCodes =>
      locales.map((info) => info.locale.languageCode).toList();

  /// Get default locale (fallback)
  static AppLocale get defaultLocale => AppLocale.en;

  /// Check if a locale is supported
  static bool isSupported(String languageCode) {
    return languageCodes.contains(languageCode);
  }

  /// Get AppLocale from language code with fallback
  static AppLocale fromLanguageCode(String languageCode) {
    final info = locales
        .where((info) => info.locale.languageCode == languageCode)
        .firstOrNull;

    return info?.locale ?? defaultLocale;
  }
}

/// Information about a supported locale
class LocaleInfo {
  const LocaleInfo({
    required this.locale,
    required this.displayName,
    required this.nativeName,
    required this.flag,
  });

  final AppLocale locale;
  final String displayName; // English name
  final String nativeName; // Native language name
  final String flag; // Emoji flag
}

/// Extension to add utility methods to AppLocale
extension AppLocaleExtension on AppLocale {
  /// Get locale information
  LocaleInfo? get info => SupportedLocales.getLocaleInfo(this);

  /// Get display name in English
  String get displayName => info?.displayName ?? languageCode.toUpperCase();

  /// Get native name
  String get nativeName => info?.nativeName ?? languageCode.toUpperCase();

  /// Get flag emoji
  String get flag => info?.flag ?? '🌐';
}
