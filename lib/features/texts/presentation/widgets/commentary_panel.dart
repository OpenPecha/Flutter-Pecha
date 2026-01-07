import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/segment_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/models/commentary/segment_commentary.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Constants for commentary panel styling
class _CommentaryPanelConstants {
  _CommentaryPanelConstants._();

  static const double horizontalPadding = 16.0;
  static const double cardSpacing = 16.0;
  static const double dividerHeight = 2.0;
  static const double dividerMargin = 8.0;
  static const double contentSpacing = 8.0;
  static const int previewMaxLength = 150;
}

/// State provider for expanded commentary index in split panel, scoped by segment ID
final expandedCommentaryPanelProvider = StateProvider.family<int?, String>(
  (ref, segmentId) => null,
);

/// A panel widget that displays commentary for a segment in a split screen view.
class CommentaryPanel extends ConsumerWidget {
  const CommentaryPanel({super.key, required this.segmentId});

  final String segmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedIndex = ref.watch(expandedCommentaryPanelProvider(segmentId));
    final segmentCommentaries = ref.watch(
      segmentCommentaryFutureProvider(segmentId),
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          // Header with close button
          _CommentaryPanelHeader(
            onClose: () {
              ref.read(commentarySplitSegmentProvider.notifier).state = null;
              ref
                  .read(expandedCommentaryPanelProvider(segmentId).notifier)
                  .state = null;
            },
          ),
          // Content
          Expanded(
            child: segmentCommentaries.when(
              data:
                  (data) => _CommentaryPanelContent(
                    commentaries: data.commentaries,
                    expandedIndex: expandedIndex,
                    segmentId: segmentId,
                    onExpansionChanged: (index) {
                      ref
                          .read(
                            expandedCommentaryPanelProvider(segmentId).notifier,
                          )
                          .state = index;
                    },
                  ),
              error:
                  (error, stackTrace) => _ErrorState(
                    error: error,
                    onRetry: () {
                      ref.invalidate(
                        segmentCommentaryFutureProvider(segmentId),
                      );
                    },
                  ),
              loading: () => const _LoadingState(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header for the commentary panel with close button
class _CommentaryPanelHeader extends StatelessWidget {
  const _CommentaryPanelHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.greyDark
                    : AppColors.greyLight,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            localizations.text_commentary,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: localizations.text_close_commentary,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

/// Main content widget displaying commentaries in panel
class _CommentaryPanelContent extends StatelessWidget {
  const _CommentaryPanelContent({
    required this.commentaries,
    required this.expandedIndex,
    required this.segmentId,
    required this.onExpansionChanged,
  });

  final List<SegmentCommentary> commentaries;
  final int? expandedIndex;
  final String segmentId;
  final ValueChanged<int?> onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    if (commentaries.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(
        _CommentaryPanelConstants.horizontalPadding,
      ),
      itemCount: commentaries.length,
      itemBuilder: (context, index) {
        final commentary = commentaries[index];
        final isExpanded = expandedIndex == index;

        return _CommentaryCard(
          commentary: commentary,
          isExpanded: isExpanded,
          index: index,
          onExpansionChanged: onExpansionChanged,
        );
      },
    );
  }
}

/// Card widget for individual commentary
class _CommentaryCard extends StatelessWidget {
  const _CommentaryCard({
    required this.commentary,
    required this.isExpanded,
    required this.index,
    required this.onExpansionChanged,
  });

  final SegmentCommentary commentary;
  final bool isExpanded;
  final int index;
  final ValueChanged<int?> onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: _CommentaryPanelConstants.cardSpacing,
        top: _CommentaryPanelConstants.cardSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentaryTitle(
            title: commentary.title,
            contentCount: commentary.segments.length,
            language: commentary.language,
          ),
          const SizedBox(height: _CommentaryPanelConstants.contentSpacing),
          const _CommentaryDivider(),
          const SizedBox(height: _CommentaryPanelConstants.contentSpacing),
          _CommentaryContentText(
            content: commentary.segments.map((e) => e.content).toList(),
            isExpanded: isExpanded,
            language: commentary.language,
          ),
          const SizedBox(height: _CommentaryPanelConstants.contentSpacing),
          _CommentaryExpansionButton(
            isExpanded: isExpanded,
            onPressed: () {
              onExpansionChanged(isExpanded ? null : index);
            },
          ),
        ],
      ),
    );
  }
}

/// Title widget for commentary card
class _CommentaryTitle extends StatelessWidget {
  const _CommentaryTitle({
    required this.title,
    required this.contentCount,
    required this.language,
  });

  final String title;
  final int contentCount;
  final String language;

  @override
  Widget build(BuildContext context) {
    final fontFamily = getFontFamily(language);
    final fontSize = language == 'bo' ? 21.0 : 17.0;
    return Text(
      '$title ($contentCount)',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontFamily: fontFamily,
        fontSize: fontSize,
      ),
    );
  }
}

/// Divider widget for commentary card
class _CommentaryDivider extends StatelessWidget {
  const _CommentaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _CommentaryPanelConstants.dividerHeight,
      color:
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.greyDark
              : Colors.grey,
      margin: const EdgeInsets.only(
        bottom: _CommentaryPanelConstants.dividerMargin,
      ),
    );
  }
}

/// Content text widget with preview/expand functionality
class _CommentaryContentText extends StatelessWidget {
  const _CommentaryContentText({
    required this.content,
    required this.isExpanded,
    required this.language,
  });

  final List<String> content;
  final bool isExpanded;
  final String language;

  @override
  Widget build(BuildContext context) {
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final fontSize = language == 'bo' ? 20.0 : 16.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          content.map((text) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: _CommentaryPanelConstants.contentSpacing,
              ),
              child: Text(
                isExpanded ? text : _getPreview(text),
                style: TextStyle(
                  fontFamily: fontFamily,
                  height: lineHeight,
                  fontSize: fontSize,
                ),
              ),
            );
          }).toList(),
    );
  }

  String _getPreview(String content) {
    if (content.length <= _CommentaryPanelConstants.previewMaxLength) {
      return content;
    }
    return content.substring(0, _CommentaryPanelConstants.previewMaxLength);
  }
}

/// Expansion button widget for commentary card
class _CommentaryExpansionButton extends StatelessWidget {
  const _CommentaryExpansionButton({
    required this.isExpanded,
    required this.onPressed,
  });

  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          isExpanded ? localizations.show_less : localizations.show_more,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

/// Empty state widget when no commentaries are found
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          _CommentaryPanelConstants.horizontalPadding * 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.no_commentary,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state widget
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Error state widget with retry functionality
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          _CommentaryPanelConstants.horizontalPadding * 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
