/// How a line of a message body is laid out.
enum ChatBlockKind {
  /// Ordinary text. Consecutive plain lines share one block.
  paragraph,

  /// `- text`, `* text` or `• text`.
  bullet,

  /// `1. text` or `1) text`, keeping the number the author typed.
  numbered,

  /// `> text`, rendered with a rule down the leading edge.
  quote,

  /// A ``` fenced ``` run, rendered monospace with no inline formatting.
  code,
}

class ChatTextBlock {
  final String text;
  final ChatBlockKind kind;

  /// The rendered marker for [ChatBlockKind.numbered] — `1.`, `2.` and so on.
  final String? marker;

  const ChatTextBlock({
    required this.text,
    this.kind = ChatBlockKind.paragraph,
    this.marker,
  });

  bool get isBullet => kind == ChatBlockKind.bullet;
}

final _bulletPattern = RegExp(r'^[ \t]*[-*•][ \t]+');
final _numberedPattern = RegExp(r'^[ \t]*(\d{1,3})[.)][ \t]+');
final _quotePattern = RegExp(r'^[ \t]*>[ \t]?');
final _fencePattern = RegExp(r'^[ \t]*```[ \t]*$');

/// Splits a body into the blocks it renders as.
///
/// Consecutive plain lines stay in one block so blank lines and wrapping
/// behave as typed; every marked line becomes its own block so it can be laid
/// out with a hanging indent rather than the marker being swallowed into the
/// text. Pure, so the parsing is testable without a widget tree.
List<ChatTextBlock> parseChatMessageBlocks(String body) {
  if (body.isEmpty) return const [ChatTextBlock(text: '')];

  final blocks = <ChatTextBlock>[];
  final paragraph = <String>[];
  final fenced = <String>[];
  var inFence = false;

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add(ChatTextBlock(text: paragraph.join('\n')));
    paragraph.clear();
  }

  for (final line in body.split('\n')) {
    if (_fencePattern.hasMatch(line)) {
      if (inFence) {
        blocks.add(
          ChatTextBlock(text: fenced.join('\n'), kind: ChatBlockKind.code),
        );
        fenced.clear();
        inFence = false;
      } else {
        flushParagraph();
        inFence = true;
      }
      continue;
    }
    if (inFence) {
      fenced.add(line);
      continue;
    }

    final bullet = _bulletPattern.firstMatch(line);
    if (bullet != null) {
      flushParagraph();
      blocks.add(
        ChatTextBlock(
          text: line.substring(bullet.end),
          kind: ChatBlockKind.bullet,
        ),
      );
      continue;
    }

    final numbered = _numberedPattern.firstMatch(line);
    if (numbered != null) {
      flushParagraph();
      blocks.add(
        ChatTextBlock(
          text: line.substring(numbered.end),
          kind: ChatBlockKind.numbered,
          marker: '${numbered.group(1)}.',
        ),
      );
      continue;
    }

    final quote = _quotePattern.firstMatch(line);
    if (quote != null) {
      flushParagraph();
      blocks.add(
        ChatTextBlock(
          text: line.substring(quote.end),
          kind: ChatBlockKind.quote,
        ),
      );
      continue;
    }

    paragraph.add(line);
  }

  // An unterminated fence is text the author typed, not a block.
  if (inFence) {
    paragraph.addAll(['```', ...fenced]);
  }
  flushParagraph();

  return blocks.isEmpty ? const [ChatTextBlock(text: '')] : blocks;
}

/// Whether [body] needs block layout at all. A message without markers stays
/// on the cheaper single-[Text] path.
bool chatBodyNeedsBlocks(String body) {
  return body
      .split('\n')
      .any(
        (line) =>
            _bulletPattern.hasMatch(line) ||
            _numberedPattern.hasMatch(line) ||
            _quotePattern.hasMatch(line) ||
            _fencePattern.hasMatch(line),
      );
}
