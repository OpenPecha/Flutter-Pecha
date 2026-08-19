import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

enum StreakWeekDayCellState { today, practiced, missed, future }

class StreakWeekTracker extends StatelessWidget {
  const StreakWeekTracker({
    super.key,
    required this.practicedDays,
    this.forShare = false,
  });

  final List<int> practicedDays;
  final bool forShare;

  @override
  Widget build(BuildContext context) {
    final todayWeekday = DateTime.now().weekday;
    final practicedSet = practicedDays.toSet();
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        for (var dayIndex = 1; dayIndex <= 7; dayIndex++) ...[
          if (dayIndex > 1) const SizedBox(width: 4),
          Expanded(
            child: _WeekDayColumn(
              dayIndex: dayIndex,
              state: resolveCellState(
                dayIndex: dayIndex,
                todayWeekday: todayWeekday,
                practicedDays: practicedSet,
              ),
              l10n: l10n,
              forShare: forShare,
            ),
          ),
        ],
      ],
    );
  }

  static StreakWeekDayCellState resolveCellState({
    required int dayIndex,
    required int todayWeekday,
    required Set<int> practicedDays,
  }) {
    if (dayIndex == todayWeekday) return StreakWeekDayCellState.today;
    if (practicedDays.contains(dayIndex)) {
      return StreakWeekDayCellState.practiced;
    }
    if (dayIndex < todayWeekday) return StreakWeekDayCellState.missed;
    return StreakWeekDayCellState.future;
  }
}

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({
    required this.dayIndex,
    required this.state,
    required this.l10n,
    required this.forShare,
  });

  final int dayIndex;
  final StreakWeekDayCellState state;
  final AppLocalizations l10n;
  final bool forShare;

  String _weekdayLabel(int day) {
    return switch (day) {
      1 => l10n.weekday_monday,
      2 => l10n.weekday_tuesday,
      3 => l10n.weekday_wednesday,
      4 => l10n.weekday_thursday,
      5 => l10n.weekday_friday,
      6 => l10n.weekday_saturday,
      7 => l10n.weekday_sunday,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            _weekdayLabel(dayIndex),
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _WeekDayCell(state: state, forShare: forShare),
      ],
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell({required this.state, required this.forShare});

  final StreakWeekDayCellState state;
  final bool forShare;

  static const _cellSize = 36.0;
  static const _flameColor = Color(0xFFE8630A);

  @override
  Widget build(BuildContext context) {
    final isDark = !forShare && Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.cardDark : AppColors.surfaceWhite;
    final missedColor = AppColors.grey300;
    final todayBorderColor = AppColors.brandblue;

    return SizedBox(
      width: _cellSize,
      height: _cellSize,
      child: switch (state) {
        StreakWeekDayCellState.today => DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: todayBorderColor, width: 1.5),
          ),
          child: const Center(
            child: Icon(AppAssets.flame, size: 16, color: _flameColor),
          ),
        ),
        StreakWeekDayCellState.practiced => DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.brandblue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(AppAssets.check, size: 16, color: Colors.white),
          ),
        ),
        StreakWeekDayCellState.missed => DecoratedBox(
          decoration: BoxDecoration(
            color: missedColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              '—',
              style: TextStyle(
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ),
        StreakWeekDayCellState.future => const SizedBox.shrink(),
      },
    );
  }
}
