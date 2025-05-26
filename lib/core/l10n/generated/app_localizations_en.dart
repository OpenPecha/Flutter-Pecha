// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pecha App';

  @override
  String get pechaHeading => 'Pecha';

  @override
  String get learnLiveShare => 'Learn Live and Share';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get switchToLight => 'Switch to Light Mode';

  @override
  String get switchToDark => 'Switch to Dark Mode';

  @override
  String get home_today => 'Today';

  @override
  String get home_dailyRefresh => 'Daily Refresh';

  @override
  String get home_meditationTitle => 'Meditation of the Day';

  @override
  String get home_meditationSubtitle => 'Awaken peace within.';

  @override
  String get home_prayerTitle => 'Prayer of the Day';

  @override
  String get home_prayerSubtitle => 'Begin your day with a sacred intention.';

  @override
  String get home_btnText => 'Start now';
}
