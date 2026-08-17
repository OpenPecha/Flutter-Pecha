import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_practices_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_card.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConnectPracticeCard extends ConsumerStatefulWidget {
  const ConnectPracticeCard({super.key, required this.practice});

  final GroupPractice practice;

  @override
  ConsumerState<ConnectPracticeCard> createState() =>
      _ConnectPracticeCardState();
}

class _ConnectPracticeCardState extends ConsumerState<ConnectPracticeCard> {
  bool _isEnrollingSeries = false;
  String? _joiningAccumulatorId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineHeight = theme.textTheme.bodyMedium?.height;
    final practice = widget.practice;

    return switch (practice.type) {
      GroupPracticeType.series when practice.series != null => _buildSeriesCard(
        practice,
        practice.series!,
        isDark,
        lineHeight,
      ),
      GroupPracticeType.accumulator when practice.accumulator != null =>
        _buildAccumulatorCard(
          practice,
          practice.accumulator!,
          isDark,
          lineHeight,
        ),
      GroupPracticeType.plan when practice.plan != null => _buildPlanCard(
        practice,
        practice.plan!,
        isDark,
        lineHeight,
      ),
      GroupPracticeType.collection when practice.collection != null =>
        _buildCollectionCard(
          practice,
          practice.collection!,
          isDark,
          lineHeight,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildSeriesCard(
    GroupPractice practice,
    GroupProfileSeries series,
    bool isDark,
    double? lineHeight,
  ) {
    final dateRange = PlanDateFormat.formatRangeOrNull(
      series.startDate,
      series.endDate,
    );
    final isEnrolled = practice.isJoined || series.isGroupEnrolled == true;
    final showPracticeOverlay = !isEnrolled;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            _isEnrollingSeries
                ? null
                : () => _navigateToSeriesDetail(practice, series, isEnrolled),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  series.image != null && !series.image!.isEmpty
                      ? ResponsiveCoverImage(
                        image: series.image,
                        fit: BoxFit.cover,
                      )
                      : ColoredBox(
                        color:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.grey100,
                        child: Icon(
                          AppAssets.bookOpenText,
                          size: 40,
                          color: isDark ? AppColors.grey500 : AppColors.grey600,
                        ),
                      ),
                  if (showPracticeOverlay)
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      alignment: Alignment.center,
                      child:
                          _isEnrollingSeries
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap:
                                    () =>
                                        _onPracticeWithUsTap(practice, series),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    context.l10n.group_practice_with_us,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: lineHeight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateRange != null ||
                      series.enrolledCount > 0 ||
                      _hasGroupLabel(practice)) ...[
                    const SizedBox(height: 4),
                    _ConnectPracticeMetaRow(
                      practice: practice,
                      isDark: isDark,
                      lineHeight: lineHeight,
                      dateText: dateRange,
                      joinCount: series.enrolledCount,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccumulatorCard(
    GroupPractice practice,
    GroupAccumulator accumulator,
    bool isDark,
    double? lineHeight,
  ) {
    final groupId = practice.groupId ?? accumulator.groupId;
    final localJoinedIds = ref.watch(
      groupAccumulatorJoinCacheProvider(groupId),
    );
    final hasJoined =
        practice.isJoined ||
        accumulatorHasJoined(accumulator, localJoinedIds: localJoinedIds);

    return GroupAccumulatorCard(
      accumulator: accumulator,
      hasJoined: hasJoined,
      isDark: isDark,
      lineHeight: lineHeight,
      isJoining: _joiningAccumulatorId == accumulator.id,
      groupName: practice.groupName,
      groupAvatarUrl: practice.groupAvatarUrl,
      groupId: practice.groupId,
      onTap: () => _navigateToAccumulatorDetail(accumulator.id, practice),
      onJoinTap: () => _onJoinAccumulatorTap(practice, accumulator),
    );
  }

  Widget _buildPlanCard(
    GroupPractice practice,
    GroupPracticePlan plan,
    bool isDark,
    double? lineHeight,
  ) {
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final dateRange = PlanDateFormat.formatRangeOrNull(plan.startDate, null);
    final details = [
      if (dateRange != null) dateRange,
      if (plan.totalDays > 0) context.l10n.days_count(plan.totalDays),
    ].join(' · ');

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToPlanDetail(practice, plan),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child:
                  plan.imageUrl != null && plan.imageUrl!.isNotEmpty
                      ? CachedNetworkImageWidget(
                        imageUrl: plan.imageUrl!,
                        fit: BoxFit.cover,
                      )
                      : ColoredBox(
                        color:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.grey100,
                        child: Icon(
                          AppAssets.bookOpenText,
                          size: 40,
                          color: isDark ? AppColors.grey500 : AppColors.grey600,
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: lineHeight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (details.isNotEmpty || _hasGroupLabel(practice)) ...[
                    const SizedBox(height: 4),
                    _ConnectPracticeMetaRow(
                      practice: practice,
                      isDark: isDark,
                      lineHeight: lineHeight,
                      dateText: details.isNotEmpty ? details : null,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard(
    GroupPractice practice,
    GroupRecitationCollection collection,
    bool isDark,
    double? lineHeight,
  ) {
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final itemCountLabel =
        collection.itemCount > 0
            ? context.l10n.home_recitation_count(collection.itemCount)
            : null;

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToCollectionDetail(practice, collection),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child:
                  collection.imageUrl != null && collection.imageUrl!.isNotEmpty
                      ? CachedNetworkImageWidget(
                        imageUrl: collection.imageUrl!,
                        fit: BoxFit.cover,
                      )
                      : ColoredBox(
                        color:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.grey100,
                        child: Icon(
                          AppAssets.bookOpenText,
                          size: 40,
                          color: isDark ? AppColors.grey500 : AppColors.grey600,
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: lineHeight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (itemCountLabel != null || _hasGroupLabel(practice)) ...[
                    const SizedBox(height: 4),
                    _ConnectPracticeMetaRow(
                      practice: practice,
                      isDark: isDark,
                      lineHeight: lineHeight,
                      dateText: itemCountLabel,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasGroupLabel(GroupPractice practice) {
    return practice.groupId != null &&
        (practice.groupName?.trim().isNotEmpty ?? false);
  }

  void _navigateToSeriesDetail(
    GroupPractice practice,
    GroupProfileSeries series,
    bool isEnrolled,
  ) {
    if (isEnrolled) {
      context.push('/home/series/${series.id}');
      return;
    }

    context.push(
      '/home/series/${series.id}',
      extra: {
        if (practice.groupId != null) 'groupId': practice.groupId,
        'groupType': GroupType.community,
        'isGroupEnrolled': false,
      },
    );
  }

  Future<void> _onPracticeWithUsTap(
    GroupPractice practice,
    GroupProfileSeries series,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final groupId = practice.groupId;
    if (groupId == null) return;

    setState(() => _isEnrollingSeries = true);
    final ok = await enrollSeriesThroughGroup(
      ref: ref,
      seriesId: series.id,
      groupId: groupId,
      groupType: GroupType.community,
    );

    if (!mounted) return;
    setState(() => _isEnrollingSeries = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.series_enroll_error),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(myConnectPracticesProvider.notifier).refresh();
    ref.read(discoverConnectPracticesProvider.notifier).refresh();
    context.push('/home/series/${series.id}');
  }

  void _navigateToAccumulatorDetail(
    String accumulatorId,
    GroupPractice practice,
  ) {
    context.push(
      '/home/group-accumulator/$accumulatorId',
      extra: {
        'groupTitle':
            practice.groupName?.trim().isNotEmpty == true
                ? practice.groupName
                : null,
      },
    );
  }

  Future<void> _onJoinAccumulatorTap(
    GroupPractice practice,
    GroupAccumulator accumulator,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final groupId = practice.groupId ?? accumulator.groupId;
    if (groupId.isEmpty) return;

    setState(() => _joiningAccumulatorId = accumulator.id);
    final ok = await joinGroupAccumulator(
      ref: ref,
      accumulatorId: accumulator.id,
      groupId: groupId,
      awaitRefresh: false,
    );

    if (!mounted) return;
    setState(() => _joiningAccumulatorId = null);

    if (ok) {
      ref.read(myConnectPracticesProvider.notifier).refresh();
      ref.read(discoverConnectPracticesProvider.notifier).refresh();
      _navigateToAccumulatorDetail(accumulator.id, practice);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.group_accumulator_join_error),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToPlanDetail(GroupPractice practice, GroupPracticePlan plan) {
    final planEntity = plan.toPlan();
    context.push(
      '/practice/plans/preview',
      extra: {
        'plan': planEntity,
        if (plan.seriesId != null) 'seriesId': plan.seriesId,
      },
    );
  }

  void _navigateToCollectionDetail(
    GroupPractice practice,
    GroupRecitationCollection collection,
  ) {
    final groupId =
        practice.groupId?.trim().isNotEmpty == true
            ? practice.groupId!
            : collection.groupId;
    if (groupId.trim().isEmpty || collection.id.trim().isEmpty) return;

    context.push(
      '/home/group/$groupId/recitation-collections/${collection.id}',
      extra: {'title': collection.name},
    );
  }
}

class _ConnectPracticeMetaRow extends StatelessWidget {
  const _ConnectPracticeMetaRow({
    required this.practice,
    required this.isDark,
    this.lineHeight,
    this.dateText,
    this.joinCount = 0,
  });

  final GroupPractice practice;
  final bool isDark;
  final double? lineHeight;
  final String? dateText;
  final int joinCount;

  @override
  Widget build(BuildContext context) {
    final hasGroup = _hasGroup(practice);
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final trimmedDate = dateText?.trim();

    if (!hasGroup &&
        (trimmedDate == null || trimmedDate.isEmpty) &&
        joinCount <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasGroup)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConnectPracticeGroupAvatar(
                avatarUrl: practice.groupAvatarUrl,
                groupId: practice.groupId,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ConnectPracticeGroupName(
                  name: practice.groupName ?? '',
                  groupId: practice.groupId,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        if ((trimmedDate != null && trimmedDate.isNotEmpty) ||
            joinCount > 0) ...[
          if (hasGroup) const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (trimmedDate != null && trimmedDate.isNotEmpty)
                Expanded(
                  child: Text(
                    trimmedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryColor,
                      height: lineHeight,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (joinCount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppAssets.usercard, size: 16, color: secondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '$joinCount',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                        height: lineHeight,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }

  bool _hasGroup(GroupPractice practice) {
    return practice.groupId != null &&
        (practice.groupName?.trim().isNotEmpty ?? false);
  }
}

class _ConnectPracticeGroupAvatar extends StatelessWidget {
  const _ConnectPracticeGroupAvatar({
    this.avatarUrl,
    this.groupId,
    required this.isDark,
  });

  final String? avatarUrl;
  final String? groupId;
  final bool isDark;

  static const double _avatarSize = 24;

  @override
  Widget build(BuildContext context) {
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final trimmedAvatar = avatarUrl?.trim();

    final avatar = ClipOval(
      child: SizedBox(
        width: _avatarSize,
        height: _avatarSize,
        child:
            trimmedAvatar != null && trimmedAvatar.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: trimmedAvatar,
                  fit: BoxFit.cover,
                  width: _avatarSize,
                  height: _avatarSize,
                )
                : ColoredBox(
                  color: placeholderColor,
                  child: Icon(
                    AppAssets.usersThree,
                    size: 14,
                    color: isDark ? AppColors.grey500 : AppColors.grey600,
                  ),
                ),
      ),
    );

    final trimmedGroupId = groupId?.trim();
    if (trimmedGroupId == null || trimmedGroupId.isEmpty) return avatar;

    return GestureDetector(
      onTap: () => context.push('/home/group/$trimmedGroupId'),
      behavior: HitTestBehavior.opaque,
      child: avatar,
    );
  }
}

class _ConnectPracticeGroupName extends StatelessWidget {
  const _ConnectPracticeGroupName({
    required this.name,
    this.groupId,
    required this.isDark,
  });

  final String name;
  final String? groupId;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final displayName =
        name.trim().isNotEmpty
            ? name.trim()
            : context.l10n.connect_group_fallback_title;

    final text = Text(
      displayName,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
      ),
    );

    final trimmedGroupId = groupId?.trim();
    if (trimmedGroupId == null || trimmedGroupId.isEmpty) return text;

    return GestureDetector(
      onTap: () => context.push('/home/group/$trimmedGroupId'),
      behavior: HitTestBehavior.opaque,
      child: text,
    );
  }
}
