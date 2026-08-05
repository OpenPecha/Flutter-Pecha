import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/group_search_screen.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_groups_tab.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.refresh(myGroupsProvider.future),
      ref.read(discoverGroupsProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverGroupsProvider);
    final myGroupsAsync = ref.watch(myGroupsProvider);
    final pendingGroups = ref.watch(pendingJoinedGroupsProvider);
    final pendingUnjoinedIds = ref.watch(pendingUnjoinedGroupIdsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final apiGroups = myGroupsAsync.valueOrNull?.groups ?? const [];
    final displayedMyGroups = mergeMyGroupsWithPending(
      apiGroups: apiGroups,
      pendingGroups: pendingGroups,
      pendingUnjoinedIds: pendingUnjoinedIds,
    );
    final joinedGroupIds = displayedMyGroups.map((group) => group.id).toSet();
    final displayedDiscoverGroups = filterDiscoverGroups(
      discoverGroups: discoverState.groups,
      joinedGroupIds: joinedGroupIds,
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
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                ConnectGroupsTab(
                  myGroups: displayedMyGroups,
                  discoverGroups: displayedDiscoverGroups,
                  discoverState: discoverState,
                  myGroupsLoading: myGroupsLoading,
                  onRefresh: _onRefresh,
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
        tabs: const [
          Tab(text: 'Feed'),
          Tab(text: 'Events'),
          Tab(text: 'Posts'),
          Tab(text: 'Groups'),
        ],
      ),
    );
  }
}
