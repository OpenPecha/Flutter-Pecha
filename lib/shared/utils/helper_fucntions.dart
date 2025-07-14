// This file contains helper functions that are used throughout the app

import 'package:flutter/material.dart';

extension HelperFunctions on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}

// Helper function to get the font family for a given language
String? getFontFamily(String language) {
  switch (language) {
    case "bo":
      return "MonlamTibetan";
    case "en":
      return null;
    case "sa":
      return "MonlamTibetan";
    case "zh":
      return null;
    default:
      return null;
  }
}

// Helper function to get the line height for a given language
double? getLineHeight(String language) {
  switch (language) {
    case "bo":
      return 2;
    case "en":
      return 1.5;
    case "sa":
      return 2;
    case "zh":
      return 1.5;
    default:
      return 1.5;
  }
}

// Helper function to get the font size for a given language
double? getFontSize(String language) {
  switch (language) {
    case "bo":
      return 18;
    case "en":
      return 20;
    case "sa":
      return 18;
    case "zh":
      return 18;
    default:
      return null;
  }
}
