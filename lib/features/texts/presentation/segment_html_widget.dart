import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SegmentHtmlWidget extends ConsumerStatefulWidget {
  final String htmlContent;
  final int segmentIndex;
  final double fontSize;
  final String language;
  const SegmentHtmlWidget({
    super.key,
    required this.htmlContent,
    required this.segmentIndex,
    required this.fontSize,
    required this.language,
  });

  @override
  ConsumerState<SegmentHtmlWidget> createState() => _SegmentHtmlWidgetState();
}

class _SegmentHtmlWidgetState extends ConsumerState<SegmentHtmlWidget> {
  // Set of visible footnote indices for this segment
  Set<int> visibleFootnotes = {};

  @override
  Widget build(BuildContext context) {
    final lineHeight = widget.language == 'bo' ? 2.0 : 1.5;

    int footnoteCounter = 0;
    return Html(
      data: widget.htmlContent,
      style: {
        ".footnote-marker": Style(
          color: const Color(0xFF007bff),
          fontWeight: FontWeight.w700,
          verticalAlign: VerticalAlign.top,
        ),
        ".footnote": Style(
          fontStyle: FontStyle.italic,
          color: const Color(0xFF8a8a8a),
          margin: Margins.only(left: 4),
          backgroundColor: const Color(0xFFF0F0F0),
          padding: HtmlPaddings.symmetric(horizontal: 5, vertical: 2),
          fontSize: FontSize(widget.fontSize),
        ),
        "body": Style(
          fontSize: FontSize(widget.fontSize),
          lineHeight: LineHeight(lineHeight),
          margin: Margins.zero,
          fontFamily: getFontFamily(widget.language),
          padding: HtmlPaddings.zero,
        ),
        'p': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
      },
      extensions: [
        TagExtension(
          tagsToExtend: {"sup"},
          builder: (context) {
            final element = context.element;
            if ((element?.classes.contains('footnote-marker')) ?? false) {
              final currentIndex = footnoteCounter++;

              return InkWell(
                onTap: () {
                  setState(() {
                    if (visibleFootnotes.contains(currentIndex)) {
                      visibleFootnotes.remove(currentIndex);
                    } else {
                      visibleFootnotes.add(currentIndex);
                    }
                  });
                },
                // Increase the tap target size for better UX
                borderRadius: BorderRadius.circular(4),
                child: Transform.translate(
                  offset: const Offset(0, -6),
                  child: Padding(
                    // Increased padding for larger tap target
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          color: const Color(0xFF007bff),
                          fontWeight: FontWeight.w700,
                          fontSize: widget.fontSize * 0.85,
                        ),
                        child:
                            (context.element?.text ?? '').isNotEmpty
                                ? Text(context.element?.text ?? '')
                                : const Text('*'),
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        TagExtension(
          tagsToExtend: {"i"},
          builder: (context) {
            final element = context.element;
            if ((element?.classes.contains('footnote')) ?? false) {
              final currentIndex = footnoteCounter - 1;
              final isVisible = visibleFootnotes.contains(currentIndex);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child:
                    isVisible
                        ? Container(
                          key: ValueKey('footnote-$currentIndex'),
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: DefaultTextStyle.merge(
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF8a8a8a),
                              fontSize: widget.fontSize,
                            ),
                            child:
                                (context.element?.text ?? '').isNotEmpty
                                    ? Text(context.element?.text ?? '')
                                    : const Text(''),
                          ),
                        )
                        : const SizedBox.shrink(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
