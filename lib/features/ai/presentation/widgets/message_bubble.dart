import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/models/chat_message.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/source_bottom_sheet.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  /// Parse markdown bold and citations from content using two-pass approach
  List<InlineSpan> _parseContentWithCitations(
    BuildContext context,
    String content,
    List<SearchResult> searchResults,
    bool isDarkMode,
    TextStyle baseStyle,
  ) {
    // Map to track citation numbers and their widgets
    final Map<String, int> idToNumber = {};
    final Map<String, Widget> citationWidgets = {};
    int citationCounter = 0;

    // FIRST PASS: Replace valid citations with unique markers
    String processedContent = content;
    final citationRegex = RegExp(r'\[([a-zA-Z0-9\-_,\s]+)\]');

    processedContent = processedContent.replaceAllMapped(citationRegex, (
      match,
    ) {
      final citationContent = match.group(1)!;
      final ids =
          citationContent
              .split(RegExp(r'[,\s]+'))
              .where((id) => id.trim().isNotEmpty)
              .toList();

      String replacement = '';

      // Process each ID
      for (final id in ids) {
        final trimmedId = id.trim();

        // Check if this ID exists in search results
        final sourceIndex = searchResults.indexWhere((s) => s.id == trimmedId);

        if (sourceIndex != -1) {
          // Assign a citation number if not already assigned
          if (!idToNumber.containsKey(trimmedId)) {
            citationCounter++;
            idToNumber[trimmedId] = citationCounter;

            final citationNumber = citationCounter;
            final source = searchResults[sourceIndex];

            // Create citation widget and store it
            citationWidgets[trimmedId] = GestureDetector(
              onTap: () {
                SourceBottomSheet.show(context, source, citationNumber);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? AppColors.grey600.withOpacity(0.3)
                          : AppColors.grey300.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDarkMode ? AppColors.grey500 : AppColors.grey600,
                    width: 1,
                  ),
                ),
                child: Text(
                  '$citationNumber',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.grey300 : AppColors.grey800,
                  ),
                ),
              ),
            );
          }

          // Add marker for this citation
          replacement += '<<CITE:$trimmedId>>';
        }
        // If ID doesn't exist, don't add anything (ignore it)
      }

      return replacement;
    });

    // SECOND PASS: Parse bold text
    final List<InlineSpan> spans = [];
    final boldRegex = RegExp(r'\*\*([^*]+)\*\*');
    int lastMatchEnd = 0;

    for (final match in boldRegex.allMatches(processedContent)) {
      // Add text before the bold
      if (match.start > lastMatchEnd) {
        final textBefore = processedContent.substring(
          lastMatchEnd,
          match.start,
        );
        spans.addAll(
          _parseTextWithCitationMarkers(textBefore, citationWidgets, baseStyle),
        );
      }

      // Add bold text (may contain citation markers)
      final boldText = match.group(1)!;
      spans.addAll(
        _parseTextWithCitationMarkers(
          boldText,
          citationWidgets,
          baseStyle.copyWith(fontWeight: FontWeight.bold),
        ),
      );

      lastMatchEnd = match.end;
    }

    // Add remaining text after last bold
    if (lastMatchEnd < processedContent.length) {
      final remainingText = processedContent.substring(lastMatchEnd);
      spans.addAll(
        _parseTextWithCitationMarkers(
          remainingText,
          citationWidgets,
          baseStyle,
        ),
      );
    }

    return spans;
  }

  /// Helper method to parse text containing citation markers
  List<InlineSpan> _parseTextWithCitationMarkers(
    String text,
    Map<String, Widget> citationWidgets,
    TextStyle style,
  ) {
    final List<InlineSpan> spans = [];
    final markerRegex = RegExp(r'<<CITE:([a-zA-Z0-9\-_]+)>>');
    int lastMatchEnd = 0;

    for (final match in markerRegex.allMatches(text)) {
      // Add text before the marker
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: style,
          ),
        );
      }

      // Add citation widget
      final citationId = match.group(1)!;
      if (citationWidgets.containsKey(citationId)) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: citationWidgets[citationId]!,
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message Content
          Flexible(
            child:
                message.isUser
                    ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.backgroundDark,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        message.content,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                    )
                    : RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                        children: _parseContentWithCitations(
                          context,
                          message.content,
                          message.searchResults,
                          isDarkMode,
                          TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color:
                                isDarkMode
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
