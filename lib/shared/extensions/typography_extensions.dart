import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/constants/plan_constants.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Extension methods for creating language-aware text styles
/// Automatically applies correct font family, line height, and font size based on language
extension TypographyExtensions on BuildContext {
  /// Get a text style configured for the specified language
  ///
  /// [language] - Language code (e.g., 'bo' for Tibetan, 'en' for English)
  /// [fontSize] - Base font size (will be adjusted for Tibetan)
  /// [fontWeight] - Font weight
  /// [color] - Text color
  ///
  /// Example:
  /// ```dart
  /// Text(
  ///   'བོད་ཡིག',
  ///   style: context.languageTextStyle('bo', fontSize: 18, fontWeight: FontWeight.bold),
  /// )
  /// ```
  TextStyle languageTextStyle(
    String language, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    final fontFamily = getFontFamily(language);
    final lineHeight = height ?? getLineHeight(language);
    final effectiveFontSize = fontSize ?? PlanConstants.getFontSizeForLanguage(language);

    return TextStyle(
      fontFamily: fontFamily,
      height: lineHeight,
      fontSize: effectiveFontSize,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
    );
  }

  /// Get title text style for the specified language
  ///
  /// Uses larger font size suitable for titles and headings
  TextStyle languageTitleStyle(
    String language, {
    FontWeight? fontWeight = FontWeight.bold,
    Color? color,
  }) {
    return languageTextStyle(
      language,
      fontSize: PlanConstants.titleFontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Get body text style for the specified language
  ///
  /// Uses standard font size suitable for body text
  TextStyle languageBodyStyle(
    String language, {
    FontWeight? fontWeight,
    Color? color,
  }) {
    return languageTextStyle(
      language,
      fontSize: PlanConstants.bodyFontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Get caption/secondary text style for the specified language
  ///
  /// Uses smaller font size suitable for captions and secondary information
  TextStyle languageCaptionStyle(
    String language, {
    FontWeight? fontWeight,
    Color? color,
  }) {
    return languageTextStyle(
      language,
      fontSize: PlanConstants.dayNumberFontSize,
      fontWeight: fontWeight,
      color: color ?? Colors.grey[600],
    );
  }
}

/// Helper class for creating TextStyle objects with language support
/// Use this when you can't use the extension method (e.g., in non-widget contexts)
class LanguageTypography {
  LanguageTypography._();

  /// Create a text style for the specified language
  static TextStyle forLanguage(
    String language, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    final fontFamily = getFontFamily(language);
    final lineHeight = height ?? getLineHeight(language);
    final effectiveFontSize = fontSize ?? PlanConstants.getFontSizeForLanguage(language);

    return TextStyle(
      fontFamily: fontFamily,
      height: lineHeight,
      fontSize: effectiveFontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Create a title text style for the specified language
  static TextStyle titleForLanguage(
    String language, {
    FontWeight fontWeight = FontWeight.bold,
    Color? color,
  }) {
    return forLanguage(
      language,
      fontSize: PlanConstants.titleFontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Create a body text style for the specified language
  static TextStyle bodyForLanguage(
    String language, {
    FontWeight? fontWeight,
    Color? color,
  }) {
    return forLanguage(
      language,
      fontSize: PlanConstants.bodyFontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
