import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_lazy_segment_mixin.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_discover_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_empty_state.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/discover_group_card.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Groups tab content with My / Discover sub-tabs.
class ConnectGroupsTab extends ConsumerStatefulWidget {
  const ConnectGroupsTab({
    super.key,
    required this.myGroups,
    required this.myGroupsLoading,
    required this.onRefresh,
    this.isActive = true,
  });

  final List<GroupProfile> myGroups;
  final bool myGroupsLoading;
  final Future<void> Function() onRefresh;
  final bool isActive;

  @override
  ConsumerState<ConnectGroupsTab> createState() => _ConnectGroupsTabState();
}

class _ConnectGroupsTabState extends ConsumerState<ConnectGroupsTab>
    with ConnectLazyMyDiscoverTabMixin<ConnectGroupsTab> {
  @override
  bool readTabActive(ConnectGroupsTab widget) => widget.isActive;

  @override
  void loadActiveSegment() {
    if (!isTabActive || selectedSegment != 1) return;
    ref.read(discoverGroupsProvider.notifier).ensureLoaded();
  }

  List<GroupProfile> _discoverGroups(DiscoverGroupsState discoverState) {
    final joinedGroupIds = widget.myGroups.map((group) => group.id).toSet();
    return filterDiscoverGroups(
      discoverGroups: discoverState.groups,
      joinedGroupIds: joinedGroupIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch unconditionally so it stays alive across My/Discover segment
    // switches; only `loadActiveSegment()` decides when to actually fetch.
    final discoverState = ref.watch(discoverGroupsProvider);
    final discoverGroups = _discoverGroups(discoverState);

    return ConnectMyDiscoverTab(
      onSegmentChanged: handleSegmentChanged,
      onMyRefresh: widget.onRefresh,
      onDiscoverRefresh: widget.onRefresh,
      onDiscoverLoadMore:
          isTabActive && selectedSegment == 1
              ? () => ref.read(discoverGroupsProvider.notifier).loadMore()
              : null,
      myBuilder: (context, _, switchToDiscover) {
        return ConnectPaginatedListView(
          items: widget.myGroups,
          isLoading: widget.myGroupsLoading,
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
                group: widget.myGroups[index],
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
          emptyDiscoverMessage: context.l10n.connect_empty_discover_groups,
          separatorHeight: 12,
          leadingItemCount: 1,
          leadingItemBuilder:
              (context) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  context.l10n.connect_all_groups,
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
