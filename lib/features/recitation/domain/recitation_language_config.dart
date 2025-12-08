import 'package:flutter_pecha/features/recitation/domain/content_type.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';

/// Configuration class for handling language-specific recitation display logic.
///
/// This class provides:
/// - Content parameters for API requests based on language
/// - Content display order based on user's language preference
class RecitationLanguageConfig {
  RecitationLanguageConfig._();

  /// Language code constants for better maintainability
  static const String tibetan = 'bo';
  static const String english = 'en';
  static const String chinese = 'zh';
  static const String sanskrit = 'sa';
  static const String tibetanAdaptation = 'tib';
  static const String tibetanTransliteration = 'tibphono';

  /// Supported languages list
  static const List<String> supportedLanguages = [tibetan, english, chinese];

  /// Returns the appropriate [RecitationContentParams] based on the user's
  /// language preference.
  ///
  /// The params determine which content types are requested from the API:
  /// - Tibetan users: Tibetan recitation + adaptation + English translation
  /// - English users: English translation + Tibetan recitation + English transliteration
  /// - Chinese users: Chinese + English translations + English transliteration
  static RecitationContentParams getContentParams(
    String language,
    String textId,
  ) {
    switch (language) {
      case tibetan:
        return RecitationContentParams(
          textId: textId,
          language: language,
          recitations: [tibetan],
          adaptations: [tibetanAdaptation],
          translations: [english],
        );

      case english:
        return RecitationContentParams(
          textId: textId,
          language: language,
          translations: [english],
          recitations: [tibetan],
          transliterations: [tibetanTransliteration],
        );

      case chinese:
        return RecitationContentParams(
          textId: textId,
          language: language,
          translations: [chinese],
          recitations: [tibetan],
          transliterations: [tibetanTransliteration],
        );

      default:
        // Default configuration for unsupported languages
        return RecitationContentParams(
          textId: textId,
          language: language,
          recitations: [tibetan],
          translations: [english],
        );
    }
  }

  /// Content order configurations for each language (cached for performance)
  static const List<ContentType> _tibetanOrder = [
    ContentType.recitation,
    ContentType.adaptation,
    ContentType.translation,
  ];

  static const List<ContentType> _englishOrder = [
    ContentType.translation,
    ContentType.recitation,
    ContentType.transliteration,
  ];

  static const List<ContentType> _chineseOrder = [
    ContentType.translation,
    ContentType.recitation,
    ContentType.transliteration,
  ];

  static const List<ContentType> _defaultOrder = [
    ContentType.recitation,
    ContentType.translation,
    ContentType.transliteration,
    ContentType.adaptation,
  ];

  /// Returns the display order of content types based on the user's language.
  ///
  /// This determines the visual hierarchy of different content types:
  /// - Tibetan users see: Recitation → Adaptation → Translation
  /// - English users see: Translation → Recitation → Transliteration
  /// - Chinese users see: Translation → Transliteration
  /// - Others see: Recitation → Translation → Transliteration → Adaptation
  static List<ContentType> getContentOrder(String languageCode) {
    return switch (languageCode) {
      tibetan => _tibetanOrder,
      english => _englishOrder,
      chinese => _chineseOrder,
      _ => _defaultOrder,
    };
  }

  /// Checks if a language code is supported.
  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.contains(languageCode);
  }
}
