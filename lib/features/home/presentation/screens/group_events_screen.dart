import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_events_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_event_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_segmented_control.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupEventsScreen extends ConsumerStatefulWidget {
  const GroupEventsScreen({super.key});

  @override
  ConsumerState<GroupEventsScreen> createState() => _GroupEventsScreenState();
}

class _GroupEventsScreenState extends ConsumerState<GroupEventsScreen> {
  static const _paginationThreshold = 200.0;

  int _selectedFilterIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myConnectEventsProvider.notifier).ensureLoaded();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - _paginationThreshold) {
      return;
    }
    ref.read(myConnectEventsProvider.notifier).loadMore();
  }

  ConnectEventLocationFilter get _selectedFilter =>
      ConnectEventLocationFilter.values[_selectedFilterIndex];

  String? _emptyMessage(BuildContext context) {
    final l10n = context.l10n;
    return switch (_selectedFilter) {
      ConnectEventLocationFilter.all => null,
      ConnectEventLocationFilter.online => l10n.connect_events_filter_empty_online,
      ConnectEventLocationFilter.inPerson =>
        l10n.connect_events_filter_empty_in_person,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(myConnectEventsProvider);
    final filteredEvents = filterGroupEventsByLocation(
      state.events,
      _selectedFilter,
    );

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(l10n.home_group_events),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(AppAssets.arrowLeft),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: ConnectSegmentedControl(
              segments: [
                l10n.connect_events_filter_all,
                l10n.connect_online,
                l10n.connect_events_filter_in_person,
              ],
              selectedIndex: _selectedFilterIndex,
              onChanged: (index) {
                if (_selectedFilterIndex == index) return;
                setState(() => _selectedFilterIndex = index);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(myConnectEventsProvider.notifier).refresh(),
              child: ConnectPaginatedListView<GroupEvent>(
                items: filteredEvents,
                isLoading: state.isLoading,
                isLoadingMore: state.isLoadingMore,
                error: state.error,
                hasMore: state.hasMore,
                hasLoaded: state.hasLoaded,
                scrollController: _scrollController,
                onRetry: () => ref.read(myConnectEventsProvider.notifier).retry(),
                emptyDiscoverMessage: _emptyMessage(context),
                myEmptyState:
                    _selectedFilter == ConnectEventLocationFilter.all
                        ? _GroupEventsEmptyState()
                        : null,
                itemBuilder:
                    (context, index) =>
                        ConnectEventCard(event: filteredEvents[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupEventsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.connect_my_empty_events_title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: titleColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.connect_my_empty_events_subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: subtitleColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
