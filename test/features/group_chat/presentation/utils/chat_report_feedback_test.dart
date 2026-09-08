import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chatReportFeedbackFor', () {
    test('no failure means the report was sent', () {
      expect(
        chatReportFeedbackFor(null, isOnline: true),
        ChatReportFeedback.sent,
      );
      expect(
        chatReportFeedbackFor(null, isOnline: false),
        ChatReportFeedback.sent,
      );
    });

    test('a network failure while offline is reported as offline', () {
      expect(
        chatReportFeedbackFor(
          const NetworkFailure('reportMessage: No internet connection'),
          isOnline: false,
        ),
        ChatReportFeedback.offline,
      );
    });

    test('a network failure while online keeps the retry path', () {
      // The interceptor files timeouts, cancels, bad certificates and unknown
      // errors under NetworkFailure too; none of those mean the user is
      // offline.
      for (final message in const [
        'reportMessage: Connection timeout',
        'reportMessage: Request cancelled',
        'reportMessage: Invalid SSL certificate',
        'reportMessage: Unknown error: something',
      ]) {
        expect(
          chatReportFeedbackFor(NetworkFailure(message), isOnline: true),
          ChatReportFeedback.failed,
          reason: message,
        );
      }
    });

    test('any other failure keeps the retry path, online or not', () {
      for (final failure in const <Failure>[
        ServerFailure('reportMessage: 500'),
        NotFoundFailure('reportMessage: 404'),
        UnknownFailure('reportMessage: boom'),
      ]) {
        expect(
          chatReportFeedbackFor(failure, isOnline: true),
          ChatReportFeedback.failed,
        );
        expect(
          chatReportFeedbackFor(failure, isOnline: false),
          ChatReportFeedback.failed,
        );
      }
    });
  });
}
