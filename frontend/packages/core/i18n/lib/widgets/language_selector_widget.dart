import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../generated/strings.g.dart';
import '../locale/supported_locales.dart';
import '../providers/locale_provider.dart';

class LanguageSelectorWidget extends ConsumerWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeNotifier = ref.read(localeProvider.notifier);
    final currentLocale = ref.watch(localeProvider);

    return PopupMenuButton<AppLocale>(
      icon: const Icon(Icons.language),
      tooltip: t.settings.changeLanguage,
      onSelected: (AppLocale locale) {
        localeNotifier.changeLocale(locale);
      },
      itemBuilder: (BuildContext context) {
        return SupportedLocales.locales.map((localeInfo) {
          final isSelected = currentLocale == localeInfo.locale;
          return PopupMenuItem<AppLocale>(
            value: localeInfo.locale,
            child: Row(
              children: [
                Text(localeInfo.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localeInfo.nativeName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        localeInfo.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

class SimpleLanguageToggleButton extends ConsumerWidget {
  const SimpleLanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeNotifier = ref.read(localeProvider.notifier);
    final currentLocale = ref.watch(localeProvider);

    return IconButton(
      onPressed: localeNotifier.toggleLocale,
      icon: Text(currentLocale.flag, style: const TextStyle(fontSize: 20)),
      tooltip: '${t.settings.changeLanguage} (${currentLocale.nativeName})',
    );
  }
}
