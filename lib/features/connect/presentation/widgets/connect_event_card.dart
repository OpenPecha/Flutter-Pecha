import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_attendance_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_card_header.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

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
      child: InkWell(
        onTap: () => context.push('/home/events/${event.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConnectFeedCardHeader(
              groupName: event.groupName ?? '',
              groupAvatarUrl: event.groupAvatarUrl,
              groupId: event.groupId,
              subtitle: detailsLine,
              trailing: IconButton(
                onPressed: () => _shareEvent(event),
                icon: Icon(
                  AppAssets.readerShare,
                  size: 20,
                  color: secondaryColor,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: context.l10n.share,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRect(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
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
                              color:
                                  isDark
                                      ? AppColors.grey500
                                      : AppColors.grey600,
                            ),
                          ),
                      if (!isPast)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: GestureDetector(
                            onTap: () => _toggleAttendance(event, isAttending),
                            behavior: HitTestBehavior.opaque,
                            child: _AttendButton(
                              isAttending: isAttending,
                              isSubmitting: _isSubmitting,
                              isDark: isDark,
                              onImage: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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

  Future<void> _shareEvent(GroupEvent event) async {
    final title = event.title.trim();
    final shareUrl = DeepLinkUrlBuilder.eventLink(eventId: event.id).toString();
    final message = title.isNotEmpty ? '$title\n\n$shareUrl' : shareUrl;
    await SharePlus.instance.share(ShareParams(text: message));
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

class _AttendButton extends StatelessWidget {
  const _AttendButton({
    required this.isAttending,
    required this.isSubmitting,
    required this.isDark,
    this.onImage = false,
  });

  final bool isAttending;
  final bool isSubmitting;
  final bool isDark;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final attendingFill =
        onImage
            ? Colors.white.withValues(alpha: 0.92)
            : (isDark ? AppColors.surfaceVariantDark : AppColors.grey100);
    final attendingTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final attendFill =
        onImage
            ? AppColors.textPrimary.withValues(alpha: 0.88)
            : (isDark ? AppColors.surfaceWhite : AppColors.textPrimary);
    final attendTextColor =
        onImage
            ? Colors.white
            : (isDark ? AppColors.textPrimary : AppColors.surfaceWhite);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isAttending ? attendingFill : attendFill,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            onImage
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAttending) ...[
            Icon(AppAssets.check, size: 14, color: attendingTextColor),
            const SizedBox(width: 4),
          ],
          if (isSubmitting)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isAttending ? attendingTextColor : attendTextColor,
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
                color: isAttending ? attendingTextColor : attendTextColor,
              ),
            ),
        ],
      ),
    );
  }
}
