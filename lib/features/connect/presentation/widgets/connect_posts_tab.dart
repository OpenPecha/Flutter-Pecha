import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_posts_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_lazy_segment_mixin.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_discover_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_empty_state.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Posts tab content with My / Discover sub-tabs.
class ConnectPostsTab extends ConsumerStatefulWidget {
  const ConnectPostsTab({
    super.key,
    this.isActive = true,
  });

  final bool isActive;

  @override
  ConsumerState<ConnectPostsTab> createState() => _ConnectPostsTabState();
}

class _ConnectPostsTabState extends ConsumerState<ConnectPostsTab>
    with ConnectLazyMyDiscoverTabMixin<ConnectPostsTab> {
  @override
  bool readTabActive(ConnectPostsTab widget) => widget.isActive;

  @override
  void loadActiveSegment() {
    if (!isTabActive) return;
    if (selectedSegment == 0) {
      ref.read(myConnectPostsProvider.notifier).ensureLoaded();
    } else {
      ref.read(discoverConnectPostsProvider.notifier).ensureLoaded();
    }
  }

  ConnectPostsState _myState() {
    if (!isTabActive || selectedSegment != 0) {
      return const ConnectPostsState();
    }
    return ref.watch(myConnectPostsProvider);
  }

  ConnectPostsState _discoverState() {
    if (!isTabActive || selectedSegment != 1) {
      return const ConnectPostsState();
    }
    return ref.watch(discoverConnectPostsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final myState = _myState();
    final discoverState = _discoverState();

    return ConnectMyDiscoverTab(
      onSegmentChanged: handleSegmentChanged,
      onMyRefresh: () => ref.read(myConnectPostsProvider.notifier).refresh(),
      onDiscoverRefresh:
          () => ref.read(discoverConnectPostsProvider.notifier).refresh(),
      onMyLoadMore: () => ref.read(myConnectPostsProvider.notifier).loadMore(),
      onDiscoverLoadMore:
          () => ref.read(discoverConnectPostsProvider.notifier).loadMore(),
      myBuilder: (context, scrollController, switchToDiscover) {
        return ConnectPaginatedListView(
          items: myState.posts,
          isLoading: myState.isLoading,
          isLoadingMore: myState.isLoadingMore,
          error: myState.error,
          hasMore: myState.hasMore,
          scrollController: scrollController,
          onRetry: () => ref.read(myConnectPostsProvider.notifier).retry(),
          myEmptyState: ConnectMyEmptyState(
            type: ConnectMyEmptyStateType.posts,
            onBrowseTap: switchToDiscover,
          ),
          itemBuilder:
              (context, index) => ConnectPostCard(
                post: myState.posts[index],
                includeUnfollowed: false,
              ),
        );
      },
      discoverBuilder: (context, scrollController, _) {
        return ConnectPaginatedListView(
          items: discoverState.posts,
          isLoading: discoverState.isLoading,
          isLoadingMore: discoverState.isLoadingMore,
          error: discoverState.error,
          hasMore: discoverState.hasMore,
          scrollController: scrollController,
          onRetry:
              () => ref.read(discoverConnectPostsProvider.notifier).retry(),
          emptyDiscoverMessage: 'No posts to discover',
          itemBuilder:
              (context, index) => ConnectPostCard(
                post: discoverState.posts[index],
                includeUnfollowed: true,
              ),
        );
      },
    );
  }
}
