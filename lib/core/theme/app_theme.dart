// This file provides a shared theme utility for the application,
// defining the light and dark themes and other styling elements.
// Defines the application's light and dark themes and theme utilities.
// Shared across all features for consistent styling.

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme([Locale? locale]) {
    final baseTheme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      fontFamily: _fontFamilyForLocale(locale),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      cardColor: Colors.grey.shade100,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
      ).copyWith(secondary: Colors.blueAccent, brightness: Brightness.light),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(color: Colors.black),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.black26,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
    // If locale is Tibetan, set line height to 2.0 for all text styles
    if (locale?.languageCode == 'bo') {
      final baseTextTheme = baseTheme.textTheme;
      final boTextTheme = baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          height: 2.0,
          color: Colors.black,
        ),
      );
      return baseTheme.copyWith(textTheme: boTextTheme);
    }
    return baseTheme;
  }

  static ThemeData darkTheme([Locale? locale]) {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      fontFamily: _fontFamilyForLocale(locale),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF222222),
        foregroundColor: Colors.white30,
        elevation: 0,
      ),
      // textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      cardColor: Colors.grey.shade900,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
      ).copyWith(secondary: Colors.blueAccent, brightness: Brightness.dark),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF222222),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white24,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
    // If locale is Tibetan, set line height to 2.0 for all text styles
    if (locale?.languageCode == 'bo') {
      final baseTextTheme = baseTheme.textTheme;
      final boTextTheme = baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          height: 2.0,
          color: Colors.white,
        ),
      );
      return baseTheme.copyWith(textTheme: boTextTheme);
    }
    return baseTheme;
  }

  static String? _fontFamilyForLocale(Locale? locale) {
    if (locale?.languageCode == 'bo') {
      return 'MonlamTibetan';
    }
    return null; // Default font
  }
}
