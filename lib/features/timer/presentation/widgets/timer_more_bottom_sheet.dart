import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Bottom sheet opened from the three-dot (⋮) button on a [PresetTimerCard].
///
/// Contains:
///   • "+ Add to my practices" action
///   • Bookmark toggle action
class TimerMoreBottomSheet extends ConsumerStatefulWidget {
  const TimerMoreBottomSheet({
    super.key,
    required this.timer,
    this.onAddToPractices,
  });

  final PresetTimer timer;
  final VoidCallback? onAddToPractices;

  @override
  ConsumerState<TimerMoreBottomSheet> createState() =>
      _TimerMoreBottomSheetState();
}

class _TimerMoreBottomSheetState extends ConsumerState<TimerMoreBottomSheet> {
  bool _isBookmarking = false;
  bool _isSharing = false;

  BookmarkTarget get _bookmarkTarget => BookmarkTarget(
        type: BookmarkType.timer,
        sourceId: widget.timer.id,
      );

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final longUrl =
          DeepLinkUrlBuilder.timerLink(timerId: widget.timer.id).toString();
      final shareMessage = context.l10n.share_timer_message;
      final shareUrl = await resolveShareUrlRef(ref, longUrl);
      if (!mounted) return;
      Navigator.of(context).pop();
      await SharePlus.instance.share(
        ShareParams(text: '$shareMessage\n\n$shareUrl'),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarking) return;
    setState(() => _isBookmarking = true);
    try {
      final nav = Navigator.of(context);
      final didToggle = await BookmarkController(
        ref: ref,
        context: context,
      ).toggleTimer(widget.timer.id);
      if (mounted && didToggle) nav.pop();
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isBookmarked = ref.watch(isBookmarkedProvider(_bookmarkTarget));

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Add to my practices ────────────────────────────────────────
          _SectionDivider(theme: theme),
          ListTile(
            leading: Icon(AppAssets.plus, color: theme.colorScheme.onSurface),
            title: Text(
              l10n.mala_add_to_practice,
              style: theme.textTheme.bodyLarge,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              widget.onAddToPractices?.call();
            },
          ),

          // ── Bookmark ───────────────────────────────────────────────────
          _SectionDivider(theme: theme),
          ListTile(
            leading:
                _isBookmarking
                    ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                    : Icon(
                      isBookmarked
                          ? AppAssets.bookmarkSimpleFill
                          : AppAssets.bookmarkSimple,
                      color: theme.colorScheme.onSurface,
                    ),
            title: Text(l10n.bookmark, style: theme.textTheme.bodyLarge),
            onTap: () {
              HapticFeedback.lightImpact();
              _toggleBookmark();
            },
          ),

          // ── Share ──────────────────────────────────────────────────────
          _SectionDivider(theme: theme),
          ListTile(
            leading:
                _isSharing
                    ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                    : Icon(AppAssets.readerShare, color: theme.colorScheme.onSurface),
            title: Text(l10n.share, style: theme.textTheme.bodyLarge),
            onTap: () {
              HapticFeedback.lightImpact();
              _share();
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: theme.dividerColor);
}

/// Shows the timer "more" bottom sheet.
void showTimerMoreBottomSheet(
  BuildContext context, {
  required PresetTimer timer,
  VoidCallback? onAddToPractices,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    useRootNavigator: true,
    builder:
        (_) => TimerMoreBottomSheet(
          timer: timer,
          onAddToPractices: onAddToPractices,
        ),
  );
}
