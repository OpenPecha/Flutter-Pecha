/// A URL found inside a message body.
class ChatLinkMatch {
  final int start;
  final int end;
  final String text;

  const ChatLinkMatch({
    required this.start,
    required this.end,
    required this.text,
  });

  /// The text with a scheme attached, ready for `launchUrl`. Bare `www.` hosts
  /// are rendered as typed but opened over https.
  String get url =>
      text.startsWith(RegExp(r'https?://', caseSensitive: false))
          ? text
          : 'https://$text';
}

final _urlPattern = RegExp(r'(?:https?://|www\.)[^\s<]+', caseSensitive: false);

/// Trailing characters that are almost always sentence punctuation rather than
/// part of the URL.
const _trailingPunctuation = '.,;:!?…"\'”’>';

/// Finds the URLs in [body], in order, with sentence punctuation trimmed off
/// the tail. Pure so linkification can be tested without a widget tree.
List<ChatLinkMatch> findChatLinks(String body) {
  final matches = <ChatLinkMatch>[];

  for (final match in _urlPattern.allMatches(body)) {
    var text = match.group(0)!;
    var end = match.end;

    while (text.isNotEmpty && _isTrimmableTail(text)) {
      text = text.substring(0, text.length - 1);
      end--;
    }

    // A bare scheme or host with nothing after it is not worth linking.
    if (text.isEmpty || text.endsWith('//') || !text.contains('.')) continue;

    matches.add(ChatLinkMatch(start: match.start, end: end, text: text));
  }

  return matches;
}

/// The first linkable URL in [body], or null. Drives the unfurl card.
String? firstChatLinkUrl(String body) {
  final links = findChatLinks(body);
  return links.isEmpty ? null : links.first.url;
}

bool _isTrimmableTail(String text) {
  final last = text[text.length - 1];
  if (_trailingPunctuation.contains(last)) return true;
  // Keep a closing bracket only when the URL opened one itself.
  if (last == ')') return _count(text, '(') <= _count(text, ')') - 1;
  if (last == ']') return _count(text, '[') <= _count(text, ']') - 1;
  return false;
}

int _count(String text, String char) {
  var total = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == char) total++;
  }
  return total;
}
