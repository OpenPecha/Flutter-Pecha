import 'package:flutter/services.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_list_continuation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The value a field holds after Return is pressed at the end of [text].
({TextEditingValue oldValue, TextEditingValue newValue}) _pressReturn(
  String text,
) {
  return (
    oldValue: TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
    newValue: TextEditingValue(
      text: '$text\n',
      selection: TextSelection.collapsed(offset: text.length + 1),
    ),
  );
}

TextEditingValue _afterReturn(String text) {
  final press = _pressReturn(text);
  return applyChatListContinuation(press.oldValue, press.newValue);
}

void main() {
  group('applyChatListContinuation', () {
    test('carries a bullet to the next line', () {
      final result = _afterReturn('- one');
      expect(result.text, '- one\n- ');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('keeps the marker the author used', () {
      expect(_afterReturn('* one').text, '* one\n* ');
      expect(_afterReturn('• one').text, '• one\n• ');
    });

    test('increments a numbered item', () {
      expect(_afterReturn('1. one').text, '1. one\n2. ');
      expect(_afterReturn('4) four').text, '4) four\n5) ');
    });

    test('repeats a block quote', () {
      expect(_afterReturn('> quoted').text, '> quoted\n> ');
    });

    test('preserves the leading indent', () {
      expect(_afterReturn('  - one').text, '  - one\n  - ');
    });

    test('a second Return on an empty item ends the list', () {
      final result = _afterReturn('- one\n- ');
      expect(result.text, '- one\n');
      // The caret sits on the now-empty line, not after a stray newline.
      expect(result.selection.baseOffset, '- one\n'.length);
    });

    test('an empty numbered item ends the list too', () {
      expect(_afterReturn('1. one\n2. ').text, '1. one\n');
    });

    test('leaves ordinary lines alone', () {
      expect(_afterReturn('hello').text, 'hello\n');
      expect(_afterReturn('a - b').text, 'a - b\n');
    });

    test('ignores anything that is not a single typed newline', () {
      const oldValue = TextEditingValue(
        text: '- one',
        selection: TextSelection.collapsed(offset: 5),
      );
      // A paste, not a Return.
      const pasted = TextEditingValue(
        text: '- one and more',
        selection: TextSelection.collapsed(offset: 14),
      );
      expect(applyChatListContinuation(oldValue, pasted), pasted);
    });
  });
}
