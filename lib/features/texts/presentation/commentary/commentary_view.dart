import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/segment_provider.dart';
import 'package:flutter_pecha/features/texts/models/commentary/segment_commentary.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Constants for commentary view styling and behavior
class _CommentaryViewConstants {
  _CommentaryViewConstants._();

  // Spacing
  static const double horizontalPadding = 16.0;
  static const double cardSpacing = 16.0;
  static const double dividerHeight = 2.0;
  static const double dividerMargin = 8.0;
  static const double contentSpacing = 8.0;

  // Card styling
  static const double cardBorderRadius = 18.0;
  static const double shadowBlurRadius = 8.0;
  static const double shadowOffset = 2.0;
  static const double shadowAlpha = 0.03;

  // Text preview
  static const int previewMaxLength = 150;

  // AppBar divider
  static const double appBarDividerHeight = 2.0;
}

/// State provider for expanded commentary index, scoped by segment ID
final expandedCommentaryProvider = StateProvider.family<int?, String>(
  (ref, segmentId) => null,
);

class CommentaryView extends ConsumerWidget {
  const CommentaryView({super.key, required this.segmentId});

  final String segmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedIndex = ref.watch(expandedCommentaryProvider(segmentId));
    final segmentCommentaries = ref.watch(
      segmentCommentaryFutureProvider(segmentId),
    );

    return Scaffold(
      appBar: _CommentaryAppBar(
        onBackPressed: () {
          ref.read(expandedCommentaryProvider(segmentId).notifier).state = null;
          context.pop();
        },
      ),
      body: segmentCommentaries.when(
        data:
            (data) => _CommentaryContent(
              commentaries: data.commentaries,
              expandedIndex: expandedIndex,
              segmentId: segmentId,
              onExpansionChanged: (index) {
                ref.read(expandedCommentaryProvider(segmentId).notifier).state =
                    index;
              },
            ),
        error:
            (error, stackTrace) => _ErrorState(
              error: error,
              onRetry: () {
                ref.invalidate(segmentCommentaryFutureProvider(segmentId));
              },
            ),
        loading: () => const _LoadingState(),
      ),
    );
  }
}

/// AppBar for commentary view
class _CommentaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CommentaryAppBar({required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: onBackPressed,
        icon: const Icon(Icons.arrow_back_ios),
        tooltip: 'Back',
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(
          _CommentaryViewConstants.appBarDividerHeight,
        ),
        child: Container(
          height: _CommentaryViewConstants.appBarDividerHeight,
          color: AppColors.greyLight,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(
    kToolbarHeight + _CommentaryViewConstants.appBarDividerHeight,
  );
}

/// Main content widget displaying commentaries
class _CommentaryContent extends StatelessWidget {
  const _CommentaryContent({
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

    final totalCommentaries = commentaries.fold<int>(
      0,
      (sum, commentary) => sum + commentary.count,
    );

    return ListView.builder(
      padding: const EdgeInsets.all(_CommentaryViewConstants.horizontalPadding),
      itemCount: commentaries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CommentaryHeader(totalCount: totalCommentaries);
        }

        final commentary = commentaries[index - 1];
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

/// Header showing total commentary count
class _CommentaryHeader extends StatelessWidget {
  const _CommentaryHeader({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: _CommentaryViewConstants.cardSpacing,
      ),
      child: Text(
        'All Commentary ($totalCount)',
        style: Theme.of(context).textTheme.titleMedium,
      ),
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
        bottom: _CommentaryViewConstants.cardSpacing,
      ),
      padding: const EdgeInsets.all(_CommentaryViewConstants.horizontalPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          _CommentaryViewConstants.cardBorderRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _CommentaryViewConstants.shadowAlpha,
            ),
            blurRadius: _CommentaryViewConstants.shadowBlurRadius,
            offset: const Offset(0, _CommentaryViewConstants.shadowOffset),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentaryTitle(
            title: commentary.title,
            contentCount: commentary.content.length,
            language: commentary.language,
          ),
          const SizedBox(height: _CommentaryViewConstants.contentSpacing),
          const _CommentaryDivider(),
          const SizedBox(height: _CommentaryViewConstants.contentSpacing),
          _CommentaryContentText(
            content: commentary.content,
            isExpanded: isExpanded,
            language: commentary.language,
          ),
          const SizedBox(height: _CommentaryViewConstants.contentSpacing),
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
    return Text(
      '$title ($contentCount)',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontFamily: getFontFamily(language)),
    );
  }
}

/// Divider widget for commentary card
class _CommentaryDivider extends StatelessWidget {
  const _CommentaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _CommentaryViewConstants.dividerHeight,
      color: AppColors.greyLight,
      margin: const EdgeInsets.only(
        bottom: _CommentaryViewConstants.dividerMargin,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          content.map((text) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: _CommentaryViewConstants.contentSpacing,
              ),
              child: Text(
                isExpanded ? text : _getPreview(text),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: getFontFamily(language),
                  height: getLineHeight(language),
                ),
              ),
            );
          }).toList(),
    );
  }

  String _getPreview(String content) {
    if (content.length <= _CommentaryViewConstants.previewMaxLength) {
      return content;
    }
    return content.substring(0, _CommentaryViewConstants.previewMaxLength);
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
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          isExpanded ? 'Show less' : 'Read more',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          _CommentaryViewConstants.horizontalPadding * 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No commentary found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'There are no commentaries available for this segment.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
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
          _CommentaryViewConstants.horizontalPadding * 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
