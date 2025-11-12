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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bo'),
    Locale('en'),
    Locale('zh'),
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

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign_in;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @onboarding_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to WeBuddhist'**
  String get onboarding_welcome;

  /// No description provided for @onboarding_description.
  ///
  /// In en, this message translates to:
  /// **'Where we learn, live, and share Buddhist wisdom every day'**
  String get onboarding_description;

  /// No description provided for @onboarding_quote.
  ///
  /// In en, this message translates to:
  /// **'Approximatey 500 million people worldwide practice Buddhism, making it the world\'s fourth largest religion'**
  String get onboarding_quote;

  /// No description provided for @onboarding_first_question.
  ///
  /// In en, this message translates to:
  /// **'In which language would you like to access core texts?'**
  String get onboarding_first_question;

  /// No description provided for @onboarding_second_question.
  ///
  /// In en, this message translates to:
  /// **'Which path or school do you feel drawn to?'**
  String get onboarding_second_question;

  /// No description provided for @onboarding_choose_option.
  ///
  /// In en, this message translates to:
  /// **'Choose upto 3 options'**
  String get onboarding_choose_option;

  /// No description provided for @onboarding_all_set.
  ///
  /// In en, this message translates to:
  /// **'You are All Setup'**
  String get onboarding_all_set;

  /// No description provided for @home_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get home_today;

  /// No description provided for @home_good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get home_good_morning;

  /// No description provided for @home_good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get home_good_afternoon;

  /// No description provided for @home_good_evening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get home_good_evening;

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

  /// No description provided for @home_scripture.
  ///
  /// In en, this message translates to:
  /// **'Guided Scripture'**
  String get home_scripture;

  /// No description provided for @home_meditation.
  ///
  /// In en, this message translates to:
  /// **'Guided Meditation'**
  String get home_meditation;

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

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_texts.
  ///
  /// In en, this message translates to:
  /// **'Texts'**
  String get nav_texts;

  /// No description provided for @nav_recitations.
  ///
  /// In en, this message translates to:
  /// **'Recitations'**
  String get nav_recitations;

  /// No description provided for @nav_practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get nav_practice;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

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

  /// No description provided for @my_plans.
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get my_plans;

  /// No description provided for @find_plans.
  ///
  /// In en, this message translates to:
  /// **'Find Plans'**
  String get find_plans;

  /// No description provided for @start_plan.
  ///
  /// In en, this message translates to:
  /// **'Start Plan'**
  String get start_plan;

  /// No description provided for @continue_plan.
  ///
  /// In en, this message translates to:
  /// **'Continue Plan'**
  String get continue_plan;

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

  /// No description provided for @recitations_title.
  ///
  /// In en, this message translates to:
  /// **'Recitations'**
  String get recitations_title;

  /// No description provided for @recitations_my_recitations.
  ///
  /// In en, this message translates to:
  /// **'My Recitations'**
  String get recitations_my_recitations;

  /// No description provided for @recitations_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get recitations_search;

  /// No description provided for @recitations_saved.
  ///
  /// In en, this message translates to:
  /// **'Recitation saved'**
  String get recitations_saved;

  /// No description provided for @recitations_unsaved.
  ///
  /// In en, this message translates to:
  /// **'Recitation removed'**
  String get recitations_unsaved;

  /// No description provided for @recitations_no_content.
  ///
  /// In en, this message translates to:
  /// **'No recitations available'**
  String get recitations_no_content;

  /// No description provided for @recitations_no_saved.
  ///
  /// In en, this message translates to:
  /// **'No saved recitations'**
  String get recitations_no_saved;

  /// No description provided for @recitations_save_prompt.
  ///
  /// In en, this message translates to:
  /// **'Save recitations to access them here'**
  String get recitations_save_prompt;

  /// No description provided for @recitations_login_required.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get recitations_login_required;

  /// No description provided for @recitations_login_prompt.
  ///
  /// In en, this message translates to:
  /// **'Please login to view your saved recitations'**
  String get recitations_login_prompt;

  /// No description provided for @recitations_save.
  ///
  /// In en, this message translates to:
  /// **'Save Recitation'**
  String get recitations_save;

  /// No description provided for @recitations_unsave.
  ///
  /// In en, this message translates to:
  /// **'Remove from Saved'**
  String get recitations_unsave;

  /// No description provided for @recitations_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get recitations_share;

  /// No description provided for @recitations_phonetic.
  ///
  /// In en, this message translates to:
  /// **'Phonetic'**
  String get recitations_phonetic;

  /// No description provided for @recitations_translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get recitations_translation;

  /// No description provided for @settings_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @notification_settings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notification_settings;

  /// No description provided for @settings_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_account;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bo', 'en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bo':
      return AppLocalizationsBo();
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
