import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';

extension HelperFunctions on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}

// Helper function to get the font family for content text (backend texts, recitations, etc.)
// This returns the content font for the given language
String? getFontFamily(String language) {
  return AppFontConfig.getFontFamily(language, FontType.content);
}

// Helper function to get TextStyle for content with appropriate font
// Use this for content widgets that need Google Fonts or local fonts
TextStyle? getContentTextStyle(String? language, TextStyle? baseStyle) {
  return AppFontConfig.getContentTextStyle(language, baseStyle);
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
