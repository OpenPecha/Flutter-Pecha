import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:intl/intl.dart';

/// Formats timestamps for social feed cards (e.g. "2h", "Mar 12").
abstract final class ConnectRelativeTime {
  static String format(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return '';

    final local = dateTime.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.isNegative || diff.inMinutes < 1) {
      return 'now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d';
    }

    final locale = intlFormatLocaleOf(context);
    if (local.year == now.year) {
      return DateFormat('MMM d', locale).format(local);
    }
    return DateFormat('MMM d, y', locale).format(local);
  }
}
