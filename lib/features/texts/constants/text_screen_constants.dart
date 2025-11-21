import 'package:flutter/material.dart';

/// Constants for text feature screens
/// Centralizes all magic numbers, colors, and spacing values
class TextScreenConstants {
  TextScreenConstants._();

  // ============ Colors ============
  /// Border and divider colors used across text screens
  static const Color primaryBorderColor = Color(0xFFB6D7D7);
  static const Color collectionDividerColor = Color(0xFF8B3A50);
  static const Color sectionDividerColor = Color(0xFFB6D7D7);

  /// Cycling colors for collection dividers and app bar borders
  static const List<Color> collectionCyclingColors = [
    Color(0xFF802F3E), // red
    Color(0xFF5B99B7), // green/blue
    Color(0xFF5D956F), // light green
    Color(0xFF004E5F), // blue
    Color(0xFF594176), // purple
    Color(0xFF7F85A9), // light purple
    Color(0xFFD4896C), // orange
    Color(0xFFC6A7B4), // pink
    Color(0xFFCCB478), // gold
  ];

  // ============ Spacing ============
  /// Horizontal padding for screen content
  static const double screenHorizontalPadding = 16.0;
  static const double screenLargePadding = 24.0;

  /// Vertical spacing
  static const double headerVerticalPadding = 8.0;
  static const double contentVerticalSpacing = 12.0;
  static const double smallVerticalSpacing = 8.0;
  static const double largeVerticalSpacing = 16.0;
  static const double extraLargeVerticalSpacing = 22.0;

  /// List item spacing
  static const double listItemHorizontalPadding = 8.0;
  static const double listItemVerticalPadding = 8.0;

  /// Card spacing
  static const double cardHorizontalMargin = 16.0;
  static const double cardVerticalMargin = 8.0;
  static const double cardPadding = 16.0;
  static const double cardInnerPadding = 12.0;

  // ============ Font Sizes ============
  static const double headerFontSize = 22.0;
  static const double titleFontSize = 20.0;
  static const double largeTitleFontSize = 18.0;
  static const double bodyFontSize = 16.0;
  static const double subtitleFontSize = 14.0;
  static const double smallFontSize = 12.0;

  // ============ Border & Divider ============
  static const double borderThickness = 2.0;
  static const double dividerThickness = 3.0;
  static const double thinDividerThickness = 1.0;
  static const double dividerHeight = 4.0;

  // ============ Border Radius ============
  static const double cardBorderRadius = 8.0;
  static const double buttonBorderRadius = 8.0;
  static const double languageBadgeBorderRadius = 18.0;

  // ============ AppBar ============
  static const double appBarToolbarHeight = 50.0;
  static const double appBarBottomHeight = 2.0;
  static const double appBarElevation = 0.0;

  // ============ Edge Insets ============
  /// Common padding values
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontalPadding,
    vertical: headerVerticalPadding,
  );

  static const EdgeInsets screenLargePaddingValue = EdgeInsets.fromLTRB(
    screenLargePadding,
    contentVerticalSpacing,
    screenLargePadding,
    screenLargePadding,
  );

  static const EdgeInsets screenLargePaddingNoBottom = EdgeInsets.fromLTRB(
    screenLargePadding,
    contentVerticalSpacing,
    screenLargePadding,
    0,
  );

  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: listItemHorizontalPadding,
    vertical: listItemVerticalPadding,
  );

  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    horizontal: cardHorizontalMargin,
    vertical: cardVerticalMargin,
  );

  static const EdgeInsets cardPaddingValue = EdgeInsets.all(cardPadding);
  static const EdgeInsets cardInnerPaddingValue = EdgeInsets.all(
    cardInnerPadding,
  );

  static const EdgeInsets languageBadgePadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 5,
  );

  static const EdgeInsets appBarActionsPadding = EdgeInsets.only(right: 20);

  // ============ Sizes ============
  static const double languageIconSize = 18.0;
  static const double continueReadingButtonWidth = 160.0;
  static const double continueReadingButtonHeight = 40.0;

  // ============ Text Overflow ============
  static const int searchResultMaxLines = 3;

  // ============ Background Colors for Search Highlights ============
  static const Color searchHighlightColor = Color(0xFFFFFF00);

  // ============ Grey Shades ============
  static const int greyShade50 = 50;
  static const int greyShade200 = 200;
  static const int greyShade600 = 600;
  static const int greyShade700 = 700;
  static const int greyShade800 = 800;
}
