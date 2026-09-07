/// A stretch of message text sharing one set of inline styles.
class ChatInlineRun {
  final String text;
  final bool bold;
  final bool italic;
  final bool strike;

  /// Inline `code`. Nothing inside is formatted further, and links are not
  /// detected in it.
  final bool code;

  const ChatInlineRun({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.strike = false,
    this.code = false,
  });
}

/// The markers, in the order they are looked for. Each captures content that
/// neither begins nor ends with a space, so `a * b * c` stays as typed and only
/// a deliberate `*bold*` is styled — the same rule WhatsApp applies.
final _code = RegExp(r'`([^`\n]+)`');
final _bold = RegExp(r'\*(\S(?:[^*\n]*\S)?)\*');
final _italic = RegExp(r'_(\S(?:[^_\n]*\S)?)_');
final _strike = RegExp(r'~(\S(?:[^~\n]*\S)?)~');

/// Which marker opened a match.
enum ChatInlineMarker { code, bold, italic, strike }

/// The first inline marker in [text], wherever it opens.
///
/// Shared by the two consumers that need different things from it: the bubble
/// strips markers, while the composer has to keep every character so the caret
/// stays where the typist put it.
class ChatInlineMatch {
  final ChatInlineMarker marker;

  /// Offsets into the string that was searched — [start] is the opening marker
  /// and [end] is one past the closing one.
  final int start;
  final int end;

  /// The text between the markers, and where it begins.
  final String content;
  final int contentStart;

  const ChatInlineMatch({
    required this.marker,
    required this.start,
    required this.end,
    required this.content,
    required this.contentStart,
  });
}

ChatInlineMatch? firstChatInlineMatch(String text) {
  final markers = {
    ChatInlineMarker.code: _code,
    ChatInlineMarker.bold: _bold,
    ChatInlineMarker.italic: _italic,
    ChatInlineMarker.strike: _strike,
  };

  ChatInlineMatch? earliest;
  markers.forEach((marker, pattern) {
    final match = pattern.firstMatch(text);
    if (match == null) return;
    if (earliest != null && match.start >= earliest!.start) return;
    earliest = ChatInlineMatch(
      marker: marker,
      start: match.start,
      end: match.end,
      content: match.group(1)!,
      contentStart: match.start + 1,
    );
  });
  return earliest;
}

/// Splits [text] into styled runs.
///
/// Markers nest — `*bold _and italic_*` yields a run carrying both — except
/// inside `code`, which is taken literally. Pure, so the grammar is testable
/// without a widget tree.
List<ChatInlineRun> parseChatInlineRuns(
  String text, {
  bool bold = false,
  bool italic = false,
  bool strike = false,
}) {
  if (text.isEmpty) return const [];

  // Whichever marker opens first wins, so the runs come out in reading order.
  final earliest = firstChatInlineMatch(text);

  if (earliest == null) {
    return [
      ChatInlineRun(text: text, bold: bold, italic: italic, strike: strike),
    ];
  }

  final runs = <ChatInlineRun>[];
  if (earliest.start > 0) {
    runs.add(
      ChatInlineRun(
        text: text.substring(0, earliest.start),
        bold: bold,
        italic: italic,
        strike: strike,
      ),
    );
  }

  final content = earliest.content;
  if (earliest.marker == ChatInlineMarker.code) {
    // Literal: no nesting, no links.
    runs.add(
      ChatInlineRun(
        text: content,
        bold: bold,
        italic: italic,
        strike: strike,
        code: true,
      ),
    );
  } else {
    runs.addAll(
      parseChatInlineRuns(
        content,
        bold: bold || earliest.marker == ChatInlineMarker.bold,
        italic: italic || earliest.marker == ChatInlineMarker.italic,
        strike: strike || earliest.marker == ChatInlineMarker.strike,
      ),
    );
  }

  final rest = text.substring(earliest.end);
  if (rest.isNotEmpty) {
    runs.addAll(
      parseChatInlineRuns(rest, bold: bold, italic: italic, strike: strike),
    );
  }
  return runs;
}

/// Whether [text] carries any inline marker, so a plain message can skip the
/// parse entirely.
bool chatTextHasInlineMarkers(String text) {
  return _code.hasMatch(text) ||
      _bold.hasMatch(text) ||
      _italic.hasMatch(text) ||
      _strike.hasMatch(text);
}
