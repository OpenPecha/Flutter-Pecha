import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/share_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/action_button.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
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
  final String? contentId;
  final String segmentId;
  final String language;
  final VoidCallback onClose;
  final VoidCallback? onOpenCommentary;

  const SegmentActionBar({
    required this.text,
    required this.onClose,
    required this.textId,
    this.contentId,
    required this.segmentId,
    required this.language,
    this.onOpenCommentary,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
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
                // commentary button - opens split screen
                ActionButton(
                  icon: Icons.comment_outlined,
                  label: localizations.text_commentary,
                  onTap: () {
                    // Toggle commentary split screen
                    final currentSegmentId = ref.read(
                      commentarySplitSegmentProvider,
                    );
                    if (currentSegmentId == segmentId) {
                      // Close if same segment - also close action bar
                      ref.read(commentarySplitSegmentProvider.notifier).state =
                          null;
                      onClose();
                    } else {
                      // Open for this segment - keep segment highlighted, don't call onClose
                      ref.read(commentarySplitSegmentProvider.notifier).state =
                          segmentId;
                      // Scroll to segment after a short delay to allow layout to update
                      Future.delayed(const Duration(milliseconds: 100), () {
                        onOpenCommentary?.call();
                      });
                    }
                  },
                ),
                ActionButton(
                  icon: Icons.copy,
                  label: localizations.copy,
                  onTap: () {
                    final textWithLineBreaks = text.replaceAll("<br>", "\n");
                    final plainText = htmlToPlainText(textWithLineBreaks);
                    Clipboard.setData(ClipboardData(text: plainText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.copied)),
                    );
                    onClose();
                  },
                ),
                _ShareButton(
                  textId: textId,
                  segmentId: segmentId,
                  language: language,
                  onClose: onClose,
                ),
                ActionButton(
                  icon: Icons.image_outlined,
                  label: localizations.image,
                  onTap: () {
                    final textWithLineBreaks = text.replaceAll("<br>", "\n");
                    final plainText = htmlToPlainText(textWithLineBreaks);
                    final cutText =
                        plainText.length > 180
                            ? plainText.substring(0, 180)
                            : plainText;
                    context.push(
                      '/texts/segment_image/choose_image',
                      extra: cutText,
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

/// Share button that generates short URL on tap and shows loading state
class _ShareButton extends ConsumerStatefulWidget {
  final String textId;
  final String segmentId;
  final String language;
  final VoidCallback onClose;

  const _ShareButton({
    required this.textId,
    required this.segmentId,
    required this.language,
    required this.onClose,
  });

  @override
  ConsumerState<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends ConsumerState<_ShareButton> {
  bool _isLoading = false;

  Future<void> _handleShare() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate the short URL
      final params = ShareUrlParams(
        textId: widget.textId,
        segmentId: widget.segmentId,
        language: widget.language,
      );
      final shortUrl = await ref.read(shareUrlProvider(params).future);

      if (!mounted) return;

      // Share the URL using native share
      final sharePositionOrigin = getSharePositionOrigin(context: context);
      await SharePlus.instance.share(
        ShareParams(text: shortUrl, sharePositionOrigin: sharePositionOrigin),
      );
      widget.onClose();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to share: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 4),
            Text(localizations.share, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    return ActionButton(
      icon: Icons.share,
      label: localizations.share,
      onTap: _handleShare,
    );
  }
}
