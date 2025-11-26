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

  /// No description provided for @no_feature_content.
  ///
  /// In en, this message translates to:
  /// **'No featured content available'**
  String get no_feature_content;

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

  /// No description provided for @text_commentary.
  ///
  /// In en, this message translates to:
  /// **'Commentary'**
  String get text_commentary;

  /// No description provided for @text_close_commentary.
  ///
  /// In en, this message translates to:
  /// **'Close commentary'**
  String get text_close_commentary;

  /// No description provided for @commentary_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commentary_total;

  /// No description provided for @show_more.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get show_more;

  /// No description provided for @show_less.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get show_less;

  /// No description provided for @read_more.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get read_more;

  /// No description provided for @no_content.
  ///
  /// In en, this message translates to:
  /// **'No content found'**
  String get no_content;

  /// No description provided for @no_version.
  ///
  /// In en, this message translates to:
  /// **'No versions found'**
  String get no_version;

  /// No description provided for @no_commentary.
  ///
  /// In en, this message translates to:
  /// **'No commentary found'**
  String get no_commentary;

  /// No description provided for @no_commentary_message.
  ///
  /// In en, this message translates to:
  /// **'There are no commentaries available for this segment.'**
  String get no_commentary_message;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @choose_image.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get choose_image;

  /// No description provided for @choose_bg_image.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Background Image'**
  String get choose_bg_image;

  /// No description provided for @create_image.
  ///
  /// In en, this message translates to:
  /// **'Create Image'**
  String get create_image;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @customise_message.
  ///
  /// In en, this message translates to:
  /// **'Tap the customize icon to adjust text style'**
  String get customise_message;

  /// No description provided for @download_image.
  ///
  /// In en, this message translates to:
  /// **'Download Image'**
  String get download_image;

  /// No description provided for @no_images_available.
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get no_images_available;

  /// No description provided for @customise_text.
  ///
  /// In en, this message translates to:
  /// **'Customise Text'**
  String get customise_text;

  /// No description provided for @text_size.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get text_size;

  /// No description provided for @text_color.
  ///
  /// In en, this message translates to:
  /// **'Text Color'**
  String get text_color;

  /// No description provided for @text_shadow.
  ///
  /// In en, this message translates to:
  /// **'Text Shadow'**
  String get text_shadow;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @practice_nav_title.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice_nav_title;

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

  /// No description provided for @browse_plans.
  ///
  /// In en, this message translates to:
  /// **'Browse Plans'**
  String get browse_plans;

  /// No description provided for @plan_info.
  ///
  /// In en, this message translates to:
  /// **'Plan Info'**
  String get plan_info;

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

  /// No description provided for @recitation_reminder.
  ///
  /// In en, this message translates to:
  /// **'Recitations Reminder.'**
  String get recitation_reminder;

  /// No description provided for @moment_to_pray.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to pray.'**
  String get moment_to_pray;

  /// No description provided for @plan_unenroll.
  ///
  /// In en, this message translates to:
  /// **'Unenroll'**
  String get plan_unenroll;

  /// No description provided for @unenroll_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unenroll from'**
  String get unenroll_confirmation;

  /// No description provided for @unenroll_message.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be permanently lost and cannot be recovered.'**
  String get unenroll_message;

  /// No description provided for @practice_plan.
  ///
  /// In en, this message translates to:
  /// **'Practice plans help you stay consistent with your practice. We have a variety of plans to choose from and for different durations.'**
  String get practice_plan;

  /// No description provided for @search_plans.
  ///
  /// In en, this message translates to:
  /// **'Search plans...'**
  String get search_plans;

  /// No description provided for @search_for_plans.
  ///
  /// In en, this message translates to:
  /// **'Search for plans'**
  String get search_for_plans;

  /// No description provided for @no_plans_found.
  ///
  /// In en, this message translates to:
  /// **'No plans found'**
  String get no_plans_found;

  /// No description provided for @no_days_available.
  ///
  /// In en, this message translates to:
  /// **'No days found'**
  String get no_days_available;

  /// No description provided for @notification_turn_on.
  ///
  /// In en, this message translates to:
  /// **'Please turn on Notifications'**
  String get notification_turn_on;

  /// No description provided for @notification_enable_message.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to receive daily practice and recitation reminders.'**
  String get notification_enable_message;

  /// No description provided for @enable_notification.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enable_notification;

  /// No description provided for @notification_daily_practice.
  ///
  /// In en, this message translates to:
  /// **'Daily Practice'**
  String get notification_daily_practice;

  /// No description provided for @notification_select_time.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get notification_select_time;

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

  /// No description provided for @notification_daily_recitation.
  ///
  /// In en, this message translates to:
  /// **'Daily Recitation'**
  String get notification_daily_recitation;

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

  /// No description provided for @browse_recitations.
  ///
  /// In en, this message translates to:
  /// **'Browse Recitations'**
  String get browse_recitations;

  /// No description provided for @recitations_search.
  ///
  /// In en, this message translates to:
  /// **'Search recitation...'**
  String get recitations_search;

  /// No description provided for @recitations_search_for.
  ///
  /// In en, this message translates to:
  /// **'Search for recitations'**
  String get recitations_search_for;

  /// No description provided for @recitations_no_found.
  ///
  /// In en, this message translates to:
  /// **'No recitations found'**
  String get recitations_no_found;

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

  /// No description provided for @recitations_login_prompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your saved recitations'**
  String get recitations_login_prompt;

  /// No description provided for @recitations_save.
  ///
  /// In en, this message translates to:
  /// **'Save Recitation'**
  String get recitations_save;

  /// No description provided for @recitations_unsave.
  ///
  /// In en, this message translates to:
  /// **'Unsave recitation'**
  String get recitations_unsave;

  /// No description provided for @recitations_translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get recitations_translation;

  /// No description provided for @no_available.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get no_available;

  /// No description provided for @recitations_no_data_message.
  ///
  /// In en, this message translates to:
  /// **'No Recitation Found.'**
  String get recitations_no_data_message;

  /// No description provided for @recitations_show_translation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get recitations_show_translation;

  /// No description provided for @recitations_hide_translation.
  ///
  /// In en, this message translates to:
  /// **'Hide translation'**
  String get recitations_hide_translation;

  /// No description provided for @recitations_show_transliteration.
  ///
  /// In en, this message translates to:
  /// **'Show transliteration'**
  String get recitations_show_transliteration;

  /// No description provided for @recitations_hide_transliteration.
  ///
  /// In en, this message translates to:
  /// **'Hide transliteration'**
  String get recitations_hide_transliteration;

  /// No description provided for @recitations_show_recitation.
  ///
  /// In en, this message translates to:
  /// **'Show recitation'**
  String get recitations_show_recitation;

  /// No description provided for @recitations_hide_recitation.
  ///
  /// In en, this message translates to:
  /// **'Hide recitation'**
  String get recitations_hide_recitation;

  /// No description provided for @recitations_show_adaptation.
  ///
  /// In en, this message translates to:
  /// **'Show adaptation'**
  String get recitations_show_adaptation;

  /// No description provided for @recitations_hide_adaptation.
  ///
  /// In en, this message translates to:
  /// **'Hide adaptation'**
  String get recitations_hide_adaptation;

  /// No description provided for @next_recitation.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next_recitation;

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

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @logout_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logout_confirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @plans_created.
  ///
  /// In en, this message translates to:
  /// **'Plan created'**
  String get plans_created;
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
