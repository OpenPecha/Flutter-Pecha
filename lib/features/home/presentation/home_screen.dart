// This file contains the presentation layer for the home screen feature.
// It handles the UI for the main home screen after splash.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _supportedLocales = const [Locale('en'), Locale('zh'), Locale('bo')];
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  void _changeLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
  }

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
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(localizations.appTitle),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                localizations.pechaHeading,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              Text(
                localizations.learnLiveShare,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              IconButton(
                iconSize: 36,
                icon: Icon(
                  _themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip:
                    _themeMode == ThemeMode.dark
                        ? localizations.switchToLight
                        : localizations.switchToDark,
                onPressed: () {
                  _toggleTheme();
                },
              ),
              Text(
                _themeMode == ThemeMode.dark
                    ? localizations.themeDark
                    : localizations.themeLight,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              DropdownButton<Locale>(
                value: _locale ?? Localizations.localeOf(context),
                items:
                    _supportedLocales.map((locale) {
                      return DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(_getLanguageName(locale)),
                      );
                    }).toList(),
                onChanged: (Locale? newLocale) {
                  _changeLocale(newLocale);
                },
                underline: Container(
                  height: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text('Language', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
