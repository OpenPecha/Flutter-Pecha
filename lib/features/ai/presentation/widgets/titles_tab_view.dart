import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/data/models/search_state.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/skeletons/search_result_skeleton.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

/// Tab view for displaying title search results with pagination
class TitlesTabView extends ConsumerStatefulWidget {
  final SearchState searchState;
  final VoidCallback onRetry;

  const TitlesTabView({
    super.key,
    required this.searchState,
    required this.onRetry,
  });

  @override
  ConsumerState<TitlesTabView> createState() => _TitlesTabViewState();
}

class _TitlesTabViewState extends ConsumerState<TitlesTabView> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    final titleResults = widget.searchState.titleResults;
    if (titleResults == null || !titleResults.hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentOffset += _pageSize;
    });

    try {
      final params = TitleSearchParams(
        title: widget.searchState.currentQuery,
        limit: _pageSize,
        offset: _currentOffset,
      );

      final result = await ref.read(titleSearchProvider(params).future);
      result.fold(
        (failure) {
          // Error handling - silently ignore for pagination
        },
        (_) {
          // Success - provider will invalidate and refresh
        },
      );
    } catch (e) {
      // Error handling is done in the provider
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = context.l10n;

    if (widget.searchState.isLoading && _currentOffset == 0) {
      return const SearchResultSkeleton(mode: SearchResultSkeletonMode.titles);
    }

    if (widget.searchState.error != null && _currentOffset == 0) {
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
                localizations.search_error(widget.searchState.error!),
                style: TextStyle(
                  color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.searchState.isLoading ? null : widget.onRetry,
                icon: Icon(
                  widget.searchState.isLoading
                      ? Icons.hourglass_empty
                      : Icons.refresh,
                ),
                label: Text(
                  widget.searchState.isLoading
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

    final titleResults = widget.searchState.titleResults;
    if (titleResults == null || titleResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            localizations.search_no_titles_found(
              widget.searchState.currentQuery,
            ),
            style: TextStyle(
              color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: titleResults.results.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == titleResults.results.length) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accentGold),
            ),
          );
        }

        final item = titleResults.results[index];
        return _buildTitleResultCard(context, item, isDarkMode);
      },
    );
  }

  Widget _buildTitleResultCard(
    BuildContext context,
    dynamic item,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          final navigationContext = NavigationContext(
            source: NavigationSource.normal,
          );
          context.push('/reader/${item.id}', extra: navigationContext);
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
                    fontSize: 16,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
