import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_events_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_event_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_empty_state.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_segmented_control.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Events tab content with My / Discover sub-tabs.
class ConnectEventsTab extends ConsumerStatefulWidget {
  const ConnectEventsTab({
    super.key,
    required this.myGroups,
    required this.onRefresh,
  });

  final List<GroupProfile> myGroups;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<ConnectEventsTab> createState() => _ConnectEventsTabState();
}

class _ConnectEventsTabState extends ConsumerState<ConnectEventsTab> {
  int _selectedSegment = 0;
  final ScrollController _myScrollController = ScrollController();
  final ScrollController _discoverScrollController = ScrollController();

  Map<String, String> get _groupNames => {
    for (final group in widget.myGroups) group.id: group.title,
  };

  Map<String, String> get _groupLocations => {
    for (final group in widget.myGroups) group.id: _locationForGroup(group),
  };

  @override
  void initState() {
    super.initState();
    _myScrollController.addListener(_onMyScroll);
    _discoverScrollController.addListener(_onDiscoverScroll);
  }

  @override
  void dispose() {
    _myScrollController.removeListener(_onMyScroll);
    _discoverScrollController.removeListener(_onDiscoverScroll);
    _myScrollController.dispose();
    _discoverScrollController.dispose();
    super.dispose();
  }

  void _onMyScroll() => _onScroll(_myScrollController, myConnectEventsProvider);

  void _onDiscoverScroll() =>
      _onScroll(_discoverScrollController, discoverConnectEventsProvider);

  void _onScroll(
    ScrollController controller,
    StateNotifierProvider<ConnectEventsNotifier, ConnectEventsState> provider,
  ) {
    if (!controller.hasClients) return;
    if (controller.position.pixels <
        controller.position.maxScrollExtent - 200) {
      return;
    }
    ref.read(provider.notifier).loadMore();
  }

  String _locationForGroup(GroupProfile group) {
    if (group.tags.isNotEmpty) return group.tags.first;
    final subtitle = group.subTitle?.trim();
    if (subtitle != null && subtitle.isNotEmpty) return subtitle;
    return 'Online';
  }

  @override
  Widget build(BuildContext context) {
    final myState = ref.watch(myConnectEventsProvider);
    final discoverState = ref.watch(discoverConnectEventsProvider);

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
          child: IndexedStack(
            index: _selectedSegment,
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await widget.onRefresh();
                  await ref.read(myConnectEventsProvider.notifier).refresh();
                },
                child: _buildEventsList(
                  context,
                  myState,
                  scrollController: _myScrollController,
                  isMySegment: true,
                  onRetry: () => ref.read(myConnectEventsProvider.notifier).retry(),
                  onBrowseDiscover: () => setState(() => _selectedSegment = 1),
                ),
              ),
              RefreshIndicator(
                onRefresh: () async {
                  await widget.onRefresh();
                  await ref
                      .read(discoverConnectEventsProvider.notifier)
                      .refresh();
                },
                child: _buildEventsList(
                  context,
                  discoverState,
                  scrollController: _discoverScrollController,
                  isMySegment: false,
                  onRetry:
                      () =>
                          ref.read(discoverConnectEventsProvider.notifier).retry(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList(
    BuildContext context,
    ConnectEventsState eventsState, {
    required ScrollController scrollController,
    required bool isMySegment,
    required VoidCallback onRetry,
    VoidCallback? onBrowseDiscover,
  }) {
    if (eventsState.isLoading && eventsState.events.isEmpty) {
      return const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (eventsState.error != null && eventsState.events.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: ErrorStateWidget(
              error: eventsState.error!,
              onRetry: onRetry,
            ),
          ),
        ],
      );
    }

    if (eventsState.events.isEmpty && !eventsState.isLoading) {
      if (isMySegment && onBrowseDiscover != null) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: ConnectMyEmptyState(
                type: ConnectMyEmptyStateType.events,
                onBrowseTap: onBrowseDiscover,
              ),
            ),
          ],
        );
      }

      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No events to discover',
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
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: eventsState.events.length + (eventsState.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == eventsState.events.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child:
                  eventsState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        final event = eventsState.events[index];
        return ConnectEventCard(
          event: event,
          groupNames: _groupNames,
          groupLocations: _groupLocations,
        );
      },
    );
  }
}
