import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_message_blocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chatBodyNeedsBlocks', () {
    test('is false for an ordinary message', () {
      expect(chatBodyNeedsBlocks('hi everyone'), isFalse);
      // A dash mid-sentence, and one with no space, are both just text.
      expect(chatBodyNeedsBlocks('a - b'), isFalse);
      expect(chatBodyNeedsBlocks('-nope'), isFalse);
      expect(chatBodyNeedsBlocks('2025 was good'), isFalse);
    });

    test('is true for any marker', () {
      expect(chatBodyNeedsBlocks('- one'), isTrue);
      expect(chatBodyNeedsBlocks('* one'), isTrue);
      expect(chatBodyNeedsBlocks('1. one'), isTrue);
      expect(chatBodyNeedsBlocks('2) one'), isTrue);
      expect(chatBodyNeedsBlocks('> quoted'), isTrue);
      expect(chatBodyNeedsBlocks('```\ncode\n```'), isTrue);
    });
  });

  group('parseChatMessageBlocks', () {
    test('keeps a plain body as one block', () {
      final blocks = parseChatMessageBlocks('hello\nthere');
      expect(blocks, hasLength(1));
      expect(blocks.single.text, 'hello\nthere');
      expect(blocks.single.kind, ChatBlockKind.paragraph);
    });

    test('strips the marker from each bullet', () {
      final blocks = parseChatMessageBlocks('- one\n- two');
      expect(blocks.map((b) => b.text).toList(), ['one', 'two']);
      expect(blocks.every((b) => b.kind == ChatBlockKind.bullet), isTrue);
    });

    test('keeps the number the author typed', () {
      final blocks = parseChatMessageBlocks('1. one\n2) two');
      expect(blocks.map((b) => b.kind).toList(), [
        ChatBlockKind.numbered,
        ChatBlockKind.numbered,
      ]);
      expect(blocks.map((b) => b.marker).toList(), ['1.', '2.']);
      expect(blocks.map((b) => b.text).toList(), ['one', 'two']);
    });

    test('reads a block quote', () {
      final blocks = parseChatMessageBlocks('> quoted');
      expect(blocks.single.kind, ChatBlockKind.quote);
      expect(blocks.single.text, 'quoted');
    });

    test('reads a fenced block and keeps its lines verbatim', () {
      final blocks = parseChatMessageBlocks('before\n```\na = 1\n\nb = 2\n```');
      expect(blocks.map((b) => b.kind).toList(), [
        ChatBlockKind.paragraph,
        ChatBlockKind.code,
      ]);
      expect(blocks.last.text, 'a = 1\n\nb = 2');
    });

    test('an unterminated fence stays literal text', () {
      final blocks = parseChatMessageBlocks('```\nstill typing');
      expect(blocks.single.kind, ChatBlockKind.paragraph);
      expect(blocks.single.text, '```\nstill typing');
    });

    test('splits a paragraph from the markers that follow it', () {
      final blocks = parseChatMessageBlocks('plan:\n- one\nthanks');
      expect(blocks.map((b) => b.kind).toList(), [
        ChatBlockKind.paragraph,
        ChatBlockKind.bullet,
        ChatBlockKind.paragraph,
      ]);
      expect(blocks.last.text, 'thanks');
    });

    test('an empty body still yields one block', () {
      expect(parseChatMessageBlocks('').single.text, '');
    });
  });
}
