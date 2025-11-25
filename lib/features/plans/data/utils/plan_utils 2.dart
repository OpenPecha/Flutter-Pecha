class PlanUtils {
  static int calculateSelectedDay(DateTime startedAt, int totalDays) {
    final today = DateTime.now();

    // Normalize dates to midnight to compare only date parts (ignore time)
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedStartedAt = DateTime(
      startedAt.year,
      startedAt.month,
      startedAt.day,
    );

    // If today equals startedAt (date-wise), return day 1
    if (normalizedToday.isAtSameMomentAs(normalizedStartedAt)) {
      return 1;
    } else if (normalizedToday.isAfter(normalizedStartedAt)) {
      // Calculate day difference (1-indexed)
      final difference =
          normalizedToday.difference(normalizedStartedAt).inDays + 1;
      if (difference > totalDays) {
        return totalDays;
      } else {
        return difference;
      }
    }

    // If startedAt is in the future
    return 1;
  }
}
