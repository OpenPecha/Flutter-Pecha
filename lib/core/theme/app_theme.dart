// This file provides a shared theme utility for the application,
// defining the light and dark themes and other styling elements.
// Defines the application's light and dark themes and theme utilities.
// Shared across all features for consistent styling.

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme([Locale? locale]) {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      fontFamily: _fontFamilyForLocale(locale),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
      ).copyWith(secondary: Colors.blueAccent, brightness: Brightness.light),
    );
  }

  static ThemeData darkTheme([Locale? locale]) {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      fontFamily: _fontFamilyForLocale(locale),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF222222),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
      ).copyWith(secondary: Colors.blueAccent, brightness: Brightness.dark),
    );
  }

  static String? _fontFamilyForLocale(Locale? locale) {
    if (locale?.languageCode == 'bo') {
      return 'MonlamTibetan';
    }
    return null; // Default font
  }
}
