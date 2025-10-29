import 'package:flutter/material.dart';

/// Color palette extracted from Figma design
/// Based on Monlam Colors design system
class AppColors {
  AppColors._(); // Prevent instantiation

  // ============ Primary Colors (Action Negative - Red/Burgundy Theme) ============
  static const Color primary = Color(0xFFAD2424); // MAN 700
  static const Color primaryLight = Color(0xFFD32F2F); // MAN 500
  static const Color primaryDark = Color(0xFF871C1C); // MAN 800
  static const Color primaryDarkest = Color(0xFF611414); // MAN 900

  /// Primary color containers and tints
  static const Color primaryContainer = Color(0xFFFAE6E6); // MAN 100
  static const Color primarySurface = Color(0xFFFCF2F2); // MAN 50

  // ============ Surface Colors ============
  static const Color surfaceLight = Color(0xFFFBF9F4); // Light BG
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Dark mode surfaces
  static const Color backgroundDark = Color(0xFF1A1A1A); // Main dark background
  static const Color surfaceDark = Color(0xFF222222); // Card/surface dark
  static const Color surfaceVariantDark = Color(
    0xFF252525,
  ); // Search bar, inputs
  static const Color cardDark = Color(0xFF222222); // Card background dark
  static const Color cardBorderDark = Color(0xFF353535); // Card border dark

  // ============ Gold/Accent Colors ============
  /// Warm gold tones for cards and highlights
  static const Color goldLight = Color(0xFFFBF9F4); // MG 50
  static const Color goldAccent = Color(0xFFF6F3E9); // MG 100

  // ============ Grey Scale ============
  static const Color greyLight = Color(0xFFEDEDED); // MGS 100
  static const Color greyMedium = Color(0xFF707070); // MGS 800
  static const Color greyDark = Color(0xFF454545); // MGS 900

  // Extended grey scale for dark mode
  static const Color grey00 = Color(0xFFFFFFFF); // MGS 00
  static const Color grey50 = Color(0xFFF2F2F2); // MGS 50
  static const Color grey100 = Color(0xFFEDEDED); // MGS 100
  static const Color grey300 = Color(0xFFDADADA); // MGS 300
  static const Color grey400 = Color(0xFFC4C4C4); // MGS 400
  static const Color grey500 = Color(0xFFB3B3B3); // MGS 500
  static const Color grey600 = Color(0xFFA1A1A1); // MGS 600
  static const Color grey800 = Color(0xFF707070); // MGS 800
  static const Color grey900 = Color(0xFF454545); // MGS 900

  // ============ Text Colors ============
  // Light mode text
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF707070);

  // Dark mode text
  static const Color textPrimaryDark = Color(0xFFF2F2F2); // Primary white
  static const Color textSecondaryDark = Color(0xFFE4E4E4); // Emphasis/headings
  static const Color textTertiaryDark = Color(0xFFB3B3B3); // Less emphasis
  static const Color textMutedDark = Color(0xFFC4C4C4); // Muted
  static const Color textSubtleDark = Color(0xFFA1A1A1); // Subtle
  static const Color textLabelDark = Color(0xFFDADADA); // Labels

  // ============ Semantic Colors (for compatibility) ============
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF008000);
  static const Color warning = Color(0xFFFFA500);
  static const Color info = Color(0xFF0000FF);
  static const Color danger = Color(0xFFD32F2F);

  // ============ Background Colors ============
  static const Color scaffoldBackgroundLight = Color(0xFFFFFFFF);
  static const Color scaffoldBackgroundDark = Color(0xFF000000);
  static const Color cardBackgroundLight = Color(0xFFF5F5F5);
  static const Color cardBackgroundDark = Color(0xFF232121);

  // onboarding screen ring color
  static const Color outerCircleColor = Color(0xFFAD2424);
  static const Color middleCircleColor = Color(0xFF871C1C);
  static const Color innerCircleColor = Color(0xFF611414);

  // ============ Design System Reference ============
  // Figma file: 0TE5qdViUvrisFZfNqODpX/WeBuddhist-App
  // Design system: Monlam Colors
  // Primary theme: Red/Burgundy Buddhist aesthetic
}
