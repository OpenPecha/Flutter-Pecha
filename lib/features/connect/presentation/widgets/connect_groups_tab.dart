import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/discover_group_card.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Groups tab content showing discover groups.
class ConnectGroupsTab extends ConsumerStatefulWidget {
  const ConnectGroupsTab({
    super.key,
    required this.myGroups,
    required this.onRefresh,
    this.isActive = true,
  });

  final List<GroupProfile> myGroups;
  final Future<void> Function() onRefresh;
  final bool isActive;

  @override
  ConsumerState<ConnectGroupsTab> createState() => _ConnectGroupsTabState();
}

class _ConnectGroupsTabState extends ConsumerState<ConnectGroupsTab> {
  static const _paginationThreshold = 200.0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.isActive) {
      _scheduleLoad();
    }
  }

  @override
  void didUpdateWidget(covariant ConnectGroupsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _scheduleLoad();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isActive) return;
      ref.read(discoverGroupsProvider.notifier).ensureLoaded();
    });
  }

  void _onScroll() {
    if (!widget.isActive || !_scrollController.hasClients) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - _paginationThreshold) {
      return;
    }
    ref.read(discoverGroupsProvider.notifier).loadMore();
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
    final discoverState = ref.watch(discoverGroupsProvider);
    final discoverGroups = _discoverGroups(discoverState);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ConnectPaginatedListView(
        items: discoverGroups,
        isLoading: discoverState.isLoading,
        isLoadingMore: discoverState.isLoadingMore,
        error: discoverState.error,
        hasMore: discoverState.hasMore,
        hasLoaded: discoverState.hasLoaded,
        scrollController: _scrollController,
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
      ),
    );
  }
}
