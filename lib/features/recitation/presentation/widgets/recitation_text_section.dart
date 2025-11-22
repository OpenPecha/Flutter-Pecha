import 'package:flutter/material.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// A widget that displays a section of recitation text.
///
/// This widget handles:
/// - Replacing HTML break tags with newlines
/// - Applying language-specific text styling
/// - Proper text rendering with appropriate line height and font family
class RecitationTextSection extends StatelessWidget {
  /// The text content to display
  final String text;

  /// The language code (e.g., 'bo', 'en', 'zh')
  final String languageCode;

  const RecitationTextSection({
    super.key,
    required this.text,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    // Replace HTML break tags with newlines
    final processedText = _processText(text);

    // Get language-specific styling
    final fontFamily = getFontFamily(languageCode);
    final lineHeight = getLineHeight(languageCode);
    final fontSize = languageCode == 'bo' ? 24.0 : 20.0;

    return Text(
      processedText,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: lineHeight,
        fontSize: fontSize,
        fontFamily: fontFamily,
      ),
    );
  }

  /// Processes the text by replacing HTML break tags with newlines.
  ///
  /// Handles both <br> and <br/> tags.
  String _processText(String text) {
    return text.replaceAll('<br>', '\n').replaceAll('<br/>', '\n');
  }
}
