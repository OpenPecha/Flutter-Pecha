import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_inline_format.dart';

/// A dash or star opening a line: the marker itself is capture 2, so it can be
/// swapped for a bullet without disturbing the indent or the space after it.
final _bulletLine = RegExp(r'^([ \t]*)([-*])([ \t]+)');

/// A message field that styles `*bold*`, `_italic_`, `~strike~`, `` `code` ``
/// and leading `- ` bullets as they are typed.
///
/// Every character is preserved: the span tree a controller returns must cover
/// exactly the same text as [text], or the caret and selection land in the
/// wrong place. Markers stay visible but dimmed, and the bullet is a
/// one-for-one glyph swap rather than a substitution of a different length.
class ChatComposerController extends TextEditingController {
  ChatComposerController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Styling runs even while an IME is composing. Deferring to the default
    // renderer there sounds tidier, but soft keyboards hold a composing region
    // open for almost every word, so it meant the formatting practically never
    // appeared. The cost is the composing underline, which the keyboard's own
    // candidate bar already conveys.
    final base = style ?? const TextStyle();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextSpan(style: base, children: _lines(text, base, isDark));
  }

  /// Renders a leading `-` or `*` as a bullet, line by line.
  ///
  /// The glyph is swapped, not the text: one character for one, so every offset
  /// after it is unchanged. The message still sends the dash the author typed,
  /// which is what the bubble parses back into a bullet.
  List<InlineSpan> _lines(String text, TextStyle style, bool isDark) {
    final lines = text.split('\n');
    final spans = <InlineSpan>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final bullet = _bulletLine.firstMatch(line);

      if (bullet == null) {
        spans.addAll(_spans(line, style, isDark));
      } else {
        final indent = bullet.group(1)!;
        if (indent.isNotEmpty) {
          spans.add(TextSpan(text: indent, style: style));
        }
        spans.add(TextSpan(text: '•', style: style));
        spans.add(TextSpan(text: bullet.group(3)!, style: style));
        spans.addAll(_spans(line.substring(bullet.end), style, isDark));
      }

      if (i < lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: style));
      }
    }

    return spans;
  }

  List<InlineSpan> _spans(String text, TextStyle style, bool isDark) {
    if (text.isEmpty) return const [];

    final match = firstChatInlineMatch(text);
    if (match == null) return [TextSpan(text: text, style: style)];

    final spans = <InlineSpan>[];
    if (match.start > 0) {
      spans.add(TextSpan(text: text.substring(0, match.start), style: style));
    }

    if (match.marker == ChatInlineMarker.code) {
      // Backticks included, so the caret still maps one-to-one.
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: style.copyWith(
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Courier New', 'Courier'],
            backgroundColor:
                isDark
                    ? AppColors.surfaceWhite.withValues(alpha: 0.08)
                    : AppColors.textPrimary.withValues(alpha: 0.06),
          ),
        ),
      );
    } else {
      final marked = switch (match.marker) {
        ChatInlineMarker.bold => style.copyWith(fontWeight: FontWeight.w700),
        ChatInlineMarker.italic => style.copyWith(fontStyle: FontStyle.italic),
        ChatInlineMarker.strike => style.copyWith(
          decoration: TextDecoration.lineThrough,
        ),
        ChatInlineMarker.code => style,
      };
      final dimmed = marked.copyWith(
        color: (marked.color ?? AppColors.textSecondary).withValues(alpha: 0.4),
      );
      final opening = text.substring(match.start, match.contentStart);
      final closing = text.substring(
        match.contentStart + match.content.length,
        match.end,
      );

      spans.add(
        TextSpan(
          style: marked,
          children: [
            // The markers are dimmed rather than hidden: removing them would
            // desynchronise the caret from the text being edited.
            TextSpan(text: opening, style: dimmed),
            ..._spans(match.content, marked, isDark),
            TextSpan(text: closing, style: dimmed),
          ],
        ),
      );
    }

    final rest = text.substring(match.end);
    if (rest.isNotEmpty) spans.addAll(_spans(rest, style, isDark));
    return spans;
  }
}
