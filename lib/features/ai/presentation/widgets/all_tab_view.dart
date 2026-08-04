import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/ai/data/models/search_state.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/search_result_card.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_source_result.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/skeletons/search_result_skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

class AllTabView extends StatelessWidget {
  final SearchState searchState;
  final Function(SearchTab) onShowMore;
  final VoidCallback onRetry;

  const AllTabView({
    super.key,
    required this.searchState,
    required this.onShowMore,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = context.l10n;

    if (searchState.isLoading) {
      return const SearchResultSkeleton();
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
                label: Text(searchState.isLoading ? localizations.search_retrying : localizations.ai_retry),
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

    final contentResults = searchState.contentResults;
    final titleResults = searchState.titleResults;
    final authorResults = searchState.authorResults;

    // Check if we have any results at all
    final hasContentResults =
        contentResults != null && contentResults.sources.isNotEmpty;
    final hasTitleResults =
        titleResults != null && titleResults.results.isNotEmpty;
    final hasAuthorResults =
        authorResults != null && authorResults.results.isNotEmpty;

    if (!hasContentResults && !hasTitleResults && !hasAuthorResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            localizations.search_no_results(searchState.currentQuery),
            style: TextStyle(
              color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Get first 3 results for each section
    final topContentResults =
        hasContentResults
            ? contentResults.sources.take(3).toList()
            : <MultilingualSourceResult>[];
    final topTitleResults =
        hasTitleResults ? titleResults.results.take(3).toList() : [];
    final topAuthorResults =
        hasAuthorResults ? authorResults.results.take(3).toList() : [];

    final hasMoreContent = hasContentResults && contentResults.sources.length >= 2;
    final hasMoreTitles = hasTitleResults && titleResults.results.length >= 2;
    final hasMoreAuthors = hasAuthorResults && authorResults.results.length >= 2;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Titles Section - Only show if there are results
        if (hasTitleResults) ...[
          _buildSectionHeader(context, isDarkMode, localizations.search_titles),
          ...topTitleResults.map(
            (item) => _buildTitleResultCard(context, item, isDarkMode),
          ),
          if (hasMoreTitles) ...[
            const SizedBox(height: 25),
            _buildShowMoreButton(context, isDarkMode, SearchTab.titles, localizations),
          ],
          const SizedBox(height: 24),
        ],

        // Contents Section - Only show if there are results
        if (hasContentResults) ...[
          _buildSectionHeader(context, isDarkMode, localizations.search_contents),
          ...topContentResults.map(
            (source) => _buildContentResultCard(
              context,
              source,
              searchState.currentQuery,
            ),
          ),
          if (hasMoreContent) ...[
            const SizedBox(height: 25),
            _buildShowMoreButton(context, isDarkMode, SearchTab.contents, localizations),
          ],
          const SizedBox(height: 24),
        ],

        // Author Section - Only show if there are results
        if (hasAuthorResults) ...[
          _buildSectionHeader(context, isDarkMode, localizations.search_author),
          ...topAuthorResults.map(
            (item) => _buildAuthorResultCard(context, item, isDarkMode),
          ),
          if (hasMoreAuthors) ...[
            const SizedBox(height: 25),
            _buildShowMoreButton(context, isDarkMode, SearchTab.author, localizations),
          ],
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    bool isDarkMode,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? AppColors.surfaceWhite : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildContentResultCard(
    BuildContext context,
    MultilingualSourceResult source,
    String query,
  ) {
    // Reuse existing SearchResultCard - only show first segment
    final segments =
        source.segmentMatches.isNotEmpty
            ? <Map<String, String>>[
              {
                'segmentId': source.segmentMatches[0].segmentId,
                'content': source.segmentMatches[0].content,
              },
            ]
            : <Map<String, String>>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchResultCard(
        textId: source.text.textId,
        textTitle: source.text.title,
        segments: segments,
        searchQuery: query,
      ),
    );
  }

  Widget _buildTitleResultCard(
    BuildContext context,
    dynamic item,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.grey900 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.grey800 : AppColors.grey300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to new reader with normal context
          final navigationContext = NavigationContext(
            source: NavigationSource.normal,
          );
          context.push(
            '/reader/${item.id}',
            extra: navigationContext,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        isDarkMode
                            ? AppColors.surfaceWhite
                            : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                color: isDarkMode ? AppColors.grey600 : AppColors.grey400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorResultCard(
    BuildContext context,
    dynamic item,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.grey900 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.grey800 : AppColors.grey300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to new reader with normal context
          final navigationContext = NavigationContext(
            source: NavigationSource.normal,
          );
          context.push(
            '/reader/${item.id}',
            extra: navigationContext,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        isDarkMode
                            ? AppColors.surfaceWhite
                            : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                color: isDarkMode ? AppColors.grey600 : AppColors.grey400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShowMoreButton(
    BuildContext context,
    bool isDarkMode,
    SearchTab tab,
    AppLocalizations localizations,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => onShowMore(tab),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.accentGold.withValues(alpha: 0.5),
              width: 1,
            ),
            color: AppColors.accentGold.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                localizations.search_show_more,
                style: TextStyle(
                  color: AppColors.accentGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.accentGold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
