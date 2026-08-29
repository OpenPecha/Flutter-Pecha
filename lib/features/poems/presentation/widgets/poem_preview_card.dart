import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';

/// A single poem preview shown on the home page — cover image, title, a
/// truncated excerpt, and the author, matching the "Poems" home section.
///
/// Tapping the card opens the full-screen swipeable poems viewer starting on
/// this poem.
class PoemPreviewCard extends StatelessWidget {
  const PoemPreviewCard({super.key, required this.poem, required this.onTap});

  final Poem poem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child:
                poem.imageUrl != null && poem.imageUrl!.isNotEmpty
                    ? CachedNetworkImageWidget(
                      imageUrl: poem.imageUrl,
                      fit: BoxFit.cover,
                    )
                    : ColoredBox(
                      color: placeholderColor,
                      child: Icon(
                        AppAssets.bookOpenText,
                        size: 40,
                        color:
                            isDark ? AppColors.grey500 : AppColors.grey600,
                      ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              poem.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _PoemPreviewExcerpt(
              content: poem.content,
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 4, 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  poem.authorName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(
                      AppAssets.readerShare,
                      size: 20,
                      color: secondaryColor,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: context.l10n.share,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows poem lines with their original breaks and appends `...` when clipped.
class _PoemPreviewExcerpt extends StatelessWidget {
  const _PoemPreviewExcerpt({required this.content, required this.style});

  final String content;
  final TextStyle style;

  static const _maxLines = 3;
  static const _ellipsis = '...';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        final textSpan = TextSpan(text: content, style: style);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: _maxLines,
          textDirection: textDirection,
        )..layout(maxWidth: constraints.maxWidth);

        if (!textPainter.didExceedMaxLines) {
          return Text(
            content,
            style: style,
            textAlign: TextAlign.center,
          );
        }

        final ellipsisSpan = TextSpan(text: _ellipsis, style: style);

        var endIndex = content.length;
        var startIndex = 0;

        while (startIndex < endIndex) {
          final mid = startIndex + ((endIndex - startIndex) ~/ 2);
          final testPainter = TextPainter(
            text: TextSpan(
              text: content.substring(0, mid),
              style: style,
              children: [ellipsisSpan],
            ),
            maxLines: _maxLines,
            textDirection: textDirection,
          )..layout(maxWidth: constraints.maxWidth);

          if (testPainter.didExceedMaxLines) {
            endIndex = mid;
          } else {
            startIndex = mid + 1;
          }
        }

        final validLength = (startIndex - 1).clamp(0, content.length);
        final truncatedText = content.substring(0, validLength).trimRight();

        return Text.rich(
          TextSpan(
            text: truncatedText,
            style: style,
            children: [ellipsisSpan],
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
