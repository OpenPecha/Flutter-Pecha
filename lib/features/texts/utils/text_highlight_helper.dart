import 'package:flutter/material.dart';

/// Builds a list of TextSpan with highlighted matches for the search query
///
/// [text] The full text to display
/// [query] The search query to highlight
/// [baseStyle] The base TextStyle for non-highlighted text
///
/// Returns a list of TextSpan with highlighted matches using yellow background
List<TextSpan> buildHighlightedText(
  String text,
  String query,
  TextStyle? baseStyle,
) {
  if (query.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final List<TextSpan> spans = [];
  final lowerText = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  int start = 0;

  while (start < text.length) {
    final index = lowerText.indexOf(lowerQuery, start);
    if (index == -1) {
      // No more matches, add remaining text
      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
      }
      break;
    }

    // Add text before match
    if (index > start) {
      spans.add(TextSpan(text: text.substring(start, index), style: baseStyle));
    }

    // Add highlighted match
    final matchText = text.substring(index, index + query.length);
    spans.add(
      TextSpan(
        text: matchText,
        style: baseStyle?.copyWith(backgroundColor: const Color(0xFFFFFF00)),
      ),
    );

    start = index + query.length;
  }

  return spans;
}
