import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_message_bubble.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders [body] and returns the text the spans actually paint.
Future<InlineSpan> _spansFor(WidgetTester tester, String body) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChatFormattedText(
          body: body,
          textColor: const Color(0xFF000000),
          isDark: false,
        ),
      ),
    ),
  );
  final text = tester.widget<Text>(find.byType(Text));
  return text.textSpan ?? TextSpan(text: text.data);
}

/// Every URL that carries a recognizer, as painted.
List<String> _linkTexts(InlineSpan root) {
  final links = <String>[];
  root.visitChildren((span) {
    if (span is TextSpan && span.recognizer is TapGestureRecognizer) {
      links.add(span.toPlainText());
    }
    return true;
  });
  return links;
}

void main() {
  group('ChatFormattedText keeps URLs intact', () {
    // Inline markers used to be parsed before links were found, so the marker
    // characters inside a URL were eaten and only the prefix before the first
    // one stayed tappable.
    const cases = <String>[
      'see https://ex.com/a_b_c page',
      'https://en.wikipedia.org/wiki/Foo_(bar)_baz',
      'https://ex.com/x?a=*b*&c=1',
      'read https://ex.com/a~b~c now',
    ];

    for (final body in cases) {
      testWidgets(body, (tester) async {
        final span = await _spansFor(tester, body);
        expect(span.toPlainText(), body);
      });
    }

    testWidgets('the whole URL stays tappable, not just its prefix', (
      tester,
    ) async {
      const url = 'https://en.wikipedia.org/wiki/Foo_(bar)_baz';
      final span = await _spansFor(tester, 'look at $url ok');
      expect(_linkTexts(span), [url]);
    });

    testWidgets('markers outside a URL are still stripped and styled', (
      tester,
    ) async {
      // Only URLs are exempt from marker parsing; the bubble still renders
      // `*bold*` as bold text with the marks removed.
      final span = await _spansFor(tester, 'a *bold* word');
      expect(span.toPlainText(), 'a bold word');
      expect(_linkTexts(span), isEmpty);

      final weights = <FontWeight?>[];
      span.visitChildren((child) {
        if (child is TextSpan && child.toPlainText() == 'bold') {
          weights.add(child.style?.fontWeight);
        }
        return true;
      });
      expect(weights, [FontWeight.w700]);
    });

    testWidgets('a marker pair spanning a URL leaves the URL alone', (
      tester,
    ) async {
      const url = 'https://ex.com/a_b_c';
      final span = await _spansFor(tester, 'x $url y');
      expect(span.toPlainText(), 'x $url y');
      expect(_linkTexts(span), [url]);
    });

    testWidgets('plain text takes the cheap path', (tester) async {
      final span = await _spansFor(tester, 'nothing special here');
      expect(span.toPlainText(), 'nothing special here');
    });
  });
}
