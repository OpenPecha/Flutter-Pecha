import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/ai/data/models/search_state.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/search_result_card.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/skeletons/search_result_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

/// Tab view for displaying content search results
class ContentsTabView extends ConsumerWidget {
  final SearchState searchState;
  final VoidCallback onRetry;

  const ContentsTabView({
    super.key,
    required this.searchState,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = context.l10n;

    if (searchState.isLoading) {
      return const SearchResultSkeleton(
        mode: SearchResultSkeletonMode.contents,
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDarkMode ? AppColors.grey500 : AppColors.grey400,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.search_error(searchState.error!),
                style: TextStyle(
                  color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: searchState.isLoading ? null : onRetry,
                icon: Icon(
                  searchState.isLoading ? Icons.hourglass_empty : Icons.refresh,
                ),
                label: Text(
                  searchState.isLoading
                      ? localizations.search_retrying
                      : localizations.ai_retry,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final results = searchState.contentResults;
    if (results == null || results.sources.isEmpty) {
      return Center(
        child: Text(
          localizations.search_no_contents_found(searchState.currentQuery),
          style: TextStyle(
            color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Group results by text (reuse logic from collections_screen.dart)
    final groupedResults = _groupResultsByText(results);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groupedResults.length,
      itemBuilder: (context, index) {
        final textGroup = groupedResults.values.toList()[index];
        return SearchResultCard(
          textId: textGroup['textId'] as String,
          textTitle: textGroup['textTitle'] as String,
          segments: textGroup['segments'] as List<Map<String, String>>,
          searchQuery: searchState.currentQuery,
        );
      },
    );
  }

  /// Group search results by text ID
  Map<String, Map<String, dynamic>> _groupResultsByText(
    MultilingualSearchResponse response,
  ) {
    final groupedResults = <String, Map<String, dynamic>>{};

    for (final source in response.sources) {
      if (!groupedResults.containsKey(source.text.textId)) {
        groupedResults[source.text.textId] = {
          'textId': source.text.textId,
          'textTitle': source.text.title,
          'segments': <Map<String, String>>[],
        };
      }
      for (final segmentMatch in source.segmentMatches) {
        (groupedResults[source.text.textId]!['segments']
                as List<Map<String, String>>)
            .add({
              'segmentId': segmentMatch.segmentId,
              'content': segmentMatch.content,
            });
      }
    }

    return groupedResults;
  }
}
