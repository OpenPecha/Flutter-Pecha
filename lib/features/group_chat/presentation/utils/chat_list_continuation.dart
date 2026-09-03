import 'package:flutter/services.dart';

/// The marker opening a list line, and what the next line's marker should be.
class _ListMarker {
  /// How many characters the marker occupies, including its trailing space.
  final int length;

  /// What to put on the following line, or null when the item is empty and the
  /// list should end instead.
  final String next;

  const _ListMarker({required this.length, required this.next});
}

final _bullet = RegExp(r'^([ \t]*)([-*•])([ \t]+)');
final _numbered = RegExp(r'^([ \t]*)(\d{1,3})([.)])([ \t]+)');
final _quote = RegExp(r'^([ \t]*)>([ \t]?)');

_ListMarker? _markerFor(String line) {
  final bullet = _bullet.firstMatch(line);
  if (bullet != null) {
    return _ListMarker(
      length: bullet.end,
      next: '${bullet.group(1)}${bullet.group(2)}${bullet.group(3)}',
    );
  }

  final numbered = _numbered.firstMatch(line);
  if (numbered != null) {
    final value = int.tryParse(numbered.group(2)!) ?? 0;
    return _ListMarker(
      length: numbered.end,
      next:
          '${numbered.group(1)}${value + 1}${numbered.group(3)}'
          '${numbered.group(4)}',
    );
  }

  final quote = _quote.firstMatch(line);
  if (quote != null) {
    return _ListMarker(
      length: quote.end,
      next: '${quote.group(1)}>${quote.group(2)}',
    );
  }

  return null;
}

/// Carries a list on to the next line when Return is pressed inside one.
///
/// Return on an item with text continues the list — a bullet repeats, a number
/// increments, a quote repeats. Return on an **empty** item ends the list
/// instead: the marker is removed and no line is added, which is the second
/// press people expect to get them out.
///
/// Pure, so the offset arithmetic is testable without a keyboard.
TextEditingValue applyChatListContinuation(
  TextEditingValue oldValue,
  TextEditingValue newValue,
) {
  // Only a single typed newline is interesting; paste and deletion are not.
  if (newValue.text.length != oldValue.text.length + 1) return newValue;
  final caret = newValue.selection.baseOffset;
  if (caret <= 0 || !newValue.selection.isCollapsed) return newValue;
  final inserted = caret - 1;
  if (inserted >= newValue.text.length) return newValue;
  if (newValue.text[inserted] != '\n') return newValue;

  final before = newValue.text.substring(0, inserted);
  final lineStart = before.lastIndexOf('\n') + 1;
  final line = before.substring(lineStart);

  final marker = _markerFor(line);
  if (marker == null) return newValue;

  // An empty item: drop the marker and swallow the newline.
  if (line.length == marker.length) {
    final text =
        oldValue.text.substring(0, lineStart) +
        oldValue.text.substring(inserted);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: lineStart),
    );
  }

  final text =
      newValue.text.substring(0, caret) +
      marker.next +
      newValue.text.substring(caret);
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: caret + marker.next.length),
  );
}

/// Applies [applyChatListContinuation] as the field is edited.
class ChatListContinuationFormatter extends TextInputFormatter {
  const ChatListContinuationFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return applyChatListContinuation(oldValue, newValue);
  }
}
