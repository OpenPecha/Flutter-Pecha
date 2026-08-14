import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_attendance_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ConnectEventCard extends ConsumerStatefulWidget {
  const ConnectEventCard({super.key, required this.event});

  final GroupEvent event;

  @override
  ConsumerState<ConnectEventCard> createState() => _ConnectEventCardState();
}

class _ConnectEventCardState extends ConsumerState<ConnectEventCard> {
  bool? _attendingOverride;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final event = widget.event;
    final isAttending = _attendingOverride ?? event.isJoined;
    final isPast = isGroupEventPast(event);
    final participantCount = _participantCount(event, isAttending);
    final title =
        event.title.trim().isNotEmpty
            ? event.title.trim()
            : context.l10n.connect_event_fallback_title;
    final detailsLine = _formatDetailsLine(context, event, participantCount);

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/home/events/${event.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child:
                  event.image != null && !event.image!.isEmpty
                      ? ResponsiveCoverImage(
                        image: event.image,
                        fit: BoxFit.cover,
                      )
                      : ColoredBox(
                        color:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.grey100,
                        child: Icon(
                          AppAssets.calendarDots,
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
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (detailsLine != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      detailsLine,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _EventGroupLabel(event: event)),
                      if (!isPast) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _toggleAttendance(event, isAttending),
                          behavior: HitTestBehavior.opaque,
                          child: _AttendButton(
                            isAttending: isAttending,
                            isSubmitting: _isSubmitting,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _participantCount(GroupEvent event, bool isAttending) {
    var count = event.participantCount;
    if (isAttending && !event.isJoined) count++;
    if (!isAttending && event.isJoined) count--;
    return count.clamp(0, 1 << 31);
  }

  String? _formatDetailsLine(
    BuildContext context,
    GroupEvent event,
    int participantCount,
  ) {
    final parts = <String>[];

    final start = event.startDate?.toLocal();
    if (start != null) {
      final locale = intlFormatLocaleOf(context);
      parts.add(DateFormat('EEE d MMM', locale).format(start));
    }

    parts.add(_eventLocationLabel(context, event));

    if (participantCount > 0) {
      parts.add(
        context.l10n.connect_event_participants_attending(participantCount),
      );
    }

    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String _eventLocationLabel(BuildContext context, GroupEvent event) {
    final locationId = event.locationId?.trim();
    if (locationId != null && locationId.isNotEmpty) {
      final name = event.location?.name.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return context.l10n.connect_online;
  }

  Future<void> _toggleAttendance(GroupEvent event, bool isAttending) async {
    if (_isSubmitting || isGroupEventPast(event)) return;

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _isSubmitting = true);
    final repository = ref.read(groupProfileRepositoryProvider);
    final result =
        isAttending
            ? await repository.leaveGroupEvent(event.id)
            : await joinGroupEventEnsuringGroupMembership(
              ref: ref,
              event: event,
            );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) {
        setState(() => _attendingOverride = !isAttending);
        ref.invalidate(groupEventDetailProvider(event.id));
        if (event.groupId.isNotEmpty) {
          ref.invalidate(groupEventsProvider(event.groupId));
        }
      },
    );
  }
}

class _EventGroupLabel extends StatelessWidget {
  const _EventGroupLabel({required this.event});

  final GroupEvent event;

  static const double _avatarSize = 24;

  @override
  Widget build(BuildContext context) {
    final name = event.groupName?.trim();
    if (name == null || name.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarUrl = event.groupAvatarUrl?.trim();
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final groupId = event.groupId.trim();

    final content = Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: _avatarSize,
            height: _avatarSize,
            child:
                avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImageWidget(
                      imageUrl: avatarUrl,
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
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );

    if (groupId.isEmpty) return content;

    return GestureDetector(
      onTap: () => context.push('/home/group/$groupId'),
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

class _AttendButton extends StatelessWidget {
  const _AttendButton({
    required this.isAttending,
    required this.isSubmitting,
    required this.isDark,
  });

  final bool isAttending;
  final bool isSubmitting;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color:
            isAttending
                ? (isDark ? AppColors.surfaceVariantDark : AppColors.grey100)
                : (isDark ? AppColors.surfaceWhite : AppColors.textPrimary),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAttending) ...[
            Icon(
              AppAssets.check,
              size: 14,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            const SizedBox(width: 4),
          ],
          if (isSubmitting)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    isAttending
                        ? (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary)
                        : (isDark
                            ? AppColors.textPrimary
                            : AppColors.surfaceWhite),
              ),
            )
          else
            Text(
              isAttending
                  ? context.l10n.connect_event_attending
                  : context.l10n.connect_event_attend,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isAttending
                        ? (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary)
                        : (isDark
                            ? AppColors.textPrimary
                            : AppColors.surfaceWhite),
              ),
            ),
        ],
      ),
    );
  }
}
