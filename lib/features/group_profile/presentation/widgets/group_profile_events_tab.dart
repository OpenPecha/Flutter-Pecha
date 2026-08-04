import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class GroupProfileEventsTab extends ConsumerWidget {
  final String groupId;
  final bool isDark;
  final double? lineHeight;

  const GroupProfileEventsTab({
    super.key,
    required this.groupId,
    required this.isDark,
    this.lineHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(groupEventsProvider(groupId));

    return eventsAsync.when(
      data: (either) {
        return either.fold(
          (failure) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ErrorStateWidget(
                error: failure,
                customMessage: 'Unable to load events. Please try again.',
                onRetry: () => ref.invalidate(groupEventsProvider(groupId)),
              ),
            ),
          ),
          (page) {
            if (page.events.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                children: [
                  Text(
                    'No events yet',
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondary,
                      height: lineHeight,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: page.events.length,
              itemBuilder: (context, index) {
                final event = page.events[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == page.events.length - 1 ? 0 : 16,
                  ),
                  child: _GroupEventCard(
                    event: event,
                    isDark: isDark,
                    lineHeight: lineHeight,
                    onTap: () => context.push('/home/events/${event.id}'),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ErrorStateWidget(
                error: error,
                customMessage: 'Unable to load events. Please try again.',
                onRetry: () => ref.invalidate(groupEventsProvider(groupId)),
              ),
            ),
          ),
    );
  }
}

class _GroupEventCard extends StatelessWidget {
  final GroupEvent event;
  final bool isDark;
  final double? lineHeight;
  final VoidCallback? onTap;

  const _GroupEventCard({
    required this.event,
    required this.isDark,
    this.lineHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final title = event.title.trim().isNotEmpty ? event.title.trim() : 'Event';
    final dateLabel = _formatDateLabel(context, event);

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: lineHeight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateLabel != null || event.participantCount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (dateLabel != null)
                          Expanded(
                            child: Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryColor,
                                height: lineHeight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (event.participantCount > 0) ...[
                          Icon(
                            AppAssets.usercard,
                            size: 16,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.participantCount}',
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

  String? _formatDateLabel(BuildContext context, GroupEvent event) {
    final start = event.startDate?.toLocal();
    if (start == null) return null;

    final locale = intlFormatLocaleOf(context);
    final date = DateFormat('d MMM y', locale).format(start);
    final time = DateFormat.jm(locale).format(start).toLowerCase();
    return '$date · $time';
  }
}
