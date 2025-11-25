import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/constants/text_routes.dart';
import 'package:flutter_pecha/features/texts/utils/text_highlight_helper.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Widget for displaying search result cards with highlighted matches
class SearchResultCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final fontSize = language == 'bo' ? 22.0 : 18.0;
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      margin: TextScreenConstants.cardMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text title shown once
          Text(
            textTitle,
            style: TextStyle(
              fontFamily: fontFamily,
              height: lineHeight,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: TextScreenConstants.smallVerticalSpacing),
          Divider(height: TextScreenConstants.thinDividerThickness),
          SizedBox(height: TextScreenConstants.contentVerticalSpacing),
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
                _buildSegmentItem(
                  context,
                  textId,
                  segmentId,
                  cleanContent,
                  language,
                ),
                if (segmentIndex < segments.length - 1)
                  const SizedBox(
                    height: TextScreenConstants.contentVerticalSpacing,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(
    BuildContext context,
    String textId,
    String segmentId,
    String content,
    String language,
  ) {
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final fontSize = language == 'bo' ? 22.0 : 18.0;
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
              context,
              content,
              searchQuery,
              TextStyle(
                fontSize: fontSize,
                fontFamily: fontFamily,
                height: lineHeight,
              ),
            ),
          ),
          maxLines: TextScreenConstants.searchResultMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
