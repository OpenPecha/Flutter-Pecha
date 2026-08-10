import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';

/// Builds a scrollable list with standard loading, error, empty, and
/// paginated footer states for Connect My/Discover tabs.
class ConnectPaginatedListView<T> extends StatelessWidget {
  const ConnectPaginatedListView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
    required this.hasMore,
    required this.onRetry,
    required this.itemBuilder,
    this.scrollController,
    this.separatorHeight = 16,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 24),
    this.emptyDiscoverMessage,
    this.myEmptyState,
    this.leadingItemCount = 0,
    this.leadingItemBuilder,
  });

  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final ScrollController? scrollController;
  final VoidCallback onRetry;
  final IndexedWidgetBuilder itemBuilder;
  final double separatorHeight;
  final EdgeInsets padding;
  final String? emptyDiscoverMessage;
  final Widget? myEmptyState;
  final int leadingItemCount;
  final WidgetBuilder? leadingItemBuilder;

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return _scrollableState(
        const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null && items.isEmpty) {
      return _scrollableState(
        ErrorStateWidget(error: error!, onRetry: onRetry),
      );
    }

    if (items.isEmpty && !isLoading) {
      if (myEmptyState != null) {
        return _scrollableState(myEmptyState!, hasScrollBody: false);
      }

      if (emptyDiscoverMessage != null) {
        return _scrollableState(
          Center(
            child: Text(
              emptyDiscoverMessage!,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }

      return _scrollableState(const SizedBox.shrink());
    }

    final itemCount = leadingItemCount + items.length + (hasMore ? 1 : 0);

    return ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: separatorHeight),
      itemBuilder: (context, index) {
        if (index < leadingItemCount) {
          return leadingItemBuilder!(context);
        }

        final dataIndex = index - leadingItemCount;
        if (dataIndex == items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child:
                  isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        return itemBuilder(context, dataIndex);
      },
    );
  }

  static Widget _scrollableState(
    Widget child, {
    bool hasScrollBody = true,
  }) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: hasScrollBody,
          child: child,
        ),
      ],
    );
  }
}
