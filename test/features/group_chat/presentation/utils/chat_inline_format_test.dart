import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_inline_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chatTextHasInlineMarkers', () {
    test('is false for ordinary prose', () {
      expect(chatTextHasInlineMarkers('hi everyone'), isFalse);
      // Spaced markers are punctuation, not formatting.
      expect(chatTextHasInlineMarkers('2 * 3 * 4'), isFalse);
      expect(chatTextHasInlineMarkers('snake_case_name'), isTrue);
    });

    test('is true for a real marker', () {
      expect(chatTextHasInlineMarkers('*bold*'), isTrue);
      expect(chatTextHasInlineMarkers('`code`'), isTrue);
    });
  });

  group('parseChatInlineRuns', () {
    test('marks bold, italic and strikethrough', () {
      expect(parseChatInlineRuns('*b*').single.bold, isTrue);
      expect(parseChatInlineRuns('_i_').single.italic, isTrue);
      expect(parseChatInlineRuns('~s~').single.strike, isTrue);
    });

    test('drops the markers from the rendered text', () {
      final runs = parseChatInlineRuns('say *hello* now');
      expect(runs.map((r) => r.text).join(), 'say hello now');
    });

    test('nests styles', () {
      final runs = parseChatInlineRuns('*bold _and italic_*');
      final nested = runs.firstWhere((r) => r.italic);
      expect(nested.bold, isTrue);
      expect(nested.text, 'and italic');
    });

    test('takes code literally', () {
      final runs = parseChatInlineRuns('run `a *b* c` now');
      final code = runs.firstWhere((r) => r.code);
      expect(code.text, 'a *b* c');
      expect(code.bold, isFalse);
    });

    test('leaves spaced markers alone', () {
      final runs = parseChatInlineRuns('2 * 3 * 4');
      expect(runs.single.bold, isFalse);
      expect(runs.single.text, '2 * 3 * 4');
    });

    test('an empty body yields nothing', () {
      expect(parseChatInlineRuns(''), isEmpty);
    });
  });
}
