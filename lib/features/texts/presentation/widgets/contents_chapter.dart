import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/data/providers/font_size_notifier.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/features/texts/utils/helper_functions.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fquery/fquery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ContentsChapter extends ConsumerStatefulWidget {
  final ItemScrollController itemScrollController;
  final Toc content;
  final String? selectedSegmentId;
  final TextDetail textDetail;
  final UseInfiniteQueryResult<ReaderResponse, dynamic, Map<String, dynamic>>
  infiniteQuery;
  final List<Section> newPageSections;

  const ContentsChapter({
    super.key,
    required this.itemScrollController,
    required this.content,
    this.selectedSegmentId,
    required this.textDetail,
    required this.infiniteQuery,
    required this.newPageSections,
  });

  @override
  ConsumerState<ContentsChapter> createState() => _ContentsChapterState();
}

class _ContentsChapterState extends ConsumerState<ContentsChapter> {
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  // Scroll management (equivalent to React's scrollRef)
  bool _hasTriggeredPrevious = false;
  bool _hasTriggeredNext = false;
  Timer? _debounceTimer;

  // Store current position before loading to calculate correct offset
  int? _currentPositionBeforeLoad;

  @override
  void initState() {
    super.initState();
    itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);
  }

  @override
  void didUpdateWidget(ContentsChapter oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect when previous page finishes loading and adjust scroll
    if (oldWidget.infiniteQuery.isFetchingPreviousPage &&
        !widget.infiniteQuery.isFetchingPreviousPage &&
        _currentPositionBeforeLoad != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _adjustScrollAfterPreviousLoad();
      });
    }
  }

  void _adjustScrollAfterPreviousLoad() {
    // Get the last loaded page to calculate items added
    final pages = widget.infiniteQuery.data?.pages;
    if (pages != null && pages.isNotEmpty) {
      // Find the most recently loaded previous page
      final newlyLoadedPage = pages.last; // Assuming it's appended
      final newItemsCount = getTotalSegmentsCount(
        newlyLoadedPage.content.sections,
      );
      // debugPrint("newItemsCount: $newItemsCount");

      if (_currentPositionBeforeLoad != null) {
        final targetIndex = _currentPositionBeforeLoad! + newItemsCount;
        // debugPrint(
        //   "Adjusting scroll to: $targetIndex (was: $_currentPositionBeforeLoad, added: $newItemsCount)",
        // );

        if (widget.itemScrollController.isAttached && targetIndex >= 0) {
          widget.itemScrollController.scrollTo(
            index: targetIndex,
            duration: const Duration(milliseconds: 1),
          );
        }
      }
    }

    _currentPositionBeforeLoad = null;
  }

  @override
  void dispose() {
    itemPositionsListener.itemPositions.removeListener(
      _onScrollPositionChanged,
    );
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScrollPositionChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      final positionsSet = itemPositionsListener.itemPositions.value;
      if (positionsSet.isEmpty) return;

      final positions =
          positionsSet.toList()..sort((a, b) => a.index.compareTo(b.index));
      final firstVisibleIndex = positions.first.index;
      final lastVisibleIndex = positions.last.index;

      final currentSegmentPosition =
          widget.infiniteQuery.data?.pages.first.currentSegmentPosition ?? 1;
      final hasPreviousPage = currentSegmentPosition > 1;

      // Load previous sections when near the beginning
      if (firstVisibleIndex <= 5 &&
          hasPreviousPage &&
          !widget.infiniteQuery.isFetchingPreviousPage &&
          !_hasTriggeredPrevious) {
        _hasTriggeredPrevious = true;
        // Store current position before loading
        _currentPositionBeforeLoad = firstVisibleIndex;
        _loadPreviousPage(anchorIndex: firstVisibleIndex);
      }

      // Load next sections when near the end
      if (lastVisibleIndex >= _getTotalItemCount() - 3 &&
          widget.infiniteQuery.hasNextPage &&
          !widget.infiniteQuery.isFetchingNextPage &&
          !_hasTriggeredNext) {
        _hasTriggeredNext = true;
        _loadNextPage();
      }
    });
  }

  Future<void> _loadPreviousPage({required int anchorIndex}) async {
    try {
      widget.infiniteQuery.fetchPreviousPage();

      // How many new list items were prepended?
      final newItemsCount = getTotalSegmentsCount(widget.newPageSections);

      final targetIndex = anchorIndex + newItemsCount;
      // if (widget.itemScrollController.isAttached && targetIndex >= 0) {
      //   widget.itemScrollController.scrollTo(
      //     index: targetIndex,
      //     duration: const Duration(milliseconds: 1),
      //   );
      // }
    } finally {
      _hasTriggeredPrevious = false;
    }
  }

  int getTotalSegmentsCount(List<Section> sections) {
    return sections.fold(0, (total, section) {
      int sectionTotal = section.segments.length;

      // Add segments from nested sections
      if (section.sections != null) {
        sectionTotal += getTotalSegmentsCount(section.sections!);
      }

      return total + sectionTotal;
    });
  }

  void _loadNextPage() {
    widget.infiniteQuery.fetchNextPage();
    _hasTriggeredNext = false;
  }

  int _getTotalItemCount() {
    int count = 0;
    for (final section in widget.content.sections) {
      count += calculateSectionItemCount(section);
    }
    return count; // No loading indicators in the count!
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Loading previous content indicator
        if (widget.infiniteQuery.isFetchingPreviousPage)
          _buildLoadingIndicator("Loading previous content..."),

        // Main content with ScrollablePositionedList
        Expanded(
          child: ScrollablePositionedList.builder(
            itemScrollController: widget.itemScrollController,
            itemPositionsListener: itemPositionsListener,
            itemCount:
                _getTotalItemCount(), // Clean count, no loading indicators
            padding: const EdgeInsets.only(bottom: 40),
            itemBuilder: (context, index) {
              return _buildSectionOrSegmentItem(index);
            },
          ),
        ),

        // Loading next content indicator
        if (widget.infiniteQuery.isFetchingNextPage)
          _buildLoadingIndicator("Loading more content..."),
      ],
    );
  }

  Widget _buildSectionOrSegmentItem(int index) {
    // Simple index calculation - no need to adjust for loading indicators!
    int currentIndex = 0;

    for (final section in widget.content.sections) {
      final sectionItemCount = calculateSectionItemCount(section);

      if (currentIndex <= index && index < currentIndex + sectionItemCount) {
        return _buildSectionRecursive(section, index - currentIndex);
      }
      currentIndex += sectionItemCount;
    }

    return const SizedBox.shrink();
  }

  Widget _buildSectionRecursive(Section section, int relativeIndex) {
    int currentIndex = 0;

    // Section title
    if (currentIndex == relativeIndex) {
      return _buildSectionTitle(section);
    }
    currentIndex++;

    // Direct segments
    for (
      int segmentIndex = 0;
      segmentIndex < section.segments.length;
      segmentIndex++
    ) {
      if (currentIndex == relativeIndex) {
        return _buildSegmentWidget(section, segmentIndex);
      }
      currentIndex++;
    }

    // Nested sections
    if (section.sections != null) {
      for (final nestedSection in section.sections!) {
        final nestedSectionItemCount = calculateSectionItemCount(nestedSection);
        if (currentIndex <= relativeIndex &&
            relativeIndex < currentIndex + nestedSectionItemCount) {
          return _buildSectionRecursive(
            nestedSection,
            relativeIndex - currentIndex,
          );
        }
        currentIndex += nestedSectionItemCount;
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildSectionTitle(Section section) {
    final language = widget.textDetail.language;
    final fontSize = language == 'bo' ? 26.0 : 22.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        section.title ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: getFontFamily(widget.textDetail.language),
        ),
      ),
    );
  }

  Widget _buildSegmentWidget(Section section, int segmentIndex) {
    final segment = section.segments[segmentIndex];
    final segmentNumber = segment.segmentNumber.toString().padLeft(2);
    final content = segment.content;
    final selectedSegment = ref.watch(selectedSegmentProvider);
    final isSelected = selectedSegment?.segmentId == segment.segmentId;
    final fontSize = ref.watch(fontSizeProvider);

    return Container(
      key: Key(segment.segmentId),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final isSameSegment = selectedSegment?.segmentId == segment.segmentId;
            final isCommentaryOpen = ref.read(commentarySplitSegmentProvider) != null;

            if (isSameSegment) {
              // Tapping the same segment - close split view if open and deselect
              ref.read(commentarySplitSegmentProvider.notifier).state = null;
              ref.read(selectedSegmentProvider.notifier).state = null;
            } else {
              // Selecting a different segment
              ref.read(selectedSegmentProvider.notifier).state = segment;
              // If commentary is open, update it to show this segment's commentary
              if (isCommentaryOpen) {
                ref.read(commentarySplitSegmentProvider.notifier).state = segment.segmentId;
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primary.withAlpha(60)
                      : Theme.of(context).colorScheme.primary.withAlpha(30)
                  : null,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segment number
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 30,
                    child: Text(
                      segmentNumber,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: fontSize * 0.6,
                        fontWeight: FontWeight.w500,
                        fontFamily: getFontFamily(widget.textDetail.language),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Segment content
                Expanded(
                  child: SegmentHtmlWidget(
                    htmlContent: content ?? '',
                    segmentIndex: segment.segmentNumber,
                    fontSize: fontSize,
                    language: widget.textDetail.language,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}
