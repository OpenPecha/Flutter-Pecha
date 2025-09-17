import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_version_language_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/font_size_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/font_size_selector.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/segment_action_bar.dart';
import 'package:flutter_pecha/features/texts/utils/hepler_functions.dart';
import 'package:flutter_pecha/shared/utils/helper_fucntions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async'; // Added for Timer

class TextReaderScreen extends ConsumerStatefulWidget {
  const TextReaderScreen({
    super.key,
    required this.textId,
    required this.contentId,
    this.segmentId,
  });
  final String textId;
  final String contentId;
  final String? segmentId;

  @override
  ConsumerState<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends ConsumerState<TextReaderScreen> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  // State variables
  List<Section> sectionsData = [];
  TextDetail? textDetailData;
  bool isLoading = true;
  bool isLoadingPreviousSection = false;
  bool isLoadingNextSection = false;
  int currentSegmentPosition = 0;
  int totalSegments = 0;
  int size = 20;

  // Scroll management
  bool _hasTriggeredPrevious = false;
  bool _hasTriggeredNext = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromProvider();
    });
  }

  @override
  void dispose() {
    itemPositionsListener.itemPositions.removeListener(
      _onScrollPositionChanged,
    );
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initializeFromProvider() async {
    try {
      setState(() {
        isLoading = true;
      });
      final params = TextDetailsParams(
        textId: widget.textId,
        contentId: widget.contentId,
        segmentId: widget.segmentId,
        direction: 'next',
      );
      final response = await ref.read(textDetailsFutureProvider(params).future);
      initialSections(response);
    } catch (e) {
      debugPrint('error initializing from provider: $e');
      setState(() {
        isLoading = false;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void initialSections(ReaderResponse response) {
    if (response.content.sections.isNotEmpty && mounted) {
      setState(() {
        sectionsData = response.content.sections;
        textDetailData = response.textDetail;
        isLoading = false;
        totalSegments = response.totalSegments;
        currentSegmentPosition = response.currentSegmentPosition;
      });
    }
  }

  void _onScrollPositionChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      final positions = itemPositionsListener.itemPositions.value;
      if (positions.isEmpty) return;

      final firstVisibleIndex = positions.first.index;
      final lastVisibleIndex = positions.last.index;

      // Load previous sections when near the beginning
      if (firstVisibleIndex <= 5 &&
          !isLoadingPreviousSection &&
          !_hasTriggeredPrevious &&
          sectionsData.isNotEmpty) {
        if (currentSegmentPosition >= 5) {
          _hasTriggeredPrevious = true;
          loadPreviousSection();
        }
      }

      // Load next sections when near the end
      if (lastVisibleIndex >= _getTotalItemCount() - 3 &&
          !isLoadingNextSection &&
          !_hasTriggeredNext &&
          currentSegmentPosition <= totalSegments - size) {
        _hasTriggeredNext = true;
        loadNextSection();
      }
    });
  }

  void loadPreviousSection() async {
    setState(() {
      isLoadingPreviousSection = true;
    });

    try {
      final firstSegmentId = getFirstSegmentId(sectionsData);
      if (firstSegmentId == null) {
        return;
      }

      final params = TextDetailsParams(
        textId: widget.textId,
        contentId: widget.contentId,
        segmentId: firstSegmentId,
        direction: 'previous',
      );

      final response = await ref.read(textDetailsFutureProvider(params).future);

      if (response.content.sections.isNotEmpty) {
        final newSections = response.content.sections;
        final mergedSections = mergeSections(
          sectionsData,
          newSections,
          'previous',
        );

        setState(() {
          sectionsData = mergedSections;
          currentSegmentPosition = response.currentSegmentPosition;
        });

        // Adjust scroll position to maintain current view
        final currentPosition =
            itemPositionsListener.itemPositions.value.first.index;
        final newSegmentsCount = getTotalSegmentsCount(newSections);
        final newPosition = currentPosition + newSegmentsCount;

        if (newPosition > 0) {
          itemScrollController.scrollTo(
            index: newPosition,
            duration: const Duration(milliseconds: 1),
          );
        }
      }
    } catch (e) {
      debugPrint('error loading previous section: $e');
    } finally {
      setState(() {
        isLoadingPreviousSection = false;
        _hasTriggeredPrevious = false;
      });
    }
  }

  void loadNextSection() async {
    setState(() {
      isLoadingNextSection = true;
    });

    try {
      final lastSegmentId = getLastSegmentId(sectionsData);
      if (lastSegmentId == null) {
        return;
      }

      final params = TextDetailsParams(
        textId: widget.textId,
        contentId: widget.contentId,
        segmentId: lastSegmentId,
        direction: 'next',
      );

      final response = await ref.read(textDetailsFutureProvider(params).future);

      if (response.content.sections.isNotEmpty) {
        final newSections = response.content.sections;
        final mergedSections = mergeSections(sectionsData, newSections, 'next');

        setState(() {
          sectionsData = mergedSections;
          currentSegmentPosition = response.currentSegmentPosition;
        });
      }
    } catch (e) {
      debugPrint('error loading next section: $e');
    } finally {
      setState(() {
        isLoadingNextSection = false;
        _hasTriggeredNext = false;
      });
    }
  }

  int _getTotalItemCount() {
    int count = 0;
    for (final section in sectionsData) {
      count += _calculateSectionItemCount(section);
    }
    if (isLoadingPreviousSection) count++;
    if (isLoadingNextSection) count++;
    return count;
  }

  int _calculateSectionItemCount(Section section) {
    int count = 1; // Section title
    count += section.segments.length; // Direct segments

    // Add nested sections
    if (section.sections != null) {
      for (final nestedSection in section.sections!) {
        count += _calculateSectionItemCount(nestedSection);
      }
    }

    return count;
  }

  Widget _buildSectionOrSegmentItem(int index) {
    // Loading indicator at top
    if (index == 0 && isLoadingPreviousSection) {
      return _buildLoadingIndicator('Loading previous sections...');
    }

    // Adjust index for loading indicator
    final adjustedIndex = isLoadingPreviousSection ? index - 1 : index;

    // Calculate which section and segment this index corresponds to
    int currentIndex = 0;

    // for (
    //   int sectionIndex = 0;
    //   sectionIndex < sectionsData.length;
    //   sectionIndex++
    // ) {
    //   final section = sectionsData[sectionIndex];

    //   // Section title
    //   if (currentIndex == adjustedIndex) {
    //     return _buildSectionTitle(section);
    //   }
    //   currentIndex++;

    //   // Section segments
    //   for (
    //     int segmentIndex = 0;
    //     segmentIndex < section.segments.length;
    //     segmentIndex++
    //   ) {
    //     if (currentIndex == adjustedIndex) {
    //       return _buildSegmentItem(section, segmentIndex, sectionIndex);
    //     }
    //     currentIndex++;
    //   }
    // }
    for (
      int sectionIndex = 0;
      sectionIndex < sectionsData.length;
      sectionIndex++
    ) {
      final section = sectionsData[sectionIndex];
      final sectionItemCount = _calculateSectionItemCount(section);
      if (currentIndex <= adjustedIndex &&
          adjustedIndex < currentIndex + sectionItemCount) {
        return _buildSectionRecursive(
          section,
          adjustedIndex - currentIndex,
          sectionIndex,
        );
      }
      currentIndex += sectionItemCount;
    }
    // Loading indicator at bottom
    if (index == _getTotalItemCount() - 1 && isLoadingNextSection) {
      return _buildLoadingIndicator('Loading next sections...');
    }

    return const SizedBox.shrink();
  }

  Widget _buildSectionRecursive(
    Section section,
    int relativeIndex,
    int sectionIndex,
  ) {
    int currentIndex = 0;
    // Section title
    if (currentIndex == relativeIndex) {
      return _buildSectionTitle(section);
    }
    currentIndex++;

    // direct segments
    for (
      int segmentIndex = 0;
      segmentIndex < section.segments.length;
      segmentIndex++
    ) {
      if (currentIndex == relativeIndex) {
        return _buildSegmentItem(section, segmentIndex, sectionIndex);
      }
      currentIndex++;
    }

    // nested sections
    if (section.sections != null) {
      for (final nestedSection in section.sections!) {
        final nestedSectionItemCount = _calculateSectionItemCount(
          nestedSection,
        );
        if (currentIndex <= relativeIndex &&
            relativeIndex < currentIndex + nestedSectionItemCount) {
          return _buildSectionRecursive(
            nestedSection,
            relativeIndex - currentIndex,
            sectionIndex,
          );
        }
        currentIndex += nestedSectionItemCount;
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildSectionTitle(Section section) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        section.title ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontFamily: getFontFamily(textDetailData?.language ?? 'en'),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSegmentItem(
    Section section,
    int segmentIndex,
    int sectionIndex,
  ) {
    final segment = section.segments[segmentIndex];
    final segmentNumber = segment.segmentNumber.toString().padLeft(2);
    final content = segment.content;

    // Calculate global segment index for selection
    final globalSegmentIndex = _calculateGlobalSegmentIndex(
      sectionIndex,
      segmentIndex,
    );
    final isSelected = ref.watch(selectedSegmentProvider) == globalSegmentIndex;

    return GestureDetector(
      onTap: () {
        // ref.read(selectedSegmentProvider.notifier).state =
        //     ref.read(selectedSegmentProvider) == globalSegmentIndex
        //         ? null
        //         : globalSegmentIndex;
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withAlpha(25)
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 30,
                child: Text(
                  segmentNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SegmentHtmlWidget(
                htmlContent: content ?? '',
                segmentIndex: globalSegmentIndex,
                fontSize: ref.watch(fontSizeProvider),
                language: textDetailData?.language ?? 'en',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }

  int _calculateGlobalSegmentIndex(int sectionIndex, int segmentIndex) {
    int globalIndex = 0;
    for (int i = 0; i < sectionIndex; i++) {
      // globalIndex += sectionsData[i].segments.length;
      globalIndex += _calculateTotalSegmentsInSection(sectionsData[i]);
    }
    return globalIndex + segmentIndex;
  }

  int _calculateTotalSegmentsInSection(Section section) {
    int count = section.segments.length;
    if (section.sections != null) {
      for (final nestedSection in section.sections!) {
        count += _calculateTotalSegmentsInSection(nestedSection);
      }
    }
    return count;
  }

  Segment? _getSegmentByGlobalIndex(int globalIndex) {
    int currentIndex = 0;
    for (final section in sectionsData) {
      final totalSegments = _calculateTotalSegmentsInSection(section);
      if (currentIndex <= globalIndex &&
          globalIndex < currentIndex + totalSegments) {
        return _findSegmentInSection(section, globalIndex - currentIndex);
      }
      currentIndex += totalSegments;
    }
    return null;
  }

  Segment? _findSegmentInSection(Section section, int relativeIndex) {
    int currentIndex = 0;

    // Check direct segments
    if (relativeIndex < section.segments.length) {
      return section.segments[relativeIndex];
    }
    currentIndex += section.segments.length;

    // Check nested sections
    if (section.sections != null) {
      for (final nestedSection in section.sections!) {
        final nestedSegments = _calculateTotalSegmentsInSection(nestedSection);
        if (currentIndex <= relativeIndex &&
            relativeIndex < currentIndex + nestedSegments) {
          return _findSegmentInSection(
            nestedSection,
            relativeIndex - currentIndex,
          );
        }
        currentIndex += nestedSegments;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final selectedIndex = ref.watch(selectedSegmentProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            ref.read(selectedSegmentProvider.notifier).state = null;
            Navigator.pop(context);
          },
        ),
        toolbarHeight: 50,
        actions: [
          IconButton(
            onPressed: () async {
              if (textDetailData != null) {
                // Create a ReaderResponse for search
                final readerResponse = ReaderResponse(
                  textDetail: textDetailData!,
                  content: Toc(
                    id: widget.contentId,
                    textId: widget.textId,
                    sections: sectionsData,
                  ),
                  size: size,
                  paginationDirection: 'next',
                  currentSegmentPosition: currentSegmentPosition,
                  totalSegments: totalSegments,
                );

                // final selectedIndex = await showSearch<int?>(
                //   context: context,
                //   delegate: TextSearchDelegate(
                //     textDetails: readerResponse,
                //     ref: ref,
                //   ),
                // );

                // if (selectedIndex != null && mounted) {
                //   final adjustedIndex = _calculateIndexForSearch(selectedIndex);
                //   itemScrollController.scrollTo(
                //     index: adjustedIndex,
                //     duration: const Duration(milliseconds: 500),
                //     curve: Curves.easeInOut,
                //   );
                // }
              }
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => showFontSizeSelector(context, ref),
            icon: const Icon(Icons.text_increase),
          ),
          GestureDetector(
            onTap: () async {
              ref
                  .read(textVersionLanguageProvider.notifier)
                  .setLanguage(textDetailData?.language ?? "en");
              final result = await context.push(
                '/texts/version_selection',
                extra: {"textId": textDetailData?.id},
              );

              if (result != null && result is Map<String, dynamic>) {
                final newTextId = result['textId'] as String?;
                final newContentId = result['contentId'] as String?;

                if (newTextId != null && newContentId != null) {
                  // Update the text with new parameters
                  setState(() {
                    isLoading = true;
                  });

                  try {
                    final params = TextDetailsParams(
                      textId: newTextId,
                      contentId: newContentId,
                      segmentId: null,
                      direction: 'next',
                    );
                    final response = await ref.read(
                      textDetailsFutureProvider(params).future,
                    );
                    initialSections(response);
                  } catch (e) {
                    debugPrint('error updating text: $e');
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    textDetailData?.language.toUpperCase() ?? "",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 20),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFFB6D7D7)),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Fixed header
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        Text(
                          textDetailData?.title ?? '',
                          style: TextStyle(
                            fontSize: getFontSize(
                              textDetailData?.language ?? 'en',
                            ),
                            fontFamily: getFontFamily(
                              textDetailData?.language ?? 'en',
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currentSegmentPosition / $totalSegments',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main content with defined height
                  Expanded(
                    child: Stack(
                      children: [
                        // Main content
                        ScrollablePositionedList.builder(
                          itemScrollController: itemScrollController,
                          itemPositionsListener: itemPositionsListener,
                          itemCount: _getTotalItemCount(),
                          padding: const EdgeInsets.only(bottom: 40),
                          itemBuilder: (context, index) {
                            return _buildSectionOrSegmentItem(index);
                          },
                        ),
                        // Segment action bar
                        // if (selectedIndex != null)
                        // _buildSegmentActionBar(selectedIndex),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSegmentActionBar(int selectedIndex) {
    final segment = _getSegmentByGlobalIndex(selectedIndex);
    if (segment == null) return const SizedBox.shrink();

    return SegmentActionBar(
      text: segment.content ?? '',
      textId: textDetailData?.id ?? '',
      contentId: widget.contentId,
      segmentId: segment.segmentId,
      language: textDetailData?.language ?? 'en',
      onClose: () => ref.read(selectedSegmentProvider.notifier).state = null,
    );
  }

  int _calculateIndexForSearch(int searchResultIndex) {
    // Convert search result index to the correct position in the list
    int currentIndex = 0;
    int segmentCount = 0;

    for (
      int sectionIndex = 0;
      sectionIndex < sectionsData.length;
      sectionIndex++
    ) {
      final section = sectionsData[sectionIndex];
      final totalSegments = _calculateTotalSegmentsInSection(section);

      // Check if the search result is in this section
      if (searchResultIndex >= segmentCount &&
          searchResultIndex < segmentCount + totalSegments) {
        // Calculate the position: header + previous sections + section title + segment position
        return (isLoadingPreviousSection
                ? 2
                : 1) + // Header + loading indicator
            currentIndex + // Previous sections and their segments
            (searchResultIndex - segmentCount); // Position within this section
      }

      currentIndex += _calculateSectionItemCount(
        section,
      ); // Section title + segments + nested sections
      segmentCount += totalSegments;
    }

    return searchResultIndex + (isLoadingPreviousSection ? 2 : 1);
  }
}

// Utility function to show font size selector
void showFontSizeSelector(BuildContext context, WidgetRef ref) {
  showDialog(context: context, builder: (context) => const FontSizeSelector());
}
