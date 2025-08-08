import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_version_language_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/chapter.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/font_size_selector.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/segment_action_bar.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/text_search_delegate.dart';
import 'package:flutter_pecha/features/texts/utils/hepler_functions.dart';
import 'package:flutter_pecha/shared/utils/helper_fucntions.dart';
import 'package:fquery/fquery.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// text chapter layout for long text
class TextChapter extends HookConsumerWidget {
  final String textId;
  final String contentId;
  final String? segmentId;
  TextChapter({
    super.key,
    required this.textId,
    required this.contentId,
    this.segmentId,
  });

  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSegment = ref.watch(selectedSegmentProvider);
    final size = 20;
    final newPageSections = useState<List<Section>>([]);

    // Initialize the infinite query
    final infiniteQuery = useInfiniteQuery<
      ReaderResponse,
      dynamic,
      Map<String, dynamic>
    >(
      ['content', textId, contentId, segmentId ?? '', size],

      (Map<String, dynamic> pageParam) async {
        final segmentId = pageParam['segmentId'] ?? this.segmentId;
        final direction = pageParam['direction'] ?? 'next';

        final params = TextDetailsParams(
          textId: textId,
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
      initialPageParam: {'segmentId': segmentId, 'direction': 'next'},

      // Function to fetch data for each page
      // (TextDetailsParams params) async {
      //   debugPrint("calling textDetailsFutureProvider $params");
      //   final response = await ref.read(
      //     textDetailsFutureProvider(params).future,
      //   );
      //   newPageSections.value = response.content.sections;
      //   return response;
      // },
      // Get the next page parameter
      getNextPageParam: (lastPage, allPages, lastPageParam, allParams) {
        if (lastPage.currentSegmentPosition == lastPage.totalSegments) {
          return null;
        }
        final lastSegmentId = getLastSegmentId(lastPage.content.sections);
        if (lastSegmentId == null) return null;
        return {'segmentId': lastSegmentId, 'direction': 'next'};
      },

      // Get the previous page parameter
      getPreviousPageParam: (firstPage, allPages, firstPageParam, allParams) {
        if (firstPage.currentSegmentPosition <= 1) return null;
        final firstSegmentId = getFirstSegmentId(firstPage.content.sections);
        if (firstSegmentId == null) return null;
        return {'segmentId': firstSegmentId, 'direction': 'previous'};
      },
      enabled: textId.isNotEmpty,
      refetchOnMount: RefetchOnMount.never,
    );

    // Merge all loaded sections for rendering
    final ReaderResponse? allContent = useMemoized(() {
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

        // Create proper Toc object instead of Map
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

    Widget chapter;
    if (infiniteQuery.isLoading) {
      chapter = const Center(child: Text("Loading..."));
    } else if (infiniteQuery.isError) {
      chapter = const Center(child: Text('No data found'));
    } else {
      chapter = Column(
        children: [
          _buildChapterHeader(context, ref, allContent!.textDetail),
          _buildChapter(
            context,
            ref,
            allContent.content,
            allContent.textDetail,
            infiniteQuery,
            selectedSegment,
            newPageSections.value,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            ref.read(selectedSegmentProvider.notifier).state = null;
            context.pop();
          },
        ),
        toolbarHeight: 50,
        actions: [
          if (infiniteQuery.data != null)
            _buildSearchButton(context, ref, allContent!),
          _buildFontSizeSelector(context, ref),
          if (infiniteQuery.data != null)
            _buildLanguageSelector(context, ref, infiniteQuery),
        ],
        actionsPadding: const EdgeInsets.only(right: 20),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFFB6D7D7)),
        ),
      ),
      body: chapter,
    );
  }

  Widget _buildSearchButton(
    BuildContext context,
    WidgetRef ref,
    ReaderResponse allContent,
  ) {
    return IconButton(
      onPressed: () async {
        final selectedSegmentId = await showSearch<String?>(
          context: context,
          delegate: TextSearchDelegate(allContent: allContent, ref: ref),
        );

        if (selectedSegmentId != null) {
          // ✅ Correct way to find the segment index
          final segmentIndex = findSegmentIndex(
            allContent.content,
            selectedSegmentId,
          );

          if (segmentIndex != -1) {
            itemScrollController.scrollTo(
              index: segmentIndex,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else {
            debugPrint("Segment not found: $selectedSegmentId");
          }
        }
      },
      icon: const Icon(Icons.search),
    );
  }

  Widget _buildFontSizeSelector(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => showFontSizeSelector(context, ref),
      icon: const Icon(Icons.text_increase),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    UseInfiniteQueryResult<ReaderResponse, dynamic, Map<String, dynamic>>
    infiniteQuery,
  ) {
    final textDetail = infiniteQuery.data!.pages.first.textDetail;
    return GestureDetector(
      onTap: () async {
        ref
            .read(textVersionLanguageProvider.notifier)
            .setLanguage(textDetail.language);
        context.push('/texts/version_selection', extra: {"textId": textId});
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
              textDetail.language.toUpperCase(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterHeader(
    BuildContext context,
    WidgetRef ref,
    TextDetail textDetail,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        textDetail.title,
        style: TextStyle(
          fontSize: getFontSize(textDetail.language),
          fontFamily: getFontFamily(textDetail.language),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildChapter(
    BuildContext context,
    WidgetRef ref,
    Toc content,
    TextDetail textDetail,
    UseInfiniteQueryResult<ReaderResponse, dynamic, Map<String, dynamic>>
    infiniteQuery,
    Segment? selectedSegment,
    List<Section> newPageSections,
  ) {
    return Expanded(
      child: Stack(
        children: [
          // Main content
          Chapter(
            itemScrollController: itemScrollController,
            textDetail: textDetail,
            content: content,
            selectedSegmentId: selectedSegment?.segmentId,
            infiniteQuery: infiniteQuery,
            newPageSections: newPageSections,
          ),
          // Segment action bar
          if (selectedSegment != null)
            _buildSegmentActionBar(context, ref, selectedSegment, textDetail),
        ],
      ),
    );
  }

  Widget _buildSegmentActionBar(
    BuildContext context,
    WidgetRef ref,
    Segment selectedSegment,
    TextDetail textDetail,
  ) {
    if (selectedSegment.content == null) return const SizedBox.shrink();

    return SegmentActionBar(
      text: selectedSegment.content ?? '',
      textId: textDetail.id,
      contentId: contentId,
      segmentId: selectedSegment.segmentId,
      language: textDetail.language,
      onClose: () => ref.read(selectedSegmentProvider.notifier).state = null,
    );
  }
}

// Utility function to show font size selector
void showFontSizeSelector(BuildContext context, WidgetRef ref) {
  showDialog(context: context, builder: (context) => const FontSizeSelector());
}
