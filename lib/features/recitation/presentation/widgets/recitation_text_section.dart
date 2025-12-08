import 'package:flutter/material.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// A widget that displays a section of recitation text.
///
/// This widget handles:
/// - Replacing HTML break tags with newlines
/// - Applying language-specific text styling
/// - Applying index-based colors for light and dark modes
/// - Proper text rendering with appropriate line height and font family
class RecitationTextSection extends StatelessWidget {
  final String text;

  final String languageCode;

  final int textIndex;

  const RecitationTextSection({
    super.key,
    required this.text,
    required this.languageCode,
    required this.textIndex,
  });

  @override
  Widget build(BuildContext context) {
    final processedText = _processText(text);

    final fontFamily = getFontFamily(languageCode);
    final lineHeight = getLineHeight(languageCode);
    final fontSize =
        languageCode == 'bo' || languageCode == 'tib' ? 24.0 : 20.0;

    final textColor = _getColorForTextIndex(context);

    return Text(
      processedText,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: lineHeight,
        fontSize: fontSize,
        fontFamily: fontFamily,
        color: textColor,
      ),
    );
  }

  /// Returns the appropriate text color based on text index and theme mode.
  /// Dark mode colors are automatically adjusted for better readability.
  Color _getColorForTextIndex(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return switch (textIndex) {
      0 =>
        isDarkMode
            ? const Color(0xFFD89070) // Lighter brown for dark mode
            : const Color(0xFF954a29), // Brown for light mode
      1 =>
        isDarkMode
            ? const Color(0xFFE5E5E5) // Light gray for dark mode
            : Colors.black, // Black for light mode
      2 =>
        isDarkMode
            ? const Color(0xFFD0D0CF) // Light gray for dark mode
            : const Color(0xFF2b2b2a), // Dark gray for light mode
      _ =>
        isDarkMode
            ? const Color(0xFFE5E5E5) // Default light gray for dark mode
            : Colors.black, // Default black for light mode
    };
  }

  /// Processes the text by replacing HTML break tags with newlines.
  /// Handles both <br> and <br/> tags.
  String _processText(String text) {
    return text.replaceAll('<br>', '\n').replaceAll('<br/>', '\n');
  }
}
