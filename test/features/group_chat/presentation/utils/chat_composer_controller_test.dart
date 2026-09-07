import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_composer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the controller through a real field so `buildTextSpan` runs with a
/// live context, then reads back what it produced.
Future<TextSpan> _spanFor(WidgetTester tester, String text) async {
  final controller = ChatComposerController(text: text);
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: TextField(controller: controller))),
  );
  final field = tester.widget<EditableText>(find.byType(EditableText));
  return controller.buildTextSpan(
    context: tester.element(find.byType(EditableText)),
    style: field.style,
    withComposing: false,
  );
}

void main() {
  group('ChatComposerController', () {
    testWidgets('keeps every typed character, markers included', (
      tester,
    ) async {
      const typed = 'say *hello* and _bye_ and `x` ok';
      final span = await _spanFor(tester, typed);
      // A dropped or duplicated character would put the caret in the wrong
      // place, so this is the invariant that matters most.
      expect(span.toPlainText(), typed);
    });

    testWidgets('styles bold, italic, strike and code', (tester) async {
      final span = await _spanFor(tester, '*b* _i_ ~s~ `c`');
      final styles = <TextStyle>[];
      span.visitChildren((visited) {
        if (visited is TextSpan && visited.style != null) {
          styles.add(visited.style!);
        }
        return true;
      });

      expect(styles.any((s) => s.fontWeight == FontWeight.w700), isTrue);
      expect(styles.any((s) => s.fontStyle == FontStyle.italic), isTrue);
      expect(
        styles.any((s) => s.decoration == TextDecoration.lineThrough),
        isTrue,
      );
      expect(styles.any((s) => s.fontFamily == 'monospace'), isTrue);
    });

    testWidgets('shows a leading dash as a bullet without moving the caret', (
      tester,
    ) async {
      const typed = '- one\n- two';
      final span = await _spanFor(tester, typed);
      // The glyph changes but the length does not, so every offset after it
      // still points at the same character.
      expect(span.toPlainText(), '• one\n• two');
      expect(span.toPlainText().length, typed.length);
    });

    testWidgets('a dash mid-sentence stays a dash', (tester) async {
      const typed = 'a - b';
      final span = await _spanFor(tester, typed);
      expect(span.toPlainText(), typed);
    });

    testWidgets('leaves unmarked text alone', (tester) async {
      const typed = 'just a normal message';
      final span = await _spanFor(tester, typed);
      expect(span.toPlainText(), typed);
    });

    testWidgets('handles an empty field', (tester) async {
      final span = await _spanFor(tester, '');
      expect(span.toPlainText(), '');
    });
  });
}
