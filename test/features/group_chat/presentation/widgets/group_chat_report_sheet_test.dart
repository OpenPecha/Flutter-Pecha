import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_reason.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_report_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the sheet. [onDone] receives whatever it resolves to.
Future<void> _openSheet(
  WidgetTester tester, {
  ValueChanged<ChatReportSubmission?>? onDone,
}) async {
  late BuildContext hostContext;

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          hostContext = context;
          return const Scaffold(body: SizedBox.expand());
        },
      ),
    ),
  );

  // Not awaited: the sheet has to stay open so the test can drive it.
  unawaited(showChatReportSheet(hostContext).then((v) => onDone?.call(v)));
  await tester.pumpAndSettle();
}

bool _submitEnabled(WidgetTester tester) {
  final button = tester.widget<ElevatedButton>(
    find.ancestor(
      of: find.text('Submit report'),
      matching: find.byType(ElevatedButton),
    ),
  );
  return button.onPressed != null;
}

void main() {
  group('showChatReportSheet', () {
    testWidgets('submit stays disabled until a reason is chosen', (
      tester,
    ) async {
      await _openSheet(tester);

      expect(find.text('Why are you reporting this?'), findsOneWidget);
      expect(_submitEnabled(tester), isFalse);

      await tester.tap(find.text('Spam or scams'));
      await tester.pumpAndSettle();

      expect(_submitEnabled(tester), isTrue);
    });

    testWidgets('something else leads to the note step', (tester) async {
      await _openSheet(tester);

      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();

      // The button advances here rather than submitting, so choosing the
      // reason has to be enough to enable it — otherwise the note step is
      // unreachable and the note can never be written.
      expect(_submitEnabled(tester), isTrue);

      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(find.text('Add a note'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('the note step will not submit while empty', (tester) async {
      await _openSheet(tester);
      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(_submitEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), 'they keep insulting');
      await tester.pumpAndSettle();

      expect(_submitEnabled(tester), isTrue);
    });

    testWidgets('whitespace alone is not a note', (tester) async {
      await _openSheet(tester);
      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '    ');
      await tester.pumpAndSettle();

      expect(_submitEnabled(tester), isFalse);
    });

    testWidgets('a plain reason submits outright, with no note', (
      tester,
    ) async {
      ChatReportSubmission? submitted;
      await _openSheet(tester, onDone: (v) => submitted = v);

      await tester.tap(find.text('Harassment or bullying'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      // No note step in the way, and nothing invented to fill one.
      expect(find.text('Add a note'), findsNothing);
      expect(submitted?.reason, ChatReportReason.harassment);
      expect(submitted?.note, isNull);
    });

    testWidgets('the note field stops at the cap', (tester) async {
      await _openSheet(tester);
      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'a' * (kChatReportNoteLimit + 40),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, hasLength(kChatReportNoteLimit));
    });
  });
}
