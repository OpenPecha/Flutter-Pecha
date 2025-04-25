import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'localization/material_localizations_bo.dart';
import 'localization/cupertino_localizations_bo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pecha App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      localizationsDelegates: [
        MaterialLocalizationsBo.delegate,
        CupertinoLocalizationsBo.delegate,
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('bo'), // Tibetan
      ],
      locale: _locale,
      home: MyHomePage(
        title: 'Pecha App',
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
        locale: _locale,
        onLocaleChanged: _changeLocale,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.themeMode,
    required this.onToggleTheme,
    required this.locale,
    required this.onLocaleChanged,
  });

  final String title;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final Locale? locale;
  final ValueChanged<Locale?> onLocaleChanged;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _supportedLocales = const [Locale('en'), Locale('es'), Locale('bo')];

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
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
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              IconButton(
                iconSize: 36,
                icon: Icon(
                  widget.themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip:
                    widget.themeMode == ThemeMode.dark
                        ? localizations.switchToLight
                        : localizations.switchToDark,
                onPressed: widget.onToggleTheme,
              ),
              Text(
                widget.themeMode == ThemeMode.dark
                    ? localizations.themeDark
                    : localizations.themeLight,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              DropdownButton<Locale>(
                value: widget.locale ?? Localizations.localeOf(context),
                items:
                    _supportedLocales.map((locale) {
                      return DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(_getLanguageName(locale)),
                      );
                    }).toList(),
                onChanged: widget.onLocaleChanged,
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
