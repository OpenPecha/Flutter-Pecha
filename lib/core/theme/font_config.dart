// Font configuration for multi-language support
// Defines system fonts (for UI) and content fonts (for backend texts)
// for each supported language.

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

/// Defines the type of font usage in the application
enum FontType {
  /// System font: Used for UI elements like tabs, navigation, settings, buttons
  system,

  /// Content font: Used for content from backend like texts, practice plans, recitations
  content,
}

/// Configuration for a language's font families
class LanguageFontConfig {
  /// Font family name for system UI elements
  final String systemFont;

  /// Font family name for content elements
  final String contentFont;

  /// Whether the font is from Google Fonts (vs local assets)
  final bool systemFontIsGoogle;
  final bool contentFontIsGoogle;

  const LanguageFontConfig({
    required this.systemFont,
    required this.contentFont,
    this.systemFontIsGoogle = true,
    this.contentFontIsGoogle = true,
  });
}

/// Central font configuration for all supported languages
class AppFontConfig {
  // Private constructor to prevent instantiation
  AppFontConfig._();

  /// Font configurations mapped by language code
  static const Map<String, LanguageFontConfig> _languageFonts = {
    // Tibetan - Google Noto Serif Tibetan for UI, Atisha (local) for content
    'bo': LanguageFontConfig(
      systemFont: 'Noto Serif Tibetan',
      contentFont: 'Atisha',
      systemFontIsGoogle: true,
      contentFontIsGoogle: false,
    ),

    'BO': LanguageFontConfig(
      systemFont: 'Noto Serif Tibetan',
      contentFont: 'Atisha',
      systemFontIsGoogle: true,
      contentFontIsGoogle: false,
    ),

    // English - Google Inter for UI, EB Garamond for content
    'en': LanguageFontConfig(
      systemFont: 'Inter',
      contentFont: 'EB Garamond',
      systemFontIsGoogle: true,
      contentFontIsGoogle: true,
    ),

    'EN': LanguageFontConfig(
      systemFont: 'Inter',
      contentFont: 'EB Garamond',
      systemFontIsGoogle: true,
      contentFontIsGoogle: true,
    ),

    // Chinese - Google Inter for UI, EB Garamond for content
    'zh': LanguageFontConfig(
      systemFont: 'Inter',
      contentFont: 'EB Garamond',
      systemFontIsGoogle: true,
      contentFontIsGoogle: true,
    ),

    'ZH': LanguageFontConfig(
      systemFont: 'Inter',
      contentFont: 'EB Garamond',
      systemFontIsGoogle: true,
      contentFontIsGoogle: true,
    ),
  };

  /// Default font configuration (used when language is not found)
  static const LanguageFontConfig _defaultConfig = LanguageFontConfig(
    systemFont: 'Inter',
    contentFont: 'EB Garamond',
    systemFontIsGoogle: true,
    contentFontIsGoogle: true,
  );

  /// Get font configuration for a specific language
  static LanguageFontConfig getConfig(String? languageCode) {
    if (languageCode == null) return _defaultConfig;
    return _languageFonts[languageCode] ?? _defaultConfig;
  }

  /// Get font family name for a specific language and font type
  /// Returns the actual font family string that can be used with TextStyle
  static String getFontFamily(String? languageCode, FontType fontType) {
    final config = getConfig(languageCode);
    final fontName =
        fontType == FontType.system ? config.systemFont : config.contentFont;
    final isGoogle =
        fontType == FontType.system
            ? config.systemFontIsGoogle
            : config.contentFontIsGoogle;

    if (!isGoogle) {
      // Return local font family name as-is
      return fontName;
    }

    // For Google Fonts, return the font family name from the GoogleFonts API
    return _getGoogleFontFamilyName(fontName);
  }

  /// Helper to get the actual font family name from Google Fonts
  static String _getGoogleFontFamilyName(String fontName) {
    switch (fontName) {
      case 'Inter':
        return GoogleFonts.inter().fontFamily ?? 'Inter';
      case 'EB Garamond':
        return GoogleFonts.ebGaramond().fontFamily ?? 'EB Garamond';
      case 'Noto Serif Tibetan':
        return GoogleFonts.notoSerifTibetan().fontFamily ??
            'Noto Serif Tibetan';
      default:
        return GoogleFonts.inter().fontFamily ?? 'Inter';
    }
  }

  /// Get TextTheme with appropriate font for a language and font type
  /// This is used for system UI elements
  static TextTheme getTextTheme(
    String? languageCode,
    FontType fontType,
    Brightness brightness,
  ) {
    final config = getConfig(languageCode);
    final fontName =
        fontType == FontType.system ? config.systemFont : config.contentFont;
    final isGoogle =
        fontType == FontType.system
            ? config.systemFontIsGoogle
            : config.contentFontIsGoogle;

    if (!isGoogle) {
      // For local fonts, return null to use fontFamily in ThemeData
      return ThemeData(brightness: brightness).textTheme;
    }

    // Use Google Fonts
    return _getGoogleFontTextTheme(fontName, brightness);
  }

  /// Helper method to get Google Font TextTheme by font name
  static TextTheme _getGoogleFontTextTheme(
    String fontName,
    Brightness brightness,
  ) {
    final baseTextTheme = ThemeData(brightness: brightness).textTheme;

    switch (fontName) {
      case 'Inter':
        return GoogleFonts.interTextTheme(baseTextTheme);
      case 'EB Garamond':
        return GoogleFonts.ebGaramondTextTheme(baseTextTheme);
      case 'Noto Serif Tibetan':
        return GoogleFonts.notoSerifTibetanTextTheme(baseTextTheme);
      default:
        return GoogleFonts.interTextTheme(baseTextTheme);
    }
  }

  /// Get text style for content with appropriate font
  static TextStyle? getContentTextStyle(
    String? languageCode,
    TextStyle? baseStyle,
  ) {
    final config = getConfig(languageCode);

    if (!config.contentFontIsGoogle) {
      // For local fonts
      return baseStyle?.copyWith(fontFamily: config.contentFont);
    }

    // Use Google Fonts
    return _getGoogleFontTextStyle(config.contentFont, baseStyle);
  }

  /// Helper method to get Google Font TextStyle by font name
  static TextStyle? _getGoogleFontTextStyle(
    String fontName,
    TextStyle? baseStyle,
  ) {
    switch (fontName) {
      case 'Inter':
        return GoogleFonts.inter(textStyle: baseStyle);
      case 'EB Garamond':
        return GoogleFonts.ebGaramond(textStyle: baseStyle);
      case 'Noto Serif Tibetan':
        return GoogleFonts.notoSerifTibetan(textStyle: baseStyle);
      default:
        return GoogleFonts.inter(textStyle: baseStyle);
    }
  }

  /// Get all supported language codes
  static List<String> get supportedLanguages => _languageFonts.keys.toList();
}
