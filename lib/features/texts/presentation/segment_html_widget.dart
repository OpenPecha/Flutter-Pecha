import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class SegmentHtmlWidget extends StatefulWidget {
  final String htmlContent;
  final int segmentIndex;
  const SegmentHtmlWidget({
    super.key,
    required this.htmlContent,
    required this.segmentIndex,
  });

  @override
  State<SegmentHtmlWidget> createState() => _SegmentHtmlWidgetState();
}

class _SegmentHtmlWidgetState extends State<SegmentHtmlWidget> {
  // Set of visible footnote indices for this segment
  Set<int> visibleFootnotes = {};

  @override
  Widget build(BuildContext context) {
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
        ),
        "body": Style(
          fontSize: FontSize(16),
          lineHeight: LineHeight(1.8),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
      },
      extensions: [
        TagExtension(
          tagsToExtend: {"sup"},
          builder: (context) {
            final element = context.element;
            if ((element?.classes.contains('footnote-marker')) ?? false) {
              final currentIndex = footnoteCounter++;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (visibleFootnotes.contains(currentIndex)) {
                      visibleFootnotes.remove(currentIndex);
                    } else {
                      visibleFootnotes.add(currentIndex);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 2, right: 2),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: Color(0xFF007bff),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    child:
                        (context.element?.text ?? '').isNotEmpty
                            ? Text(context.element?.text ?? '')
                            : const Text('*'),
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
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF8a8a8a),
                              fontSize: 16,
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
