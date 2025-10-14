import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bo.dart';
import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bo'),
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'WeBuddhist'**
  String get appTitle;

  /// No description provided for @pechaHeading.
  ///
  /// In en, this message translates to:
  /// **'WeBuddhist'**
  String get pechaHeading;

  /// No description provided for @learnLiveShare.
  ///
  /// In en, this message translates to:
  /// **'Learn Live and Share'**
  String get learnLiveShare;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDark;

  /// No description provided for @switchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to Light Mode'**
  String get switchToLight;

  /// No description provided for @switchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to Dark Mode'**
  String get switchToDark;

  /// No description provided for @home_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get home_today;

  /// No description provided for @home_dailyRefresh.
  ///
  /// In en, this message translates to:
  /// **'Daily Refresh'**
  String get home_dailyRefresh;

  /// No description provided for @home_meditationTitle.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get home_meditationTitle;

  /// No description provided for @home_meditationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Awaken peace within.'**
  String get home_meditationSubtitle;

  /// No description provided for @home_prayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer of the Day'**
  String get home_prayerTitle;

  /// No description provided for @home_prayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Begin your day with a sacred intention.'**
  String get home_prayerSubtitle;

  /// No description provided for @home_btnText.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get home_btnText;

  /// No description provided for @home_goDeeper.
  ///
  /// In en, this message translates to:
  /// **'Go Deeper'**
  String get home_goDeeper;

  /// No description provided for @home_intention.
  ///
  /// In en, this message translates to:
  /// **'My Intention for Today'**
  String get home_intention;

  /// No description provided for @home_recitation.
  ///
  /// In en, this message translates to:
  /// **'Recitation'**
  String get home_recitation;

  /// No description provided for @home_bringing.
  ///
  /// In en, this message translates to:
  /// **'Bringing it to life'**
  String get home_bringing;

  /// No description provided for @home_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get home_profile;

  /// No description provided for @text_browseTheLibrary.
  ///
  /// In en, this message translates to:
  /// **'Browse The Library'**
  String get text_browseTheLibrary;

  /// No description provided for @text_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get text_search;

  /// No description provided for @text_detail_rootText.
  ///
  /// In en, this message translates to:
  /// **'Root Text'**
  String get text_detail_rootText;

  /// No description provided for @text_detail_commentaryText.
  ///
  /// In en, this message translates to:
  /// **'Commentary Text'**
  String get text_detail_commentaryText;

  /// No description provided for @text_toc_continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get text_toc_continueReading;

  /// No description provided for @text_toc_content.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get text_toc_content;

  /// No description provided for @text_toc_versions.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get text_toc_versions;

  /// No description provided for @text_toc_revisionHistory.
  ///
  /// In en, this message translates to:
  /// **'Revision History'**
  String get text_toc_revisionHistory;

  /// No description provided for @tibetan.
  ///
  /// In en, this message translates to:
  /// **'Tibetan'**
  String get tibetan;

  /// No description provided for @sanskrit.
  ///
  /// In en, this message translates to:
  /// **'Sanskrit'**
  String get sanskrit;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @dailyPracticeNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Practice Reminder'**
  String get dailyPracticeNotificationTitle;

  /// No description provided for @timeForDailyPractice.
  ///
  /// In en, this message translates to:
  /// **'It\'s time for your daily practice.'**
  String get timeForDailyPractice;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @dailyPractice.
  ///
  /// In en, this message translates to:
  /// **'Daily Practice'**
  String get dailyPractice;

  /// No description provided for @dailyPracticeRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Get reminded daily to practice your meditation and prayers'**
  String get dailyPracticeRemindersDescription;

  /// No description provided for @enableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable Reminders'**
  String get enableReminders;

  /// No description provided for @remindersEnabled.
  ///
  /// In en, this message translates to:
  /// **'Reminders are active'**
  String get remindersEnabled;

  /// No description provided for @remindersDisabled.
  ///
  /// In en, this message translates to:
  /// **'Reminders are inactive'**
  String get remindersDisabled;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @updateTime.
  ///
  /// In en, this message translates to:
  /// **'Update Time'**
  String get updateTime;

  /// No description provided for @testNotifications.
  ///
  /// In en, this message translates to:
  /// **'Test Notifications'**
  String get testNotifications;

  /// No description provided for @testNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Send a test notification to verify everything is working'**
  String get testNotificationsDescription;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @manageDailyReminders.
  ///
  /// In en, this message translates to:
  /// **'Manage daily reminders'**
  String get manageDailyReminders;

  /// No description provided for @text_noContent.
  ///
  /// In en, this message translates to:
  /// **'No texts available in the selected language'**
  String get text_noContent;

  /// No description provided for @text_switchToTibetan.
  ///
  /// In en, this message translates to:
  /// **'Switch to Tibetan'**
  String get text_switchToTibetan;

  /// No description provided for @common_sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get common_sign_in;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['bo', 'en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bo': return AppLocalizationsBo();
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
