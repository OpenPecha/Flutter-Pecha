import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_empty_state.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_segmented_control.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/discover_group_card.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Groups tab content with My / Discover sub-tabs.
class ConnectGroupsTab extends ConsumerStatefulWidget {
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
  ConsumerState<ConnectGroupsTab> createState() => _ConnectGroupsTabState();
}

class _ConnectGroupsTabState extends ConsumerState<ConnectGroupsTab> {
  int _selectedSegment = 0;
  final ScrollController _discoverScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _discoverScrollController.addListener(_onDiscoverScroll);
  }

  @override
  void dispose() {
    _discoverScrollController.removeListener(_onDiscoverScroll);
    _discoverScrollController.dispose();
    super.dispose();
  }

  void _onDiscoverScroll() {
    if (_discoverScrollController.position.pixels >=
        _discoverScrollController.position.maxScrollExtent - 200) {
      ref.read(discoverGroupsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: ConnectSegmentedControl(
            segments: const ['My', 'Discover'],
            selectedIndex: _selectedSegment,
            onChanged: (index) => setState(() => _selectedSegment = index),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child:
                _selectedSegment == 0
                    ? _buildMyGroupsList(context)
                    : _buildDiscoverGroupsList(context),
          ),
        ),
      ],
    );
  }

  Widget _buildMyGroupsList(BuildContext context) {
    if (widget.myGroupsLoading && widget.myGroups.isEmpty) {
      return const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (widget.myGroups.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ConnectMyEmptyState(
              type: ConnectMyEmptyStateType.groups,
              onBrowseTap: () => setState(() => _selectedSegment = 1),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: widget.myGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return DiscoverGroupCard(
          group: widget.myGroups[index],
          showOpenButton: true,
        );
      },
    );
  }

  Widget _buildDiscoverGroupsList(BuildContext context) {
    final discoverState = widget.discoverState;
    final groups = widget.discoverGroups;

    if (discoverState.isLoading && groups.isEmpty) {
      return const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (discoverState.error != null && groups.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: ErrorStateWidget(
              error: discoverState.error!,
              onRetry: () => ref.read(discoverGroupsProvider.notifier).retry(),
            ),
          ),
        ],
      );
    }

    if (groups.isEmpty && !discoverState.isLoading) {
      return const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No groups to discover',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _discoverScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: groups.length + 1 + (discoverState.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'All groups',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                height: AppFontConfig.tibetanCompactLineHeight,
              ),
            ),
          );
        }

        final groupIndex = index - 1;
        if (groupIndex == groups.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child:
                  discoverState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        return DiscoverGroupCard(
          group: groups[groupIndex],
          showJoinButton: true,
        );
      },
    );
  }
}
