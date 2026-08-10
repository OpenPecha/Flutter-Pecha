import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_events_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_event_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_lazy_segment_mixin.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_discover_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_empty_state.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Events tab content with My / Discover sub-tabs.
class ConnectEventsTab extends ConsumerStatefulWidget {
  const ConnectEventsTab({
    super.key,
    required this.myGroups,
    this.isActive = true,
  });

  final List<GroupProfile> myGroups;
  final bool isActive;

  @override
  ConsumerState<ConnectEventsTab> createState() => _ConnectEventsTabState();
}

class _ConnectEventsTabState extends ConsumerState<ConnectEventsTab>
    with ConnectLazyMyDiscoverTabMixin<ConnectEventsTab> {
  Map<String, String> get _groupNames => {
    for (final group in widget.myGroups) group.id: group.title,
  };

  Map<String, String> _groupLocations(BuildContext context) => {
    for (final group in widget.myGroups)
      group.id: _locationForGroup(group, context),
  };

  @override
  bool readTabActive(ConnectEventsTab widget) => widget.isActive;

  @override
  void loadActiveSegment() {
    if (!isTabActive) return;
    if (selectedSegment == 0) {
      ref.read(myConnectEventsProvider.notifier).ensureLoaded();
    } else {
      ref.read(discoverConnectEventsProvider.notifier).ensureLoaded();
    }
  }

  String _locationForGroup(GroupProfile group, BuildContext context) {
    if (group.tags.isNotEmpty) return group.tags.first;
    final subtitle = group.subTitle?.trim();
    if (subtitle != null && subtitle.isNotEmpty) return subtitle;
    return context.l10n.connect_online;
  }

  @override
  Widget build(BuildContext context) {
    // Watch both providers unconditionally so they stay alive across
    // My/Discover segment switches; only `loadActiveSegment()` decides
    // when to actually fetch.
    final myState = ref.watch(myConnectEventsProvider);
    final discoverState = ref.watch(discoverConnectEventsProvider);
    final groupLocations = _groupLocations(context);

    return ConnectMyDiscoverTab(
      onSegmentChanged: handleSegmentChanged,
      onMyRefresh: () => ref.read(myConnectEventsProvider.notifier).refresh(),
      onDiscoverRefresh:
          () => ref.read(discoverConnectEventsProvider.notifier).refresh(),
      onMyLoadMore: () => ref.read(myConnectEventsProvider.notifier).loadMore(),
      onDiscoverLoadMore:
          () => ref.read(discoverConnectEventsProvider.notifier).loadMore(),
      myBuilder: (context, scrollController, switchToDiscover) {
        return ConnectPaginatedListView(
          items: myState.events,
          isLoading: myState.isLoading,
          isLoadingMore: myState.isLoadingMore,
          error: myState.error,
          hasMore: myState.hasMore,
          scrollController: scrollController,
          onRetry: () => ref.read(myConnectEventsProvider.notifier).retry(),
          myEmptyState: ConnectMyEmptyState(
            type: ConnectMyEmptyStateType.events,
            onBrowseTap: switchToDiscover,
          ),
          itemBuilder:
              (context, index) => ConnectEventCard(
                event: myState.events[index],
                groupNames: _groupNames,
                groupLocations: groupLocations,
              ),
        );
      },
      discoverBuilder: (context, scrollController, _) {
        return ConnectPaginatedListView(
          items: discoverState.events,
          isLoading: discoverState.isLoading,
          isLoadingMore: discoverState.isLoadingMore,
          error: discoverState.error,
          hasMore: discoverState.hasMore,
          scrollController: scrollController,
          onRetry:
              () => ref.read(discoverConnectEventsProvider.notifier).retry(),
          emptyDiscoverMessage: context.l10n.connect_empty_discover_events,
          itemBuilder:
              (context, index) => ConnectEventCard(
                event: discoverState.events[index],
                groupNames: _groupNames,
                groupLocations: groupLocations,
              ),
        );
      },
    );
  }
}
