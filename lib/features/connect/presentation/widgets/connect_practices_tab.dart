import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_practices_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_lazy_segment_mixin.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_discover_tab_gate.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_empty_state.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_practice_card.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Practices tab content with My / Discover sub-tabs.
class ConnectPracticesTab extends ConsumerStatefulWidget {
  const ConnectPracticesTab({super.key, this.isActive = true});

  final bool isActive;

  @override
  ConsumerState<ConnectPracticesTab> createState() =>
      _ConnectPracticesTabState();
}

class _ConnectPracticesTabState extends ConsumerState<ConnectPracticesTab>
    with ConnectLazyMyDiscoverTabMixin<ConnectPracticesTab> {
  @override
  bool readTabActive(ConnectPracticesTab widget) => widget.isActive;

  @override
  void loadActiveSegment() {
    if (!isTabActive) return;
    if (selectedSegment == 0) {
      ref.read(myConnectPracticesProvider.notifier).ensureLoaded();
    } else {
      ref.read(discoverConnectPracticesProvider.notifier).ensureLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myState = ref.watch(myConnectPracticesProvider);
    final discoverState = ref.watch(discoverConnectPracticesProvider);

    return ConnectMyDiscoverTabGate(
      myHasLoaded: myState.hasLoaded,
      myIsEmpty: myState.practices.isEmpty,
      myHasError: myState.error != null,
      onSegmentChanged: handleSegmentChanged,
      onMyRefresh: () => ref.read(myConnectPracticesProvider.notifier).refresh(),
      onDiscoverRefresh:
          () => ref.read(discoverConnectPracticesProvider.notifier).refresh(),
      onMyLoadMore: () => ref.read(myConnectPracticesProvider.notifier).loadMore(),
      onDiscoverLoadMore:
          () => ref.read(discoverConnectPracticesProvider.notifier).loadMore(),
      myBuilder: (context, switchToDiscover, scrollHeader) {
        return ConnectPaginatedListView<GroupPractice>(
          scrollViewKey: const PageStorageKey<String>('connect_practices_my'),
          header: scrollHeader,
          items: myState.practices,
          isLoading: myState.isLoading,
          isLoadingMore: myState.isLoadingMore,
          error: myState.error,
          hasMore: myState.hasMore,
          hasLoaded: myState.hasLoaded,
          onRetry: () => ref.read(myConnectPracticesProvider.notifier).retry(),
          myEmptyState: ConnectMyEmptyState(
            type: ConnectMyEmptyStateType.practices,
            onBrowseTap: switchToDiscover,
          ),
          itemBuilder:
              (context, index) =>
                  ConnectPracticeCard(practice: myState.practices[index]),
        );
      },
      discoverBuilder: (context, _, scrollHeader) {
        return ConnectPaginatedListView<GroupPractice>(
          scrollViewKey: const PageStorageKey<String>('connect_practices_discover'),
          header: scrollHeader,
          items: discoverState.practices,
          isLoading: discoverState.isLoading,
          isLoadingMore: discoverState.isLoadingMore,
          error: discoverState.error,
          hasMore: discoverState.hasMore,
          hasLoaded: discoverState.hasLoaded,
          onRetry:
              () => ref.read(discoverConnectPracticesProvider.notifier).retry(),
          emptyDiscoverMessage: context.l10n.connect_empty_discover_practices,
          itemBuilder:
              (context, index) => ConnectPracticeCard(
                practice: discoverState.practices[index],
              ),
        );
      },
    );
  }
}
