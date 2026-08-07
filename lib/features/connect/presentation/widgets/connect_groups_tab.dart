import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_discover_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_empty_state.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/discover_group_card.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Groups tab content with My / Discover sub-tabs.
class ConnectGroupsTab extends ConsumerWidget {
  const ConnectGroupsTab({
    super.key,
    required this.myGroups,
    required this.discoverGroups,
    required this.discoverState,
    required this.myGroupsLoading,
    required this.onRefresh,
  });

  final List<GroupProfile> myGroups;
  final List<GroupProfile> discoverGroups;
  final DiscoverGroupsState discoverState;
  final bool myGroupsLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConnectMyDiscoverTab(
      onMyRefresh: onRefresh,
      onDiscoverRefresh: onRefresh,
      onDiscoverLoadMore:
          () => ref.read(discoverGroupsProvider.notifier).loadMore(),
      myBuilder: (context, _, switchToDiscover) {
        return ConnectPaginatedListView(
          items: myGroups,
          isLoading: myGroupsLoading,
          isLoadingMore: false,
          error: null,
          hasMore: false,
          onRetry: () {},
          separatorHeight: 12,
          myEmptyState: ConnectMyEmptyState(
            type: ConnectMyEmptyStateType.groups,
            onBrowseTap: switchToDiscover,
          ),
          itemBuilder:
              (context, index) => DiscoverGroupCard(
                group: myGroups[index],
                showOpenButton: true,
              ),
        );
      },
      discoverBuilder: (context, scrollController, _) {
        return ConnectPaginatedListView(
          items: discoverGroups,
          isLoading: discoverState.isLoading,
          isLoadingMore: discoverState.isLoadingMore,
          error: discoverState.error,
          hasMore: discoverState.hasMore,
          scrollController: scrollController,
          onRetry: () => ref.read(discoverGroupsProvider.notifier).retry(),
          emptyDiscoverMessage: 'No groups to discover',
          separatorHeight: 12,
          leadingItemCount: 1,
          leadingItemBuilder:
              (context) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'All groups',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: AppFontConfig.tibetanCompactLineHeight,
                  ),
                ),
              ),
          itemBuilder:
              (context, index) => DiscoverGroupCard(
                group: discoverGroups[index],
                showJoinButton: true,
              ),
        );
      },
    );
  }
}
