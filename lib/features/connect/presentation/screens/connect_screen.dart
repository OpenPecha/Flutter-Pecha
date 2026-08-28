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
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_practices_tab.dart';
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
    _tabController = TabController(length: 5, vsync: this);
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
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: FollowedGroupsRow(
                  groups: displayedMyGroups,
                  isLoading: myGroupsLoading,
                ),
              ),
              SliverToBoxAdapter(
                child: _ConnectMainTabBar(
                  controller: _tabController,
                  isDark: isDark,
                ),
              ),
            ],
        body: TabBarView(
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
            ConnectPracticesTab(isActive: activeTabIndex == 3),
            ConnectGroupsTab(
              myGroups: displayedMyGroups,
              onRefresh: _onGroupsRefresh,
              isActive: activeTabIndex == 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectMainTabBar extends StatelessWidget {
  const _ConnectMainTabBar({required this.controller, required this.isDark});

  final TabController controller;
  final bool isDark;

  static const _tabCount = 5;
  static const _labelStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
  static const _labelPadding = EdgeInsets.symmetric(horizontal: 4);

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final unselectedColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final labels = [
      context.l10n.connect_tab_feed,
      context.l10n.connect_tab_events,
      context.l10n.connect_tab_posts,
      context.l10n.connect_tab_practices,
      context.l10n.connect_tab_groups,
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScaler = MediaQuery.textScalerOf(context);
          final textDirection = Directionality.of(context);
          final slotWidth = constraints.maxWidth / _tabCount;
          final horizontalPadding = _labelPadding.horizontal;
          final needsScroll = labels.any(
            (label) =>
                _measureLabelWidth(label, textScaler, textDirection) +
                    horizontalPadding >
                slotWidth,
          );

          return TabBar(
            controller: controller,
            isScrollable: needsScroll,
            tabAlignment:
                needsScroll ? TabAlignment.start : TabAlignment.fill,
            labelColor: labelColor,
            unselectedLabelColor: unselectedColor,
            indicatorColor: labelColor,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelPadding: _labelPadding,
            labelStyle: _labelStyle,
            unselectedLabelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            tabs: [for (final label in labels) Tab(text: label)],
          );
        },
      ),
    );
  }

  static double _measureLabelWidth(
    String text,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _labelStyle),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}
