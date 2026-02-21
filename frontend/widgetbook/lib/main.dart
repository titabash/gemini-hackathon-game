import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:shared_ui/shared_ui.dart';
import 'package:core_i18n/core_i18n.dart';

// Import Use Cases (organized by source package structure)
// ignore: unused_import
import 'use_cases/shared_ui/components/app_button_use_case.dart';

import 'main.directories.g.dart';

void main() {
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: directories,
      addons: [
        // Viewport Addon (should be first)
        ViewportAddon([
          Viewports.none,
          IosViewports.iPhoneSE,
          IosViewports.iPhone13,
          IosViewports.iPhone13ProMax,
          AndroidViewports.samsungGalaxyA50,
          AndroidViewports.samsungGalaxyNote20,
          AndroidViewports.samsungGalaxyS20,
        ]),
        // Theme Addon
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: AppTheme.lightTheme),
            WidgetbookTheme(name: 'Dark', data: AppTheme.darkTheme),
          ],
        ),
        // Localization Addon
        LocalizationAddon(
          locales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialLocale: AppLocale.en.flutterLocale,
        ),
        // Text Scale Addon
        TextScaleAddon(min: 0.85, max: 2.0, initialScale: 1.0),
        // Grid Addon for alignment
        GridAddon(100),
      ],
    );
  }
}
