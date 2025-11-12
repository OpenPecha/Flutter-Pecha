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

/// Calculates the share position origin for share_plus ShareParams.
///
/// Tries to get the position from the provided [context] or [globalKey].
/// Falls back to screen center if unable to determine position.
///
/// [context] - BuildContext to find render box position
/// [globalKey] - Optional GlobalKey to find widget position
///
/// Returns a Rect representing the share position origin.
Rect getSharePositionOrigin({
  required BuildContext context,
  GlobalKey? globalKey,
}) {
  try {
    // Try to get position from globalKey first if provided
    if (globalKey != null) {
      final RenderBox? box =
          globalKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final Offset position = box.localToGlobal(Offset.zero);
        final Size size = box.size;
        return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
      }
    }

    // Try to get position from context
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final Offset position = box.localToGlobal(Offset.zero);
      final Size size = box.size;
      return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    }
  } catch (e) {
    // Fall through to screen center fallback
  }

  // Fallback to screen center
  final screenSize = MediaQuery.of(context).size;
  return Rect.fromLTWH(
    screenSize.width * 0.5 - 50,
    screenSize.height * 0.5 - 50,
    100,
    100,
  );
}
