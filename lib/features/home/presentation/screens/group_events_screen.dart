import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_events_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_event_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupEventsScreen extends ConsumerStatefulWidget {
  const GroupEventsScreen({super.key});

  @override
  ConsumerState<GroupEventsScreen> createState() => _GroupEventsScreenState();
}

class _GroupEventsScreenState extends ConsumerState<GroupEventsScreen>
    with SingleTickerProviderStateMixin {
  static const _paginationThreshold = 200.0;

  late TabController _tabController;
  late final List<ScrollController> _scrollControllers;
  late final List<VoidCallback> _scrollListeners;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollControllers = List.generate(3, (_) => ScrollController());
    _scrollListeners = List.generate(3, (index) => () => _onScroll(index));
    for (var i = 0; i < _scrollControllers.length; i++) {
      _scrollControllers[i].addListener(_scrollListeners[i]);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myConnectEventsProvider.notifier).ensureLoaded();
    });
  }

  @override
  void dispose() {
    for (var i = 0; i < _scrollControllers.length; i++) {
      _scrollControllers[i].removeListener(_scrollListeners[i]);
      _scrollControllers[i].dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll(int tabIndex) {
    final controller = _scrollControllers[tabIndex];
    if (!controller.hasClients) return;
    if (controller.position.pixels <
        controller.position.maxScrollExtent - _paginationThreshold) {
      return;
    }
    ref.read(myConnectEventsProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          _GroupEventsTabBar(controller: _tabController, isDark: isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (
                  var i = 0;
                  i < ConnectEventLocationFilter.values.length;
                  i++
                )
                  _GroupEventsTabContent(
                    filter: ConnectEventLocationFilter.values[i],
                    scrollController: _scrollControllers[i],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupEventsTabContent extends ConsumerWidget {
  const _GroupEventsTabContent({
    required this.filter,
    required this.scrollController,
  });

  final ConnectEventLocationFilter filter;
  final ScrollController scrollController;

  String? _emptyMessage(BuildContext context) {
    final l10n = context.l10n;
    return switch (filter) {
      ConnectEventLocationFilter.all => null,
      ConnectEventLocationFilter.online =>
        l10n.connect_events_filter_empty_online,
      ConnectEventLocationFilter.inPerson =>
        l10n.connect_events_filter_empty_in_person,
    };
  }

  bool _shouldAutoLoadMoreForFilter(
    ConnectEventsState state,
    List<GroupEvent> filteredEvents,
  ) {
    return filter != ConnectEventLocationFilter.all &&
        filteredEvents.isEmpty &&
        state.hasLoaded &&
        !state.isLoading &&
        !state.isLoadingMore &&
        state.hasMore &&
        state.error == null;
  }

  bool _isResolvingFilteredEmpty(
    ConnectEventsState state,
    List<GroupEvent> filteredEvents,
  ) {
    return filter != ConnectEventLocationFilter.all &&
        filteredEvents.isEmpty &&
        state.hasLoaded &&
        state.hasMore &&
        state.error == null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myConnectEventsProvider);
    final filteredEvents = filterGroupEventsByLocation(state.events, filter);

    if (_shouldAutoLoadMoreForFilter(state, filteredEvents)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(myConnectEventsProvider.notifier).loadMore();
      });
    }

    final isResolvingFilteredEmpty = _isResolvingFilteredEmpty(
      state,
      filteredEvents,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(myConnectEventsProvider.notifier).refresh(),
      child: ConnectPaginatedListView<GroupEvent>(
        items: filteredEvents,
        isLoading: state.isLoading || isResolvingFilteredEmpty,
        isLoadingMore: state.isLoadingMore,
        error: state.error,
        hasMore: state.hasMore,
        hasLoaded: state.hasLoaded,
        scrollController: scrollController,
        onRetry: () => ref.read(myConnectEventsProvider.notifier).retry(),
        emptyDiscoverMessage: _emptyMessage(context),
        myEmptyState:
            filter == ConnectEventLocationFilter.all
                ? _GroupEventsEmptyState()
                : null,
        itemBuilder:
            (context, index) => ConnectEventCard(event: filteredEvents[index]),
      ),
    );
  }
}

class _GroupEventsTabBar extends StatelessWidget {
  const _GroupEventsTabBar({required this.controller, required this.isDark});

  final TabController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final unselectedColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey300;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: TabBar(
        controller: controller,
        tabAlignment: TabAlignment.fill,
        labelColor: labelColor,
        unselectedLabelColor: unselectedColor,
        indicatorColor: labelColor,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(text: l10n.connect_events_filter_all),
          Tab(text: l10n.connect_online),
          Tab(text: l10n.connect_events_filter_in_person),
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
            style: TextStyle(fontSize: 15, color: subtitleColor, height: 1.5),
          ),
        ],
      ),
    );
  }
}
