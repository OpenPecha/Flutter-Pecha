import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_reading_params_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_version_language_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/font_size_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/segment_action_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TextReaderScreen extends ConsumerStatefulWidget {
  const TextReaderScreen({super.key});

  @override
  ConsumerState<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends ConsumerState<TextReaderScreen> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  void _showFontSizeSelector(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final fontSize = ref.watch(fontSizeProvider);
            return Dialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.only(
                top: 60.0,
                left: 20.0,
                right: 20.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final size in [12.0, 18.0, 24.0, 30.0, 40.0])
                          Text(
                            'A',
                            style: TextStyle(
                              fontSize: size,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      padding: EdgeInsets.zero,
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Colors.grey.shade300,
                      min: 10,
                      max: 40,
                      value: fontSize,
                      label: '${fontSize.round()}',
                      onChanged: (value) {
                        ref.read(fontSizeProvider.notifier).setFontSize(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('50%'),
                        Text('110%'),
                        Text('175%'),
                        Text('235%'),
                        Text('300%'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final readingParams = ref.watch(textReadingParamsProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final selectedIndex = ref.watch(selectedSegmentProvider);

    final params = TextDetailsParams(
      textId: readingParams?.textId ?? '',
      contentId: readingParams?.contentId ?? '',
      versionId: readingParams?.versionId,
      skip: readingParams?.skip,
    );

    final textDetails = ref.watch(textDetailsFutureProvider(params));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        toolbarHeight: 50,
        actions: [
          // search icon
          IconButton(
            onPressed: () async {
              final details = textDetails.value;
              if (details != null) {
                final selectedIndex = await showSearch<int?>(
                  context: context,
                  delegate: TextSearchDelegate(textDetails: details, ref: ref),
                );

                if (selectedIndex != null && mounted) {
                  itemScrollController.scrollTo(
                    index: selectedIndex + 1, // +1 for the header
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              }
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => _showFontSizeSelector(context, ref),
            icon: const Icon(Icons.text_increase),
          ),
          GestureDetector(
            onTap: () {
              ref
                  .read(textVersionLanguageProvider.notifier)
                  .setLanguage(textDetails.value?.textDetail.language ?? "en");
              context.push(
                '/texts/version_selection',
                extra: {"textId": textDetails.value?.textDetail.id},
              );
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
                    textDetails.value?.textDetail.language.toUpperCase() ?? "",
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
      body: textDetails.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (response) {
          if (response.content.sections.isEmpty) {
            return const Center(child: Text("No content available"));
          }
          final firstSection = response.content.sections[0];
          if (firstSection.segments.isEmpty) {
            return const Center(child: Text("No segments available"));
          }
          return Stack(
            children: [
              ScrollablePositionedList.builder(
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                itemCount: firstSection.segments.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // This is the header
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            response.textDetail.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            firstSection.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  }

                  final segmentIndex = index - 1;
                  final segment = firstSection.segments[segmentIndex];
                  final segmentNumber = segment.segmentNumber
                      .toString()
                      .padLeft(2);
                  final content = segment.content;
                  final isSelected = selectedIndex == segmentIndex;

                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedSegmentProvider.notifier).state =
                          ref.read(selectedSegmentProvider) == segmentIndex
                              ? null
                              : segmentIndex;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(25)
                                : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
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
                              htmlContent: content,
                              segmentIndex: segmentIndex,
                              fontSize: fontSize,
                              isSelected: isSelected,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (selectedIndex != null)
                SegmentActionBar(
                  text: firstSection.segments[selectedIndex].content,
                  onClose:
                      () =>
                          ref.read(selectedSegmentProvider.notifier).state =
                              null,
                ),
            ],
          );
        },
      ),
    );
  }
}

class TextSearchDelegate extends SearchDelegate<int?> {
  final ReaderResponse textDetails;
  final WidgetRef ref;

  TextSearchDelegate({required this.textDetails, required this.ref});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Container(color: Theme.of(context).scaffoldBackgroundColor);
    }
    final segments = textDetails.content.sections.first.segments;
    final results =
        segments
            .where(
              (segment) =>
                  segment.content.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No results found for "$query"',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final segment = results[index];
          return ListTile(
            title: Text(
              segment.content.replaceAll(RegExp(r'<[^>]*>'), ''),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('Segment ${segment.segmentNumber}'),
            onTap: () {
              final originalIndex = segments.indexOf(segment);
              close(context, originalIndex);
            },
          );
        },
      ),
    );
  }
}
