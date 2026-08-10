import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_attendance_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
          const Expanded(
            child: Text(
              'Events',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
    final participantsAsync = ref.watch(
      groupEventParticipantsProvider(event.id),
    );
    final participantsPage = participantsAsync.valueOrNull?.fold(
      (_) => null,
      (page) => page,
    );
    final participants = participantsPage?.participants ?? const [];

    // Clear the optimistic override once the server confirms the change,
    // so subsequent state derives purely from `event.isJoined`.
    if (_attendingOverride != null && _attendingOverride == event.isJoined) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _attendingOverride = null);
      });
    }

    final isAttending = _attendingOverride ?? event.isJoined;
    final totalAttending = _attendeeCount(event, isAttending);
    final hasVideos = _hasVideos(event);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventHeroCard(event: event, isDark: isDark),
          const SizedBox(height: 14),
          _AttendeesRow(
            participants: participants,
            totalAttending: totalAttending,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildActionRow(event, isAttending, isDark),
          const SizedBox(height: 16),
          _EventInfoCard(event: event, isDark: isDark),
          const SizedBox(height: 16),
          _buildTabs(isDark, hasVideos: hasVideos),
          const SizedBox(height: 12),
          hasVideos && _selectedTab == 0
              ? _VideosPanel(event: event, isDark: isDark)
              : _AboutPanel(event: event, isDark: isDark),
        ],
      ),
    );
  }

  bool _hasVideos(GroupEvent event) {
    return event.links.any((link) => link.url.isNotEmpty);
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
              : Text(isAttending ? 'Attending' : 'Attend'),
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
            child: const Text('Invite'),
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
            label: 'Videos',
            selected: _selectedTab == 0,
            isDark: isDark,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          const SizedBox(width: 20),
        ],
        _EventTabButton(
          label: 'About',
          selected: !hasVideos || _selectedTab == 1,
          isDark: isDark,
          onTap: () => setState(() => _selectedTab = 1),
        ),
      ],
    );
  }

  Future<void> _attendEvent(GroupEvent event) async {
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
    ref.invalidate(groupEventParticipantsProvider(event.id));
    if (event.groupId.isNotEmpty) {
      ref.invalidate(groupEventsProvider(event.groupId));
    }
  }

  Future<void> _shareEvent() async {
    final shareUrl =
        DeepLinkUrlBuilder.eventLink(eventId: widget.eventId).toString();
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
    final title = event.title.trim().isNotEmpty ? event.title.trim() : 'Event';

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
  final List<GroupEventParticipant> participants;
  final int totalAttending;
  final bool isDark;

  const _AttendeesRow({
    required this.participants,
    required this.totalAttending,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final shown = participants.take(2).toList();
    final remaining = math.max(0, totalAttending - shown.length);
    final textColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    final double avatarSize = 28.0;
    final double overlap = 18.0;

    final int totalItems = shown.length + (remaining > 0 ? 1 : 0);
    final double stackWidth =
        totalItems == 0 ? 0 : (totalItems - 1) * overlap + avatarSize;

    return Row(
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
          '$totalAttending attending',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
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
          const Text(
            'WHEN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 7),
          if (dateText != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppAssets.calendarDots, size: 15, color: secondaryColor),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(dateText, style: const TextStyle(fontSize: 14)),
                ),
              ],
            )
          else
            Text(
              'Date to be announced',
              style: TextStyle(fontSize: 14, color: secondaryColor),
            ),
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
    return '$date · $startTime - $endTime ${start.timeZoneName}';
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
  final GroupEvent event;
  final bool isDark;

  const _VideosPanel({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final links = event.links.where((link) => link.url.isNotEmpty).toList();
    if (links.isEmpty) {
      return Text(
        'No videos yet',
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More about this event',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: links.length,
          itemBuilder: (context, index) {
            return _VideoLinkCard(
              link: links[index],
              event: event,
              isDark: isDark,
            );
          },
        ),
      ],
    );
  }
}

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
    return GestureDetector(
      onTap: () => _openLink(link.url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            event.image != null && !event.image!.isEmpty
                ? ResponsiveCoverImage(image: event.image, fit: BoxFit.cover)
                : ColoredBox(
                  color:
                      isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
                ),
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
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                'No event details yet',
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
