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
}
