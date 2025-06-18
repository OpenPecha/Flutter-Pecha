import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/action_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html/parser.dart' as html_parser;

String htmlToPlainText(String htmlString) {
  // Remove specific HTML elements with their content
  String cleanedHtml = removeHtmlElementsWithContent(
    htmlString,
    ['sup', 'i'], // Add more tags as needed
  );
  final document = html_parser.parse(cleanedHtml);
  return document.body?.text ?? '';
}

String removeHtmlElementsWithContent(String html, List<String> tagsToRemove) {
  String result = html;

  for (String tag in tagsToRemove) {
    // Create regex pattern to match opening and closing tags with content
    // This pattern matches: <tag>...</tag> or <tag attributes>...</tag>
    RegExp regex = RegExp(
      '<$tag(?:\\s[^>]*)?>.*?<\\/$tag>',
      caseSensitive: false,
      dotAll: true, // Makes . match newlines too
    );

    result = result.replaceAll(regex, '');
  }

  return result;
}

class SegmentActionBar extends StatelessWidget {
  final String text;
  final VoidCallback onClose;
  const SegmentActionBar({
    required this.text,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ActionButton(
                icon: Icons.copy,
                label: 'Copy',
                onTap: () {
                  final textWithLineBreaks = text.replaceAll("<br>", "\n");
                  final plainText = htmlToPlainText(textWithLineBreaks);
                  Clipboard.setData(ClipboardData(text: plainText));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Copied!')));
                  onClose();
                },
              ),
              ActionButton(
                icon: Icons.share,
                label: 'Share',
                onTap: () {
                  final textWithLineBreaks = text.replaceAll("<br>", "\n");
                  final plainText = htmlToPlainText(textWithLineBreaks);
                  final webUrl =
                      "https://pecha-frontend-12552055234-4f99e0e.onrender.com/";
                  SharePlus.instance.share(
                    ShareParams(text: "$plainText\n$webUrl"),
                  );
                  onClose();
                },
              ),
              ActionButton(
                icon: Icons.image,
                label: 'Image',
                onTap: () {
                  // TODO: Implement image export
                  onClose();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
