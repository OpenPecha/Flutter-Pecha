import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/constants/text_routes.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_version_language_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/chapter_header.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/contents_chapter.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/font_size_selector.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/language_selector_badge.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/segment_action_bar.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/library_search_delegate.dart';
import 'package:flutter_pecha/features/texts/utils/helper_functions.dart';
import 'package:fquery/fquery.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Screen for reading chapter content with infinite scroll pagination
/// Supports searching within text, font size adjustment, and language selection
class ChaptersScreen extends StatefulHookConsumerWidget {
  final String textId;
  final String? contentId;
  final String? segmentId;
  final int? colorIndex;

  const ChaptersScreen({
    super.key,
    required this.textId,
    this.contentId,
    this.segmentId,
    this.colorIndex,
  });

  @override
  ConsumerState<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends ConsumerState<ChaptersScreen> {
  final ItemScrollController itemScrollController = ItemScrollController();

  // State variables to hold the current textId and segmentId
  late String currentTextId;
  late String? currentContentId;
  late String? currentSegmentId;

  @override
  void initState() {
    super.initState();
    // Initialize with the widget's initial values
    currentTextId = widget.textId;
    currentContentId = widget.contentId;
    currentSegmentId = widget.segmentId;
  }

  /// Update the text and segment when navigating within the chapter
  void updateTextAndSegment(
    String newTextId, {
    String? newSegmentId,
    String? newContentId,
  }) {
    setState(() {
      currentTextId = newTextId;
      currentSegmentId = newSegmentId;
      currentContentId = newContentId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedSegment = ref.watch(selectedSegmentProvider);
    const size = 20;
    final newPageSections = useState<List<Section>>([]);

    // Initialize the infinite query using current state values
    final infiniteQuery = useInfiniteQuery<
      ReaderResponse,
      dynamic,
      Map<String, dynamic>
    >(
      [
        'content',
        currentTextId,
        currentContentId ?? '',
        currentSegmentId ?? '',
        size,
      ],
      (Map<String, dynamic> pageParam) async {
        final segmentId = pageParam['segmentId'] ?? currentSegmentId;
        final contentId = pageParam['contentId'] ?? currentContentId;
        final direction = pageParam['direction'] ?? 'next';

        final params = TextDetailsParams(
          textId: currentTextId,
          contentId: contentId,
          segmentId: segmentId,
          direction: direction,
        );

        final response = await ref.read(
          textDetailsFutureProvider(params).future,
        );
        newPageSections.value = response.content.sections;
        return response;
      },
      initialPageParam: {'segmentId': currentSegmentId, 'direction': 'next'},
      getNextPageParam: (lastPage, allPages, lastPageParam, allParams) {
        if (lastPage.currentSegmentPosition == lastPage.totalSegments) {
          return null;
        }
        final lastSegmentId = getLastSegmentId(lastPage.content.sections);
        if (lastSegmentId == null) return null;
        return {'segmentId': lastSegmentId, 'direction': 'next'};
      },
      getPreviousPageParam: (firstPage, allPages, firstPageParam, allParams) {
        if (firstPage.currentSegmentPosition <= 1) return null;
        final firstSegmentId = getFirstSegmentId(firstPage.content.sections);
        if (firstSegmentId == null) return null;
        return {'segmentId': firstSegmentId, 'direction': 'previous'};
      },
      enabled: currentTextId.isNotEmpty,
      refetchOnMount: RefetchOnMount.never,
    );

    // Memoize merged content to avoid recalculation on every rebuild
    final allContent = useMemoized(() {
      if (infiniteQuery.data?.pages == null ||
          infiniteQuery.data!.pages.isEmpty) {
        return null;
      }
      try {
        List<Section> mergedSections = [];
        final textDetail = infiniteQuery.data!.pages[0].textDetail;

        for (int index = 0; index < infiniteQuery.data!.pages.length; index++) {
          final page = infiniteQuery.data!.pages[index];
          if (index == 0) {
            mergedSections = page.content.sections;
          } else {
            mergedSections = mergeSections(
              mergedSections,
              page.content.sections,
              'next',
            );
          }
        }

        final mergedToc = Toc(
          id: infiniteQuery.data!.pages[0].content.id,
          textId: infiniteQuery.data!.pages[0].content.textId,
          sections: mergedSections,
        );

        return ReaderResponse(
          content: mergedToc,
          textDetail: textDetail,
          currentSegmentPosition:
              infiniteQuery.data!.pages[0].currentSegmentPosition,
          totalSegments: infiniteQuery.data!.pages[0].totalSegments,
          size: infiniteQuery.data!.pages[0].size,
          paginationDirection: infiniteQuery.data!.pages[0].paginationDirection,
        );
      } catch (e) {
        debugPrint("Error creating merged content: $e");
        return null;
      }
    }, [infiniteQuery.data?.pages]);

    // useEffect(() {
    //   if (segmentId != null && allContent != null) {
    //     final idx = findSegmentIndex(allContent.content, segmentId!);
    //     if (idx != -1 && itemScrollController.isAttached) {
    //       // Jump without animation to avoid flicker and race with the listener
    //       itemScrollController.scrollTo(
    //         index: idx,
    //         duration: const Duration(milliseconds: 1),
    //       );
    //     }
    //   }
    //   return null;
    // }, [allContent?.content.id, segmentId]);

    return Scaffold(
      appBar: _buildAppBar(context, infiniteQuery),
      body: _buildBody(
        context,
        infiniteQuery,
        allContent,
        selectedSegment,
        newPageSections.value,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    UseInfiniteQueryResult<ReaderResponse, dynamic, Map<String, dynamic>>
    infiniteQuery,
  ) {
    // Get the border color from the color index
    final borderColor = widget.colorIndex != null
        ? TextScreenConstants.collectionCyclingColors[widget.colorIndex! % 9]
        : TextScreenConstants.primaryBorderColor;

    return AppBar(
      elevation: TextScreenConstants.appBarElevation,
      scrolledUnderElevation: TextScreenConstants.appBarElevation,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          ref.read(selectedSegmentProvider.notifier).state = null;
          context.pop();
        },
      ),
      toolbarHeight: TextScreenConstants.appBarToolbarHeight,
      actions: [
        _buildSearchButton(context),
        _buildFontSizeButton(context),
        if (infiniteQuery.data != null)
          _buildLanguageSelector(context, infiniteQuery),
      ],
      actionsPadding: TextScreenConstants.appBarActionsPadding,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(
          TextScreenConstants.appBarBottomHeight,
        ),
        child: Container(
          height: TextScreenConstants.appBarBottomHeight,
          color: borderColor,
        ),
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final result = await showSearch<Map<String, String>?>(
          context: context,
          delegate: LibrarySearchDelegate(ref: ref, textId: currentTextId),
        );

        if (result != null) {
          final selectedTextId = result['textId']!;
          final selectedSegmentId = result['segmentId']!;

          // Update textId and segmentId to load new text without routing
          updateTextAndSegment(selectedTextId, newSegmentId: selectedSegmentId);
        }
      },
      icon: const Icon(Icons.search),
    );
  }

  Widget _buildFontSizeButton(BuildContext context) {
    return IconButton(
      onPressed: () => _showFontSizeSelector(context),
      icon: const Icon(Icons.text_increase),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    UseInfiniteQueryResult<ReaderResponse, dynamic, Map<String, dynamic>>
    infiniteQuery,
  ) {
    final textDetail = infiniteQuery.data!.pages.first.textDetail;
    return LanguageSelectorBadge(
      language: textDetail.language,
      onTap: () async {
        ref
            .read(textVersionLanguageProvider.notifier)
            .setLanguage(textDetail.language);
        final result = await context.push(
          TextRoutes.versionSelection,
          extra: {"textId": currentTextId},
        );
        if (result != null && result is Map<String, dynamic>) {
          final newTextId = result['textId'] as String?;
          final newContentId = result['contentId'] as String?;
          if (newTextId != null && newContentId != null) {
            updateTextAndSegment(newTextId, newContentId: newContentId);
          }
        }
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    UseInfiniteQueryResult<ReaderResponse, dynamic, Map<String, dynamic>>
    infiniteQuery,
    ReaderResponse? allContent,
    Segment? selectedSegment,
    List<Section> newPageSections,
  ) {
    if (infiniteQuery.isLoading) {
      return const Center(child: Text("Loading..."));
    }

    if (infiniteQuery.isError) {
      return const Center(child: Text('No data found'));
    }

    return Column(
      children: [
        ChapterHeader(textDetail: allContent!.textDetail),
        Expanded(
          child: Stack(
            children: [
              // Main content
              ContentsChapter(
                itemScrollController: itemScrollController,
                textDetail: allContent.textDetail,
                content: allContent.content,
                selectedSegmentId: selectedSegment?.segmentId,
                infiniteQuery: infiniteQuery,
                newPageSections: newPageSections,
              ),
              // Segment action bar
              if (selectedSegment != null)
                _buildSegmentActionBar(
                  context,
                  selectedSegment,
                  allContent.textDetail,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentActionBar(
    BuildContext context,
    Segment selectedSegment,
    TextDetail textDetail,
  ) {
    if (selectedSegment.content == null) return const SizedBox.shrink();

    return SegmentActionBar(
      text: selectedSegment.content ?? '',
      textId: textDetail.id,
      contentId: currentContentId,
      segmentId: selectedSegment.segmentId,
      language: textDetail.language,
      onClose: () => ref.read(selectedSegmentProvider.notifier).state = null,
    );
  }

  /// Show font size selector dialog
  void _showFontSizeSelector(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final language = locale.languageCode;
    showDialog(
      context: context,
      builder: (context) => FontSizeSelector(language: language),
    );
  }
}
