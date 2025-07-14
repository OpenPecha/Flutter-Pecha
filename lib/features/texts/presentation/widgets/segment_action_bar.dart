import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/features/texts/data/providers/share_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/action_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class SegmentActionBar extends ConsumerWidget {
  final String text;
  final String textId;
  final String contentId;
  final String segmentId;
  final String language;
  final VoidCallback onClose;

  const SegmentActionBar({
    required this.text,
    required this.onClose,
    required this.textId,
    required this.contentId,
    required this.segmentId,
    required this.language,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).cardColor,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // commentary button
                ActionButton(
                  icon: Icons.comment_outlined,
                  label: 'Commentary',
                  onTap: () {
                    context.push('/texts/commentary', extra: segmentId);
                  },
                ),
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
                Consumer(
                  builder: (context, ref, child) {
                    final shareParams = ShareUrlParams(
                      textId: textId,
                      contentId: contentId,
                      segmentId: segmentId,
                      language: language,
                    );

                    final shareUrlAsync = ref.watch(
                      shareUrlProvider(shareParams),
                    );

                    return shareUrlAsync.when(
                      data:
                          (shortUrl) => ActionButton(
                            icon: Icons.share,
                            label: 'Share',
                            onTap: () async {
                              try {
                                await SharePlus.instance.share(
                                  ShareParams(text: shortUrl),
                                );
                                onClose();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to share: ${e.toString()}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                      loading:
                          () => ActionButton(
                            icon: Icons.share,
                            label: 'Loading...',
                            onTap: () {
                              // Show loading indicator
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Generating share link...'),
                                ),
                              );
                            },
                          ),
                      error:
                          (error, stack) => ActionButton(
                            icon: Icons.share,
                            label: 'Error',
                            onTap: () {
                              // Retry the share operation
                              ref.invalidate(shareUrlProvider(shareParams));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Retrying... ${error.toString()}',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                          ),
                    );
                  },
                ),
                ActionButton(
                  icon: Icons.image_outlined,
                  label: 'Image',
                  onTap: () {
                    final textWithLineBreaks = text.replaceAll("<br>", "\n");
                    final plainText = htmlToPlainText(textWithLineBreaks);
                    context.push(
                      '/texts/segment_image/choose_image',
                      extra: plainText,
                    );
                    onClose();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
