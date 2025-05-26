// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Pecha 应用';

  @override
  String get pechaHeading => 'Pecha';

  @override
  String get learnLiveShare => '学习、生活与分享';

  @override
  String get themeLight => '浅色模式';

  @override
  String get themeDark => '深色模式';

  @override
  String get switchToLight => '切换到浅色模式';

  @override
  String get switchToDark => '切换到深色模式';

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
