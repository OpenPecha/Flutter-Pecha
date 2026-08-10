import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_hero_card.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_session_complete_sheet.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class GroupAccumulatorScreen extends ConsumerStatefulWidget {
  final String accumulatorId;
  final String? groupTitle;

  const GroupAccumulatorScreen({
    super.key,
    required this.accumulatorId,
    this.groupTitle,
  });

  @override
  ConsumerState<GroupAccumulatorScreen> createState() =>
      _GroupAccumulatorScreenState();
}

class _GroupAccumulatorScreenState extends ConsumerState<GroupAccumulatorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      groupAccumulatorDetailProvider(widget.accumulatorId),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(groupAccumulatorDetailProvider(widget.accumulatorId), (
      previous,
      next,
    ) {
      next.whenData((either) {
        either.fold((_) {}, (detail) {
          final cacheNotifier = ref.read(
            groupAccumulatorJoinCacheProvider(detail.groupId).notifier,
          );
          if (detail.isJoined == true) {
            cacheNotifier.markJoined(detail.id);
          } else if (detail.isJoined == false) {
            cacheNotifier.markUnjoined(detail.id);
          }
        });
      });
    });

    final resolvedDetail = detailAsync.whenOrNull(
      data: (either) => either.fold((_) => null, (detail) => detail),
    );
    if (resolvedDetail != null) {
      ref.listen(
        groupFollowProvider(
          GroupFollowKey(
            groupId: resolvedDetail.groupId,
            groupType: _resolveGroupType(ref, resolvedDetail.groupId),
          ),
        ),
        (previous, next) {
          if (next case GroupFollowSuccess(isFollowing: false)) {
            ref
                .read(
                  groupAccumulatorJoinCacheProvider(
                    resolvedDetail.groupId,
                  ).notifier,
                )
                .clear();
            ref.invalidate(
              groupAccumulatorDetailProvider(widget.accumulatorId),
            );
            ref.invalidate(groupAccumulatorsProvider(resolvedDetail.groupId));
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context, resolvedDetail),
            Expanded(
              child: detailAsync.when(
                data:
                    (either) => either.fold(
                      (failure) => Center(
                        child: ErrorStateWidget(
                          error: failure,
                          onRetry:
                              () => ref.invalidate(
                                groupAccumulatorDetailProvider(
                                  widget.accumulatorId,
                                ),
                              ),
                        ),
                      ),
                      (detail) => _buildContent(context, detail, isDark),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Center(
                      child: ErrorStateWidget(
                        error: error,
                        onRetry:
                            () => ref.invalidate(
                              groupAccumulatorDetailProvider(
                                widget.accumulatorId,
                              ),
                            ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, GroupAccumulatorDetail? detail) {
    final title = widget.groupTitle?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              title != null && title.isNotEmpty ? title : '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (detail == null)
            const SizedBox(width: 48, height: 48)
          else
            IconButton(
              icon: const Icon(AppAssets.readerShare),
              onPressed: () => _onShareTap(detail),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    GroupAccumulatorDetail detail,
    bool isDark,
  ) {
    final localJoinedIds = ref.watch(
      groupAccumulatorJoinCacheProvider(detail.groupId),
    );
    final hasJoined = accumulatorHasJoined(
      detail,
      localJoinedIds: localJoinedIds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _AccumulatorHeroCard(
            detail: detail,
            hasJoined: hasJoined,
            isDark: isDark,
            isJoining: _isJoining,
            onJoinTap: () => _onJoinTap(detail),
            onReciteTap: () => _onReciteTap(context, detail),
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
          unselectedLabelColor:
              isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
          indicatorColor:
              isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
          indicatorWeight: 2,
          dividerHeight: 1,
          dividerColor: isDark ? AppColors.cardBorderDark : AppColors.grey300,
          tabs: [
            Tab(text: context.l10n.group_accumulator_leaderboard),
            Tab(text: context.l10n.group_accumulator_my_contributions),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LeaderboardTab(
                accumulatorId: widget.accumulatorId,
                isDark: isDark,
              ),
              _MyContributionsTab(detail: detail, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onJoinTap(GroupAccumulatorDetail detail) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _isJoining = true);
    final ok = await joinGroupAccumulator(
      ref: ref,
      accumulatorId: detail.id,
      groupId: detail.groupId,
    );

    if (!mounted) return;
    setState(() {
      _isJoining = false;
      if (ok) {
        ref
            .read(groupAccumulatorJoinCacheProvider(detail.groupId).notifier)
            .markJoined(detail.id);
      }
    });

    if (ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.group_accumulator_join_error),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _onReciteTap(
    BuildContext context,
    GroupAccumulatorDetail detail,
  ) async {
    if (!detail.hasTextContent) {
      final presetId = detail.presetAccumulatorId;
      if (presetId.isEmpty) return;
      await context.push(
        '/mala',
        extra: {'presetId': presetId, 'groupAccumulatorId': detail.id},
      );
      if (!context.mounted) return;
      await _refreshAfterPractice(detail);
      return;
    }

    final textId = detail.textId;
    if (textId == null || textId.isEmpty) return;

    final sessionCount = await context.push<int>(
      '/reader/$textId',
      extra: NavigationContext(
        source: NavigationSource.groupAccumulatorChant,
        groupAccumulatorId: detail.id,
        presetAccumulatorId: detail.presetAccumulatorId,
        groupId: detail.groupId,
        groupTitle:
            _resolveGroupName(detail.groupId)?.trim().isNotEmpty == true
                ? _resolveGroupName(detail.groupId)!.trim()
                : null,
        groupAccumulatorSessionCount: detail.user?.totalCount ?? 0,
      ),
    );

    if (!context.mounted) return;

    await _refreshAfterPractice(detail);

    if (sessionCount == null) return;

    showGroupAccumulatorSessionCompleteSheet(
      context,
      sessionCount: sessionCount,
      accumulationTitle: detail.title,
      accumulatorId: detail.id,
      groupId: detail.groupId,
      groupName: _resolveGroupName(detail.groupId),
    );
  }

  Future<void> _refreshAfterPractice(GroupAccumulatorDetail detail) async {
    try {
      await ref.read(malaSyncManagerProvider).flush(SyncReason.screenLeave);
    } catch (_) {}

    refreshGroupAccumulatorData(
      ref,
      accumulatorId: detail.id,
      groupId: detail.groupId,
    );
  }

  Future<void> _onShareTap(GroupAccumulatorDetail detail) async {
    final groupName = _resolveGroupName(detail.groupId);
    final shareMessage =
        groupName == null
            ? context.l10n.group_accumulator_share_message_no_group(
              detail.title,
            )
            : context.l10n.group_accumulator_share_message(
              detail.title,
              groupName,
            );
    final shareUrl =
        DeepLinkUrlBuilder.groupAccumulatorLink(
          accumulatorId: detail.id,
          groupId: detail.groupId,
        ).toString();
    final sharePositionOrigin = getSharePositionOrigin(context: context);

    await SharePlus.instance.share(
      ShareParams(
        text: '$shareMessage\n\n$shareUrl',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// The group title normally arrives via the route extra; when the screen is
  /// opened from a deep link it is absent, so fall back to the cached group
  /// profile if it has already loaded.
  String? _resolveGroupName(String groupId) {
    final title = widget.groupTitle?.trim();
    if (title != null && title.isNotEmpty) return title;
    return ref
        .read(groupProfileProvider(groupId))
        .whenOrNull(
          data:
              (either) => either.fold((_) => null, (profile) => profile.title),
        );
  }
}

GroupType _resolveGroupType(WidgetRef ref, String groupId) {
  final profileAsync = ref.read(groupProfileProvider(groupId));
  return profileAsync.maybeWhen(
    data:
        (either) => either.fold(
          (_) => GroupType.community,
          (profile) => profile.groupType,
        ),
    orElse: () => GroupType.community,
  );
}

class _MyContributionsTab extends StatefulWidget {
  final GroupAccumulatorDetail detail;
  final bool isDark;

  const _MyContributionsTab({required this.detail, required this.isDark});

  @override
  State<_MyContributionsTab> createState() => _MyContributionsTabState();
}

class _MyContributionsTabState extends State<_MyContributionsTab> {
  GroupAccumulatorMemberSort _sort = GroupAccumulatorMemberSort.total;

  @override
  Widget build(BuildContext context) {
    final user = widget.detail.user;
    final secondaryColor =
        widget.isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final numberFormat = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    );

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            context.l10n.group_accumulator_contributions_empty,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: secondaryColor),
          ),
        ),
      );
    }

    final count =
        _sort == GroupAccumulatorMemberSort.today
            ? user.todayCount
            : user.totalCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Text(
              context.l10n.group_accumulator_recited,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color:
                    widget.isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            _SortToggle(
              sort: _sort,
              isDark: widget.isDark,
              onChanged: (sort) => setState(() => _sort = sort),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _MemberAvatar(avatarUrl: user.imageUrl, isDark: widget.isDark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      widget.isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              numberFormat.format(count),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    widget.isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccumulatorHeroCard extends StatelessWidget {
  final GroupAccumulatorDetail detail;
  final bool hasJoined;
  final bool isDark;
  final bool isJoining;
  final VoidCallback? onJoinTap;
  final VoidCallback? onReciteTap;

  const _AccumulatorHeroCard({
    required this.detail,
    required this.hasJoined,
    required this.isDark,
    this.isJoining = false,
    this.onJoinTap,
    this.onReciteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GroupAccumulatorHeroCard(
      detail: detail,
      hasJoined: hasJoined,
      isDark: isDark,
      isJoining: isJoining,
      onJoinTap: onJoinTap,
      onActionTap: hasJoined ? onReciteTap : null,
    );
  }
}

class _LeaderboardTab extends ConsumerStatefulWidget {
  final String accumulatorId;
  final bool isDark;

  const _LeaderboardTab({required this.accumulatorId, required this.isDark});

  @override
  ConsumerState<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<_LeaderboardTab> {
  final ScrollController _scrollController = ScrollController();
  bool _hasRequestedInitialLoad = false;
  GroupAccumulatorMemberSort _sort = GroupAccumulatorMemberSort.total;

  GroupAccumulatorMembersKey get _membersKey => GroupAccumulatorMembersKey(
    accumulatorId: widget.accumulatorId,
    sortBy: _sort,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialIfNeeded();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialIfNeeded({bool force = false}) {
    if (_hasRequestedInitialLoad && !force) return;
    _hasRequestedInitialLoad = true;
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(groupAccumulatorMembersProvider(_membersKey).notifier)
          .loadInitial(force: force);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(groupAccumulatorMembersProvider(_membersKey).notifier)
          .loadMore();
    }
  }

  void _onSortChanged(GroupAccumulatorMemberSort sort) {
    if (_sort == sort) return;
    setState(() => _sort = sort);
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(groupAccumulatorMembersProvider(_membersKey).notifier)
          .loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(
      groupAccumulatorMembersProvider(_membersKey),
    );
    final secondaryColor =
        widget.isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final numberFormat = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    );

    if ((membersState.isLoading || !membersState.hasLoadedOnce) &&
        membersState.members.isEmpty &&
        membersState.error == null) {
      if (!membersState.isLoading) {
        Future.microtask(() {
          if (!mounted) return;
          ref
              .read(groupAccumulatorMembersProvider(_membersKey).notifier)
              .loadInitial();
        });
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (membersState.error != null && membersState.members.isEmpty) {
      return Center(
        child: ErrorStateWidget(
          error: membersState.error!,
          onRetry:
              () =>
                  ref
                      .read(
                        groupAccumulatorMembersProvider(_membersKey).notifier,
                      )
                      .retry(),
        ),
      );
    }

    final sortedMembers =
        sortAccumulatorMembers(membersState.members, _sort).where((member) {
          final count =
              _sort == GroupAccumulatorMemberSort.today
                  ? member.todayCount
                  : member.totalCount;
          return count > 0;
        }).toList();

    final hasAnyPositive = membersState.members.any((member) {
      final count =
          _sort == GroupAccumulatorMemberSort.today
              ? member.todayCount
              : member.totalCount;
      return count > 0;
    });

    final showEmptyMessage =
        membersState.hasLoadedOnce &&
        !hasAnyPositive &&
        !membersState.isLoading &&
        !membersState.isLoadingMore &&
        membersState.error == null;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount:
          1 +
          (showEmptyMessage ? 1 : sortedMembers.length) +
          (membersState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text(
                  context.l10n.group_accumulator_recited,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        widget.isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _SortToggle(
                  sort: _sort,
                  isDark: widget.isDark,
                  onChanged: _onSortChanged,
                ),
              ],
            ),
          );
        }

        if (showEmptyMessage && index == 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.l10n.group_accumulator_leaderboard_empty,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: secondaryColor),
            ),
          );
        }

        final memberIndex = index - 1 - (showEmptyMessage ? 1 : 0);
        if (memberIndex < sortedMembers.length) {
          final member = sortedMembers[memberIndex];
          final count =
              _sort == GroupAccumulatorMemberSort.today
                  ? member.todayCount
                  : member.totalCount;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${memberIndex + 1}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _MemberAvatar(
                  avatarUrl: member.avatarUrl,
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          widget.isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  numberFormat.format(count),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        widget.isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _SortToggle extends StatelessWidget {
  final GroupAccumulatorMemberSort sort;
  final bool isDark;
  final ValueChanged<GroupAccumulatorMemberSort> onChanged;

  const _SortToggle({
    required this.sort,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SortToggleChip(
            label: context.l10n.home_today,
            isSelected: sort == GroupAccumulatorMemberSort.today,
            isDark: isDark,
            onTap: () => onChanged(GroupAccumulatorMemberSort.today),
          ),
          _SortToggleChip(
            label: context.l10n.group_accumulator_total,
            isSelected: sort == GroupAccumulatorMemberSort.total,
            isDark: isDark,
            onTap: () => onChanged(GroupAccumulatorMemberSort.total),
          ),
        ],
      ),
    );
  }
}

class _SortToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SortToggleChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isDark ? AppColors.surfaceWhite : AppColors.textPrimary)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                isSelected
                    ? (isDark ? AppColors.textPrimary : AppColors.surfaceWhite)
                    : (isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String? avatarUrl;
  final bool isDark;

  const _MemberAvatar({required this.avatarUrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child:
            avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: _placeholder(),
                )
                : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.profile,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}
