import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/constants/text_routes.dart';
import 'package:flutter_pecha/features/texts/utils/text_highlight_helper.dart';
import 'package:go_router/go_router.dart';

/// Widget for displaying search result cards with highlighted matches
class SearchResultCard extends StatelessWidget {
  final String textId;
  final String textTitle;
  final List<Map<String, String>> segments;
  final String searchQuery;

  const SearchResultCard({
    super.key,
    required this.textId,
    required this.textTitle,
    required this.segments,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: TextScreenConstants.cardMargin,
      child: Padding(
        padding: TextScreenConstants.cardPaddingValue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text title shown once
            Text(
              textTitle,
              style: const TextStyle(
                fontSize: TextScreenConstants.largeTitleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: TextScreenConstants.smallVerticalSpacing),
            const Divider(height: TextScreenConstants.thinDividerThickness),
            const SizedBox(height: TextScreenConstants.contentVerticalSpacing),
            // List all segments for this text
            ...segments.asMap().entries.map((entry) {
              final segmentIndex = entry.key;
              final segment = entry.value;
              final segmentId = segment['segmentId']!;
              final content = segment['content']!;
              final cleanContent = content.replaceAll(RegExp(r'<[^>]*>'), '');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSegmentItem(context, textId, segmentId, cleanContent),
                  if (segmentIndex < segments.length - 1)
                    const SizedBox(
                      height: TextScreenConstants.contentVerticalSpacing,
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentItem(
    BuildContext context,
    String textId,
    String segmentId,
    String content,
  ) {
    return InkWell(
      onTap: () {
        context.push(
          TextRoutes.chapters,
          extra: {'textId': textId, 'segmentId': segmentId},
        );
      },
      borderRadius: BorderRadius.circular(TextScreenConstants.cardBorderRadius),
      child: Container(
        width: double.infinity,
        padding: TextScreenConstants.cardInnerPaddingValue,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(
            TextScreenConstants.cardBorderRadius,
          ),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: TextScreenConstants.thinDividerThickness,
          ),
        ),
        child: Text.rich(
          TextSpan(
            children: buildHighlightedText(
              content,
              searchQuery,
              TextStyle(fontSize: TextScreenConstants.subtitleFontSize),
            ),
          ),
          maxLines: TextScreenConstants.searchResultMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
