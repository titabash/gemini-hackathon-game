import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/strings.g.dart';
import '../locale/supported_locales.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  static const String _localeKey = 'app_locale';

  @override
  AppLocale build() {
    _loadSavedLocale();
    return SupportedLocales.defaultLocale;
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);

      if (savedLocale != null) {
        final appLocale = SupportedLocales.fromLanguageCode(savedLocale);

        if (appLocale != state) {
          state = appLocale;
          LocaleSettings.setLocale(appLocale);
        }
      }
    } catch (e) {
      // If loading fails, keep the default locale
      // print('Failed to load saved locale: $e');
    }
  }

  Future<void> changeLocale(AppLocale locale) async {
    if (state == locale) return;

    state = locale;
    LocaleSettings.setLocale(locale);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      // print('Failed to save locale preference: $e');
    }
  }

  void toggleLocale() {
    // Cycle through all available locales
    final currentIndex = AppLocale.values.indexOf(state);
    final nextIndex = (currentIndex + 1) % AppLocale.values.length;
    changeLocale(AppLocale.values[nextIndex]);
  }

  void setLocaleByLanguageCode(String languageCode) {
    final locale = SupportedLocales.fromLanguageCode(languageCode);
    changeLocale(locale);
  }

  List<AppLocale> get availableLocales =>
      SupportedLocales.locales.map((info) => info.locale).toList();
}

// Provider for current Flutter Locale
@riverpod
Locale currentLocale(Ref ref) {
  final appLocale = ref.watch(localeProvider);
  return appLocale.flutterLocale;
}

// Provider for checking current locale language code
@riverpod
String currentLanguageCode(Ref ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode;
}

// Provider for checking if current locale matches a specific language
@riverpod
bool isCurrentLanguage(Ref ref, String languageCode) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode == languageCode;
}
