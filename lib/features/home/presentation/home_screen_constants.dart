/// Constants used in the HomeScreen
class HomeScreenConstants {
  // UI Dimensions
  static const double topBarHorizontalPadding = 16.0;
  static const double topBarVerticalPadding = 8.0;
  static const double titleFontSize = 22.0;
  static const double notificationIconSize = 28.0;
  static const double iconSpacing = 16.0;
  static const double avatarRadius = 16.0;
  static const double profileIconSize = 32.0;
  static const double bodyHorizontalPadding = 16.0;
  static const double bodyVerticalPadding = 8.0;
  static const double cardSpacing = 16.0;
  static const double emptyStatePadding = 32.0;
  static const double errorIconSize = 48.0;
  static const double errorSpacing = 16.0;
  static const double errorTextSpacing = 8.0;

  // Text Content
  static const String defaultDuration = '1-2 min';
  static const String emptyStateMessage = 'No featured content available';
  static const String errorMessage = 'Failed to load featured day content';
  static const String retryButtonText = 'Retry';

  // Timer Configuration
  static const Duration dayCheckInterval = Duration(minutes: 15);

  // Card Indices
  static const int verseCardIndex = 0;
  static const int scriptureCardIndex = 1;
  static const int meditationCardIndex = 2;

  // Private constructor to prevent instantiation
  HomeScreenConstants._();
}
