import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/group_search_screen.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_events_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_groups_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_posts_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/followed_groups_row.dart';
import 'package:flutter_pecha/shared/widgets/main_tab_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _onGroupsRefresh() async {
    await Future.wait([
      ref.refresh(myGroupsProvider.future),
      ref.read(discoverGroupsProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final myGroupsAsync = ref.watch(myGroupsProvider);
    final pendingGroups = ref.watch(pendingJoinedGroupsProvider);
    final pendingUnjoinedIds = ref.watch(pendingUnjoinedGroupIdsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeTabIndex = _tabController.index;

    final apiGroups = myGroupsAsync.valueOrNull?.groups ?? const [];
    final displayedMyGroups = mergeMyGroupsWithPending(
      apiGroups: apiGroups,
      pendingGroups: pendingGroups,
      pendingUnjoinedIds: pendingUnjoinedIds,
    );
    final myGroupsLoading =
        myGroupsAsync.isLoading && displayedMyGroups.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: MainTabAppBar(
        title: context.l10n.nav_connect,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GroupSearchScreen(),
                ),
              );
            },
            icon: Icon(
              AppAssets.exploreUnselected,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: context.l10n.text_search,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FollowedGroupsRow(
            groups: displayedMyGroups,
            isLoading: myGroupsLoading,
          ),
          _ConnectMainTabBar(controller: _tabController, isDark: isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ConnectFeedTab(
                  myGroups: displayedMyGroups,
                  isActive: activeTabIndex == 0,
                ),
                ConnectEventsTab(
                  myGroups: displayedMyGroups,
                  isActive: activeTabIndex == 1,
                ),
                ConnectPostsTab(isActive: activeTabIndex == 2),
                ConnectGroupsTab(
                  myGroups: displayedMyGroups,
                  myGroupsLoading: myGroupsLoading,
                  onRefresh: _onGroupsRefresh,
                  isActive: activeTabIndex == 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectMainTabBar extends StatelessWidget {
  const _ConnectMainTabBar({
    required this.controller,
    required this.isDark,
  });

  final TabController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: labelColor,
        unselectedLabelColor: unselectedColor,
        indicatorColor: labelColor,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 20),
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(text: context.l10n.connect_tab_feed),
          Tab(text: context.l10n.connect_tab_events),
          Tab(text: context.l10n.connect_tab_posts),
          Tab(text: context.l10n.connect_tab_groups),
        ],
      ),
    );
  }
}
