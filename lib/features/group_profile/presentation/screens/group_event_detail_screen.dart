import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_attendance_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_link_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_participants_drawer.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/youtube_video_player.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class GroupEventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const GroupEventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<GroupEventDetailScreen> createState() =>
      _GroupEventDetailScreenState();
}

class _GroupEventDetailScreenState
    extends ConsumerState<GroupEventDetailScreen> {
  int _selectedTab = 0;
  bool? _attendingOverride;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(groupEventParticipantsProvider(widget.eventId).notifier)
          .loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventAsync = ref.watch(groupEventDetailProvider(widget.eventId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context, isDark),
            Expanded(
              child: eventAsync.when(
                data:
                    (either) => either.fold(
                      (failure) => ErrorStateWidget(
                        error: failure,
                        onRetry:
                            () => ref.invalidate(
                              groupEventDetailProvider(widget.eventId),
                            ),
                      ),
                      (event) => _buildContent(context, event, isDark),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => ErrorStateWidget(
                      error: error,
                      onRetry:
                          () => ref.invalidate(
                            groupEventDetailProvider(widget.eventId),
                          ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          Expanded(
            child: Text(
              context.l10n.connect_tab_events,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(AppAssets.readerShare),
            onPressed: _shareEvent,
            iconSize: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, GroupEvent event, bool isDark) {
    final participantsState = ref.watch(
      groupEventParticipantsProvider(event.id),
    );
    final participants = participantsState.participants;

    // Clear the optimistic override once the server confirms the change,
    // so subsequent state derives purely from `event.isJoined`.
    if (_attendingOverride != null && _attendingOverride == event.isJoined) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _attendingOverride = null);
      });
    }

    final isAttending = _attendingOverride ?? event.isJoined;
    final totalAttending = _attendeeCount(event, isAttending);
    final videos = _videoLinks(event);
    final hasVideos = videos.isNotEmpty;
    final hasPractices =
        event.plan != null ||
        event.accumulator != null ||
        event.groupRecitationCollection != null;
    final isPast = isGroupEventPast(event);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventHeroCard(event: event, isDark: isDark),
          const SizedBox(height: 14),
          _AttendeesRow(
            eventId: event.id,
            participants: participants,
            totalAttending: totalAttending,
            isDark: isDark,
          ),
          if (!isPast) ...[
            const SizedBox(height: 14),
            _buildActionRow(event, isAttending, isDark),
          ],
          const SizedBox(height: 16),
          _EventInfoCard(event: event, isDark: isDark),
          if (hasPractices) ...[
            const SizedBox(height: 16),
            _EventPracticesCard(event: event, isDark: isDark),
          ],
          const SizedBox(height: 16),
          _buildTabs(isDark, hasVideos: hasVideos),
          const SizedBox(height: 12),
          hasVideos && _selectedTab == 0
              ? _VideosPanel(videos: videos, event: event, isDark: isDark)
              : _AboutPanel(event: event, isDark: isDark),
        ],
      ),
    );
  }

  int _attendeeCount(GroupEvent event, bool isAttending) {
    var count = event.participantCount;
    if (isAttending && !event.isJoined) count++;
    if (!isAttending && event.isJoined) count--;
    return math.max(0, count);
  }

  Widget _buildActionRow(GroupEvent event, bool isAttending, bool isDark) {
    final secondaryButtonColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite;
    final secondaryBorder = isDark ? AppColors.grey800 : AppColors.grey300;

    final attendButton = ElevatedButton(
      onPressed:
          _isSubmitting
              ? null
              : () => isAttending ? _leaveEvent(event) : _attendEvent(event),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 44),
        backgroundColor:
            isAttending
                ? (isDark ? AppColors.surfaceVariantDark : AppColors.grey100)
                : (isDark ? AppColors.surfaceWhite : AppColors.textPrimary),
        foregroundColor:
            isAttending
                ? (isDark ? AppColors.textTertiaryDark : AppColors.textPrimary)
                : (isDark ? AppColors.textPrimary : AppColors.surfaceWhite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child:
          _isSubmitting
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Text(
                isAttending
                    ? context.l10n.connect_event_attending
                    : context.l10n.connect_event_attend,
              ),
    );

    if (!isAttending) {
      return SizedBox(width: double.infinity, child: attendButton);
    }

    return Row(
      children: [
        Expanded(child: attendButton),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : _shareEvent,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: secondaryButtonColor,
              foregroundColor:
                  isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              side: BorderSide(color: secondaryBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(context.l10n.group_invite),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool isDark, {required bool hasVideos}) {
    return Row(
      children: [
        if (hasVideos) ...[
          _EventTabButton(
            label: context.l10n.connect_event_tab_videos,
            selected: _selectedTab == 0,
            isDark: isDark,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          const SizedBox(width: 20),
        ],
        _EventTabButton(
          label: context.l10n.connect_event_tab_about,
          selected: !hasVideos || _selectedTab == 1,
          isDark: isDark,
          onTap: () => setState(() => _selectedTab = 1),
        ),
      ],
    );
  }

  List<GroupEventLink> _videoLinks(GroupEvent event) {
    return event.links
        .where(
          (link) =>
              link.url.isNotEmpty &&
              GroupEventLinkUtils.kindOf(link) == GroupEventLinkKind.video,
        )
        .toList();
  }

  Future<void> _attendEvent(GroupEvent event) async {
    if (isGroupEventPast(event)) return;

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await joinGroupEventEnsuringGroupMembership(
      ref: ref,
      event: event,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold((failure) => _showError(failure.message), (_) {
      setState(() => _attendingOverride = true);
      _refreshEvent(event);
    });
  }

  Future<void> _leaveEvent(GroupEvent event) async {
    if (isGroupEventPast(event)) return;

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref
        .read(groupProfileRepositoryProvider)
        .leaveGroupEvent(event.id);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold((failure) => _showError(failure.message), (_) {
      setState(() => _attendingOverride = false);
      _refreshEvent(event);
    });
  }

  void _refreshEvent(GroupEvent event) {
    ref.invalidate(groupEventDetailProvider(event.id));
    ref.read(groupEventParticipantsProvider(event.id).notifier).refresh();
    if (event.groupId.isNotEmpty) {
      ref.invalidate(groupEventsProvider(event.groupId));
    }
  }

  Future<void> _shareEvent() async {
    final longUrl =
        DeepLinkUrlBuilder.eventLink(eventId: widget.eventId).toString();
    final shareUrl = await resolveShareUrlRef(ref, longUrl);
    if (!mounted) return;

    await SharePlus.instance.share(
      ShareParams(
        text: shareUrl,
        sharePositionOrigin: getSharePositionOrigin(context: context),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class _EventHeroCard extends StatelessWidget {
  final GroupEvent event;
  final bool isDark;

  const _EventHeroCard({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final title =
        event.title.trim().isNotEmpty
            ? event.title.trim()
            : context.l10n.connect_event_fallback_title;

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
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
                        size: 42,
                        color: isDark ? AppColors.grey500 : AppColors.grey600,
                      ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeesRow extends StatelessWidget {
  final String eventId;
  final List<GroupEventParticipant> participants;
  final int totalAttending;
  final bool isDark;

  const _AttendeesRow({
    required this.eventId,
    required this.participants,
    required this.totalAttending,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (totalAttending <= 0) {
      return const SizedBox.shrink();
    }

    final shown = participants.take(2).toList();
    final remaining = math.max(0, totalAttending - shown.length);
    final textColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    final double avatarSize = 28.0;
    final double overlap = 18.0;

    final int totalItems = shown.length + (remaining > 0 ? 1 : 0);
    final double stackWidth =
        totalItems == 0 ? 0 : (totalItems - 1) * overlap + avatarSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          () => GroupEventParticipantsDrawer.show(
            context,
            eventId: eventId,
            totalAttending: totalAttending,
          ),
      child: Row(
        children: [
          if (totalItems > 0)
            SizedBox(
              width: stackWidth,
              height: avatarSize,
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(
                      left: i * overlap,
                      child: _ParticipantAvatar(
                        participant: shown[i],
                        isDark: isDark,
                        size: avatarSize,
                      ),
                    ),
                  if (remaining > 0)
                    Positioned(
                      left: shown.length * overlap,
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark
                                  ? AppColors.grey800
                                  : const Color(0xFFE8E5DF),
                          border: Border.all(
                            color:
                                isDark
                                    ? AppColors.scaffoldBackgroundDark
                                    : AppColors.surfaceLight,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '+$remaining',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.greyDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (totalItems > 0) const SizedBox(width: 8),
          Text(
            context.l10n.connect_event_participants_attending(totalAttending),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  final GroupEventParticipant participant;
  final bool isDark;
  final double size;

  const _ParticipantAvatar({
    required this.participant,
    required this.isDark,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = participant.avatarUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color:
              isDark
                  ? AppColors.scaffoldBackgroundDark
                  : AppColors.surfaceLight,
          width: 2,
        ),
      ),
      child: ClipOval(
        child:
            avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: _avatarFallback(),
                )
                : _avatarFallback(),
      ),
    );
  }

  Widget _avatarFallback() {
    final name = participant.displayName;
    final initials = _getInitials(name);

    return ColoredBox(
      color: AppColors.primary,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDarkest,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0].characters.first}${parts[1].characters.first}'
          .toUpperCase();
    }
    return name.characters.take(2).toString().toUpperCase();
  }
}

class _EventInfoCard extends StatelessWidget {
  final GroupEvent event;
  final bool isDark;

  const _EventInfoCard({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dateText = _formatDateText(context, event);
    final recurrenceText = _formatRecurrenceText(context, event);
    final locationName = event.location?.name.trim() ?? '';
    final isOnline = isGroupEventOnline(event);
    final showLocation = !isOnline && locationName.isNotEmpty;
    final links =
        event.links
            .where(
              (link) =>
                  link.url.isNotEmpty &&
                  GroupEventLinkUtils.kindOf(link) != GroupEventLinkKind.video,
            )
            .toList();
    // Only a meeting room implies an online venue, not a plain link.
    final hasMeetingLink = links.any(
      (link) =>
          GroupEventLinkUtils.kindOf(link) == GroupEventLinkKind.meeting,
    );
    final showOnline =
        isOnline || isGroupEventHybrid(event) || hasMeetingLink;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventSectionLabel(text: context.l10n.connect_event_when),
          const SizedBox(height: 10),
          if (dateText != null)
            _EventInfoRow(
              icon: AppAssets.clock,
              text: dateText,
              iconColor: secondaryColor,
            )
          else
            Text(
              context.l10n.connect_event_date_tba,
              style: TextStyle(fontSize: 14, color: secondaryColor),
            ),
          if (recurrenceText != null) ...[
            const SizedBox(height: 10),
            _EventInfoRow(
              icon: AppAssets.repeat,
              text: recurrenceText,
              iconColor: secondaryColor,
            ),
          ],
          if (showLocation || showOnline || links.isNotEmpty) ...[
            const SizedBox(height: 16),
            _EventSectionLabel(text: context.l10n.connect_event_where),
            const SizedBox(height: 10),
          ],
          if (showLocation)
            _EventInfoRow(
              icon: AppAssets.buildings,
              text: locationName,
              iconColor: secondaryColor,
              bold: true,
            ),
          if (showOnline) ...[
            if (showLocation) const SizedBox(height: 12),
            _EventInfoRow(
              icon: AppAssets.videoCamera,
              text: context.l10n.connect_online,
              iconColor: secondaryColor,
              bold: true,
            ),
          ],
          for (final link in links) ...[
            const SizedBox(height: 10),
            _EventLinkText(link: link, isDark: isDark),
          ],
        ],
      ),
    );
  }

  String? _formatDateText(BuildContext context, GroupEvent event) {
    final start = event.startDate?.toLocal();
    if (start == null) return null;

    final locale = intlFormatLocaleOf(context);
    final date = DateFormat('EEE d MMM y', locale).format(start);
    final startTime = DateFormat.jm(locale).format(start).toLowerCase();
    final end = event.endDate?.toLocal();
    if (end == null || end.isAtSameMomentAs(start)) {
      return '$date · $startTime ${start.timeZoneName}';
    }

    final endTime = DateFormat.jm(locale).format(end).toLowerCase();
    final isMultiDay = !event.isOneDay && !DateUtils.isSameDay(start, end);
    if (isMultiDay) {
      final endDate = DateFormat('EEE d MMM y', locale).format(end);
      return '$date · $startTime – $endDate · $endTime ${end.timeZoneName}';
    }
    return '$date · $startTime – $endTime ${end.timeZoneName}';
  }

  String? _formatRecurrenceText(BuildContext context, GroupEvent event) {
    final recurrence = event.recurrence;
    if (!event.isRecurring || recurrence == null) return null;

    final anchor = (event.occurrenceDate ?? event.startDate)?.toLocal();
    if (anchor == null) return null;

    final locale = intlFormatLocaleOf(context);
    return switch (recurrence.frequency.toUpperCase()) {
      'DAILY' => context.l10n.connect_event_every_day,
      'WEEKLY' => context.l10n.connect_event_every_weekday(
        DateFormat.EEEE(locale).format(anchor),
      ),
      'MONTHLY' => context.l10n.connect_event_every_month,
      'YEARLY' => context.l10n.connect_event_every_date(
        DateFormat('d MMM', locale).format(anchor),
      ),
      _ => null,
    };
  }
}

class _EventSectionLabel extends StatelessWidget {
  final String text;

  const _EventSectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.poemAuthor,
      ),
    );
  }
}

class _EventInfoRow extends StatelessWidget {
  const _EventInfoRow({
    required this.icon,
    required this.text,
    required this.iconColor,
    this.leading,
    this.textColor,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final Color iconColor;

  /// Replaces [icon] when set, e.g. a brand logo image.
  final Widget? leading;
  final Color? textColor;
  final bool bold;

  static const double _iconSize = 16;
  static const double _iconSlotWidth = 18;
  static const TextStyle _textStyle = TextStyle(fontSize: 14, height: 1.35);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _iconSlotWidth,
          height: _textStyle.fontSize! * _textStyle.height!,
          child: Align(
            alignment: Alignment.center,
            child: leading ?? Icon(icon, size: _iconSize, color: iconColor),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: _textStyle.copyWith(
              fontWeight: bold ? FontWeight.w700 : null,
              color: textColor,
            ),
            maxLines: textColor == null ? null : 1,
            overflow: textColor == null ? null : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Meeting or web link under the "Online" row, shown as its short url with a
/// camera icon for meeting rooms and a globe for everything else.
class _EventLinkText extends StatelessWidget {
  final GroupEventLink link;
  final bool isDark;

  const _EventLinkText({required this.link, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isMeeting =
        GroupEventLinkUtils.kindOf(link) == GroupEventLinkKind.meeting;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final brandIcon = _brandIcon();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openLink(link.url),
      child: _EventInfoRow(
        icon: isMeeting ? AppAssets.videoCamera : AppAssets.globe,
        leading:
            brandIcon == null
                ? null
                : Image.asset(brandIcon, width: 16, height: 16),
        text: GroupEventLinkUtils.shortUrl(link.url),
        iconColor: secondaryColor,
        textColor: isDark ? AppColors.blueDark : AppColors.blue,
        bold: true,
      ),
    );
  }

  String? _brandIcon() {
    final provider = GroupEventLinkUtils.providerName(link) ?? link.type;
    return switch (provider.toLowerCase()) {
      'google meet' || 'google-meet' || 'meet' => AppAssets.googleMeetIcon,
      'zoom' => AppAssets.zoomIcon,
      _ => null,
    };
  }
}

class _EventPracticesCard extends ConsumerStatefulWidget {
  final GroupEvent event;
  final bool isDark;

  const _EventPracticesCard({required this.event, required this.isDark});

  @override
  ConsumerState<_EventPracticesCard> createState() =>
      _EventPracticesCardState();
}

class _EventPracticesCardState extends ConsumerState<_EventPracticesCard> {
  String? _loadingId;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isDark = widget.isDark;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final plan = event.plan;
    final accumulator = event.accumulator;
    final collection = event.groupRecitationCollection;

    final rows = <Widget>[
      if (plan != null)
        _EventPracticeRow(
          practice: plan,
          isDark: isDark,
          isLoading: _loadingId == plan.id,
          onTap: () => _openPlan(plan),
        ),
      if (accumulator != null)
        _EventPracticeRow(
          practice: accumulator,
          isDark: isDark,
          isLoading: false,
          onTap: () => _openMala(accumulator),
        ),
      if (collection != null)
        _EventPracticeRow(
          practice: collection,
          isDark: isDark,
          isLoading: false,
          onTap:
              () => context.push(
                '/home/group/${event.groupId}/recitation-collections/${collection.id}',
                extra: {'title': collection.name},
              ),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventSectionLabel(text: context.l10n.connect_event_practices),
          const SizedBox(height: 4),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
              ),
            rows[i],
          ],
        ],
      ),
    );
  }

  Future<void> _openPlan(GroupEventPracticeRef practice) async {
    if (_loadingId != null) return;
    setState(() => _loadingId = practice.id);

    final either = await ref.read(planByIdFutureProvider(practice.id).future);
    if (!mounted) return;
    setState(() => _loadingId = null);

    final plan = either.fold((_) => null, (plan) => plan);
    if (plan == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.notFound)));
      return;
    }
    context.push(AppRoutes.practicePlanPreview, extra: {'plan': plan});
  }

  /// `accumulator_id` on an event is a mala preset id, so the counter opens
  /// on that mantra directly.
  void _openMala(GroupEventPracticeRef practice) {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }
    context.push(AppRoutes.mala, extra: {'presetId': practice.id});
  }
}

class _EventPracticeRow extends StatelessWidget {
  final GroupEventPracticeRef practice;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onTap;

  const _EventPracticeRow({
    required this.practice,
    required this.isDark,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final imageUrl = practice.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 48,
                height: 48,
                child:
                    hasImage
                        ? CachedNetworkImageWidget(
                          imageUrl: imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: _imageFallback(),
                        )
                        : _imageFallback(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                practice.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  AppAssets.caretRight,
                  size: 18,
                  color: secondaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.bookOpenText,
        size: 20,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}

class _EventTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _EventTabButton({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        selected
            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
            : (isDark ? AppColors.textTertiaryDark : AppColors.textSecondary);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 2,
            color: selected ? textColor : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _VideosPanel extends StatelessWidget {
  final List<GroupEventLink> videos;
  final GroupEvent event;
  final bool isDark;

  const _VideosPanel({
    required this.videos,
    required this.event,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return _VideoLinkCard(
          link: videos[index],
          event: event,
          isDark: isDark,
        );
      },
    );
  }
}

Future<void> _openLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// YouTube thumbnail that plays in the in-app full-screen player; any other
/// video host falls back to the event image and opens externally.
class _VideoLinkCard extends StatelessWidget {
  final GroupEventLink link;
  final GroupEvent event;
  final bool isDark;

  const _VideoLinkCard({
    required this.link,
    required this.event,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final videoId = YoutubePlayer.convertUrlToId(link.url);
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final label = link.label?.trim() ?? '';

    return GestureDetector(
      onTap: () => _play(context, videoId),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (videoId != null)
              CachedNetworkImageWidget(
                imageUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                fit: BoxFit.cover,
                errorWidget: ColoredBox(color: placeholderColor),
              )
            else if (event.image != null && !event.image!.isEmpty)
              ResponsiveCoverImage(image: event.image, fit: BoxFit.cover)
            else
              ColoredBox(color: placeholderColor),
            Container(color: Colors.black.withValues(alpha: 0.18)),
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
                child: const Icon(
                  AppAssets.play,
                  color: AppColors.primaryDark,
                  size: 24,
                ),
              ),
            ),
            if (label.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _play(BuildContext context, String? videoId) {
    if (videoId == null) {
      _openLink(link.url);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => YoutubeVideoPlayer(
              videoUrl: link.url,
              title: link.label?.trim() ?? '',
            ),
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  final GroupEvent event;
  final bool isDark;

  const _AboutPanel({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final description = event.description?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          description != null && description.isNotEmpty
              ? PlanInlineMarkdownView(
                content: description,
                fontSize: getLocalizedFontSize(AppTextSize.body),
              )
              : Text(
                context.l10n.connect_event_about_empty,
                style: TextStyle(
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textSecondary,
                ),
              ),
    );
  }
}
