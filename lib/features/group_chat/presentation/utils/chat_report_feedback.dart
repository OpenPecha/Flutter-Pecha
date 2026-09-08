import 'package:flutter_pecha/core/error/failures.dart';

/// What to tell the member once a report request has settled.
enum ChatReportFeedback { sent, offline, failed }

/// Picks the snackbar for a settled report.
///
/// `NetworkFailure` is too broad to mean "offline" on its own: the error
/// interceptor also raises it for timeouts, cancelled requests, bad
/// certificates and anything Dio files as unknown, all of which happen with a
/// working connection. Only call the failure offline when a live probe
/// agrees; otherwise keep the Retry action, since a second attempt may well
/// go through.
///
/// [isOnline] must be a fresh check, not a cached flag. The request itself
/// never refreshes connectivity state, so a flag that went stale while the
/// app was backgrounded would file every network failure as offline and hide
/// Retry. The probe is only run when a `NetworkFailure` makes it relevant.
Future<ChatReportFeedback> chatReportFeedbackFor(
  Failure? failure, {
  required Future<bool> Function() isOnline,
}) async {
  if (failure == null) return ChatReportFeedback.sent;
  if (failure is NetworkFailure && !await isOnline()) {
    return ChatReportFeedback.offline;
  }
  return ChatReportFeedback.failed;
}
