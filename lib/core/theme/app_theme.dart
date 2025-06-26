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
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: Colors.black),
        prefixIconColor: Colors.black45,
        fillColor: const Color(0xFFefefef),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black),
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
        displayLarge: baseTextTheme.displayLarge?.copyWith(height: 2.0),
        displayMedium: baseTextTheme.displayMedium?.copyWith(height: 2.0),
        displaySmall: baseTextTheme.displaySmall?.copyWith(height: 2.0),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(height: 2.0),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(height: 2.0),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(height: 2.0),
        titleLarge: baseTextTheme.titleLarge?.copyWith(height: 2.0),
        titleMedium: baseTextTheme.titleMedium?.copyWith(height: 2.0),
        titleSmall: baseTextTheme.titleSmall?.copyWith(height: 2.0),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 2.0),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 2.0),
        bodySmall: baseTextTheme.bodySmall?.copyWith(height: 2.0),
        labelLarge: baseTextTheme.labelLarge?.copyWith(height: 2.0),
        labelMedium: baseTextTheme.labelMedium?.copyWith(height: 2.0),
        labelSmall: baseTextTheme.labelSmall?.copyWith(height: 2.0),
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
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        displayLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.white),
        displaySmall: TextStyle(color: Colors.white),
      ),
      cardColor: const Color(0xFF232121),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
      ).copyWith(secondary: Colors.blueAccent, brightness: Brightness.dark),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIconColor: Colors.grey[400],
        fillColor: const Color(0xFF444444),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF121212),
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFF7f7f7f),
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
    // If locale is Tibetan, set line height to 2.0 for all text styles
    if (locale?.languageCode == 'bo') {
      final baseTextTheme = baseTheme.textTheme;
      final boTextTheme = baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(height: 2.0),
        displayMedium: baseTextTheme.displayMedium?.copyWith(height: 2.0),
        displaySmall: baseTextTheme.displaySmall?.copyWith(height: 2.0),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(height: 2.0),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(height: 2.0),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(height: 2.0),
        titleLarge: baseTextTheme.titleLarge?.copyWith(height: 2.0),
        titleMedium: baseTextTheme.titleMedium?.copyWith(height: 2.0),
        titleSmall: baseTextTheme.titleSmall?.copyWith(height: 2.0),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 2.0),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 2.0),
        bodySmall: baseTextTheme.bodySmall?.copyWith(height: 2.0),
        labelLarge: baseTextTheme.labelLarge?.copyWith(height: 2.0),
        labelMedium: baseTextTheme.labelMedium?.copyWith(height: 2.0),
        labelSmall: baseTextTheme.labelSmall?.copyWith(height: 2.0),
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
