import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  final _supportedLocales = const [Locale('en'), Locale('zh'), Locale('bo')];

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文 (Chinese)';
      case 'bo':
        return 'བོད་སྐད་ (Tibetan)';
      default:
        return locale.languageCode;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              iconSize: 36,
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip:
                  themeMode == ThemeMode.dark
                      ? localizations.switchToLight
                      : localizations.switchToDark,
              onPressed: () {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
            Text(
              themeMode == ThemeMode.dark
                  ? localizations.themeDark
                  : localizations.themeLight,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            DropdownButton<Locale>(
              value: locale ?? Localizations.localeOf(context),
              dropdownColor: Theme.of(context).colorScheme.primary,
              items:
                  _supportedLocales.map((localeItem) {
                    return DropdownMenuItem<Locale>(
                      value: localeItem,
                      child: Text(
                        _getLanguageName(localeItem),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
              onChanged: (Locale? newLocale) {
                ref.read(localeProvider.notifier).setLocale(newLocale);
              },
              underline: Container(
                height: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text('Language', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
