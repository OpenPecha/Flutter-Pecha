import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_feed_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_event_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_lazy_segment_mixin.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_discover_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_empty_state.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_card.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feed tab content with My / Discover sub-tabs.
class ConnectFeedTab extends ConsumerStatefulWidget {
  const ConnectFeedTab({
    super.key,
    required this.myGroups,
    this.isActive = true,
  });

  final List<GroupProfile> myGroups;
  final bool isActive;

  @override
  ConsumerState<ConnectFeedTab> createState() => _ConnectFeedTabState();
}

class _ConnectFeedTabState extends ConsumerState<ConnectFeedTab>
    with ConnectLazyMyDiscoverTabMixin<ConnectFeedTab> {
  Map<String, String> get _groupNames => {
    for (final group in widget.myGroups) group.id: group.title,
  };

  String _locationForGroup(GroupProfile group, BuildContext context) {
    if (group.tags.isNotEmpty) return group.tags.first;
    final subtitle = group.subTitle?.trim();
    if (subtitle != null && subtitle.isNotEmpty) return subtitle;
    return context.l10n.connect_online;
  }

  Map<String, String> _groupLocations(BuildContext context) => {
    for (final group in widget.myGroups)
      group.id: _locationForGroup(group, context),
  };

  @override
  bool readTabActive(ConnectFeedTab widget) => widget.isActive;

  @override
  void loadActiveSegment() {
    if (!isTabActive) return;
    if (selectedSegment == 0) {
      ref.read(myConnectFeedProvider.notifier).ensureLoaded();
    } else {
      ref.read(discoverConnectFeedProvider.notifier).ensureLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch both providers unconditionally so they stay alive across
    // My/Discover segment switches; only `loadActiveSegment()` decides
    // when to actually fetch.
    final myState = ref.watch(myConnectFeedProvider);
    final discoverState = ref.watch(discoverConnectFeedProvider);
    final groupLocations = _groupLocations(context);

    return ConnectMyDiscoverTab(
      onSegmentChanged: handleSegmentChanged,
      onMyRefresh: () => ref.read(myConnectFeedProvider.notifier).refresh(),
      onDiscoverRefresh:
          () => ref.read(discoverConnectFeedProvider.notifier).refresh(),
      onMyLoadMore: () => ref.read(myConnectFeedProvider.notifier).loadMore(),
      onDiscoverLoadMore:
          () => ref.read(discoverConnectFeedProvider.notifier).loadMore(),
      myBuilder: (context, scrollController, switchToDiscover) {
        return ConnectPaginatedListView(
          items: myState.items,
          isLoading: myState.isLoading,
          isLoadingMore: myState.isLoadingMore,
          error: myState.error,
          hasMore: myState.hasMore,
          scrollController: scrollController,
          onRetry: () => ref.read(myConnectFeedProvider.notifier).retry(),
          myEmptyState: ConnectMyEmptyState(
            type: ConnectMyEmptyStateType.feed,
            onBrowseTap: switchToDiscover,
          ),
          itemBuilder:
              (context, index) => _buildFeedItem(
                context,
                myState.items[index],
                includeUnfollowed: false,
                groupLocations: groupLocations,
              ),
        );
      },
      discoverBuilder: (context, scrollController, _) {
        return ConnectPaginatedListView(
          items: discoverState.items,
          isLoading: discoverState.isLoading,
          isLoadingMore: discoverState.isLoadingMore,
          error: discoverState.error,
          hasMore: discoverState.hasMore,
          scrollController: scrollController,
          onRetry: () => ref.read(discoverConnectFeedProvider.notifier).retry(),
          emptyDiscoverMessage: context.l10n.connect_empty_discover_feed,
          itemBuilder:
              (context, index) => _buildFeedItem(
                context,
                discoverState.items[index],
                includeUnfollowed: true,
                groupLocations: groupLocations,
              ),
        );
      },
    );
  }

  Widget _buildFeedItem(
    BuildContext context,
    ConnectFeedItem item, {
    required bool includeUnfollowed,
    required Map<String, String> groupLocations,
  }) {
    final groupNames = {
      ..._groupNames,
      if (item.groupName.isNotEmpty) item.groupId: item.groupName,
    };

    if (item.type == ConnectFeedItemType.post && item.post != null) {
      return ConnectPostCard(
        post: item.post!,
        includeUnfollowed: includeUnfollowed,
        syncFeedProvider: true,
      );
    }

    if (item.type == ConnectFeedItemType.event && item.event != null) {
      return ConnectEventCard(
        event: item.event!,
        groupNames: groupNames,
        groupLocations: groupLocations,
      );
    }

    return const SizedBox.shrink();
  }
}
