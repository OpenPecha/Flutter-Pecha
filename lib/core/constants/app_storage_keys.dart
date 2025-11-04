/// Application storage keys
/// Contains all local storage keys used throughout the app
class AppStorageKeys {
  AppStorageKeys._();

  // ========== AUTHENTICATION ==========
  static const String userData = 'user_data';

  // ========== ONBOARDING ==========
  static const String onboardingPreferences = 'onboarding_preferences';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String onboardingStep = 'onboarding_step';
  static const String onboardingData = 'onboarding_data';

  // ========== USER PREFERENCES ==========
  static const String themeMode = 'theme_mode';
  static const String language = 'language'; // legacy string is "locale"
  static const String fontSize = 'font_size';

  // ========== NOTIFICATIONS ==========
  static const String dailyReminderTime = 'daily_reminder_time';
  static const String dailyReminderEnabled = 'dailyReminder_enabled';

  // ========== FEATURES ==========
  static const String profileData = 'profile_data';

  // ========== BUSINESS LOGIC ==========
  static const String lastProfileUpdate = 'last_profile_update';
  static const String streakCount = 'streak_count';
}
