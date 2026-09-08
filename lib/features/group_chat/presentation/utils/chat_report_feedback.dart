import 'package:flutter_pecha/core/error/failures.dart';

/// What to tell the member once a report request has settled.
enum ChatReportFeedback { sent, offline, failed }

/// Picks the snackbar for a settled report.
///
/// `NetworkFailure` is too broad to mean "offline" on its own: the error
/// interceptor also raises it for timeouts, cancelled requests, bad
/// certificates and anything Dio files as unknown, all of which happen with a
/// working connection. Only call the failure offline when the connectivity
/// service agrees; otherwise keep the Retry action, since a second attempt
/// may well go through.
ChatReportFeedback chatReportFeedbackFor(
  Failure? failure, {
  required bool isOnline,
}) {
  if (failure == null) return ChatReportFeedback.sent;
  if (failure is NetworkFailure && !isOnline) {
    return ChatReportFeedback.offline;
  }
  return ChatReportFeedback.failed;
}
