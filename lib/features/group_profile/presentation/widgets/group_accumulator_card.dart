import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';
import 'package:go_router/go_router.dart';

class GroupAccumulatorCard extends StatelessWidget {
  final GroupAccumulator accumulator;
  final bool hasJoined;
  final bool isDark;
  final double? lineHeight;
  final bool isJoining;
  final VoidCallback? onTap;
  final VoidCallback? onJoinTap;
  final String? groupName;
  final String? groupAvatarUrl;
  final String? groupId;

  const GroupAccumulatorCard({
    super.key,
    required this.accumulator,
    required this.hasJoined,
    required this.isDark,
    this.lineHeight,
    this.isJoining = false,
    this.onTap,
    this.onJoinTap,
    this.groupName,
    this.groupAvatarUrl,
    this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final dateRange = _formatDateRange(accumulator);
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final showJoinOverlay = !hasJoined;

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isJoining ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  accumulator.image != null && !accumulator.image!.isEmpty
                      ? ResponsiveCoverImage(
                        image: accumulator.image,
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
                  if (showJoinOverlay)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isJoining ? null : onTap,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.55),
                        alignment: Alignment.center,
                        child:
                            isJoining
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
                                  onTap: onJoinTap,
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
                                      context.l10n.group_join_to_contribute,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
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
                    accumulator.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: lineHeight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateRange != null ||
                      accumulator.memberCount > 0 ||
                      _hasGroupLabel) ...[
                    const SizedBox(height: 4),
                    _hasGroupLabel
                        ? _ConnectGroupMetaRow(
                          groupName: groupName!,
                          groupAvatarUrl: groupAvatarUrl,
                          groupId: groupId,
                          isDark: isDark,
                          lineHeight: lineHeight,
                          dateText: dateRange,
                          joinCount: accumulator.memberCount,
                        )
                        : Row(
                          children: [
                            if (dateRange != null)
                              Expanded(
                                child: Text(
                                  dateRange,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: secondaryColor,
                                    height: lineHeight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (accumulator.memberCount > 0) ...[
                              Icon(
                                AppAssets.usercard,
                                size: 16,
                                color: secondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${accumulator.memberCount}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: secondaryColor,
                                  height: lineHeight,
                                ),
                              ),
                            ],
                          ],
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

  String? _formatDateRange(GroupAccumulator accumulator) {
    return PlanDateFormat.formatRangeOrNull(
      accumulator.startDate,
      accumulator.endDate,
    );
  }

  bool get _hasGroupLabel =>
      groupName != null && groupName!.trim().isNotEmpty;
}

class _ConnectGroupMetaRow extends StatelessWidget {
  const _ConnectGroupMetaRow({
    required this.groupName,
    this.groupAvatarUrl,
    this.groupId,
    required this.isDark,
    this.lineHeight,
    this.dateText,
    this.joinCount = 0,
  });

  final String groupName;
  final String? groupAvatarUrl;
  final String? groupId;
  final bool isDark;
  final double? lineHeight;
  final String? dateText;
  final int joinCount;

  static const double _avatarSize = 24;

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final displayName =
        groupName.trim().isNotEmpty
            ? groupName.trim()
            : context.l10n.connect_group_fallback_title;
    final trimmedAvatar = groupAvatarUrl?.trim();
    final trimmedDate = dateText?.trim();
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupTapTarget(
              context,
              child: ClipOval(
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
                              color:
                                  isDark ? AppColors.grey500 : AppColors.grey600,
                            ),
                          ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildGroupTapTarget(
                context,
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ],
        ),
        if ((trimmedDate != null && trimmedDate.isNotEmpty) || joinCount > 0) ...[
          const SizedBox(height: 4),
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

  Widget _buildGroupTapTarget(BuildContext context, {required Widget child}) {
    final trimmedGroupId = groupId?.trim();
    if (trimmedGroupId == null || trimmedGroupId.isEmpty) return child;

    return GestureDetector(
      onTap: () => context.push('/home/group/$trimmedGroupId'),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
