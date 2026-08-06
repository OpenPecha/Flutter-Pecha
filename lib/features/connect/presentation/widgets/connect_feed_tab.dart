import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_feed_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_event_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_segmented_control.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feed tab content with My / Discover sub-tabs.
class ConnectFeedTab extends ConsumerStatefulWidget {
  const ConnectFeedTab({
    super.key,
    required this.myGroups,
    required this.onRefresh,
  });

  final List<GroupProfile> myGroups;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<ConnectFeedTab> createState() => _ConnectFeedTabState();
}

class _ConnectFeedTabState extends ConsumerState<ConnectFeedTab> {
  int _selectedSegment = 0;
  final ScrollController _scrollController = ScrollController();

  Map<String, String> get _groupNames => {
    for (final group in widget.myGroups) group.id: group.title,
  };

  Map<String, String> get _groupLocations => {
    for (final group in widget.myGroups)
      group.id: _locationForGroup(group),
  };

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
        _scrollController.position.maxScrollExtent - 200) {
      final provider =
          _selectedSegment == 0
              ? myConnectFeedProvider
              : discoverConnectFeedProvider;
      ref.read(provider.notifier).loadMore();
    }
  }

  String _locationForGroup(GroupProfile group) {
    if (group.tags.isNotEmpty) return group.tags.first;
    final subtitle = group.subTitle?.trim();
    if (subtitle != null && subtitle.isNotEmpty) return subtitle;
    return 'Online';
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(
      _selectedSegment == 0
          ? myConnectFeedProvider
          : discoverConnectFeedProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: ConnectSegmentedControl(
            segments: const ['My', 'Discover'],
            selectedIndex: _selectedSegment,
            onChanged: (index) {
              setState(() => _selectedSegment = index);
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await widget.onRefresh();
              final provider =
                  _selectedSegment == 0
                      ? myConnectFeedProvider
                      : discoverConnectFeedProvider;
              await ref.read(provider.notifier).refresh();
            },
            child: _buildFeedList(context, feedState),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedList(BuildContext context, ConnectFeedState feedState) {
    if (feedState.isLoading && feedState.items.isEmpty) {
      return const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (feedState.error != null && feedState.items.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: ErrorStateWidget(
              error: feedState.error!,
              onRetry: () {
                final provider =
                    _selectedSegment == 0
                        ? myConnectFeedProvider
                        : discoverConnectFeedProvider;
                ref.read(provider.notifier).retry();
              },
            ),
          ),
        ],
      );
    }

    if (feedState.items.isEmpty && !feedState.isLoading) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Text(
                _selectedSegment == 0 ? 'No feed items yet' : 'Nothing to discover',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: feedState.items.length + (feedState.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == feedState.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child:
                  feedState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        final item = feedState.items[index];
        return _buildFeedItem(context, item);
      },
    );
  }

  Widget _buildFeedItem(BuildContext context, ConnectFeedItem item) {
    final includeUnfollowed = _selectedSegment == 1;
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
        groupLocations: _groupLocations,
      );
    }

    return const SizedBox.shrink();
  }
}
