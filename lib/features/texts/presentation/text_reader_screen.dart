import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/version_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_reading_params_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_version_language_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/font_size_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/segment_action_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TextReaderScreen extends ConsumerWidget {
  const TextReaderScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final readingParams = ref.watch(textReadingParamsProvider);
    final currentLanguage = ref.watch(textVersionLanguageProvider);
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
            ref.read(versionProvider.notifier).clearVersion();
            ref.read(textReadingParamsProvider.notifier).clearParams();
            Navigator.pop(context);
          },
        ),
        toolbarHeight: 50,
        actions: [
          // search icon
          // IconButton(
          //   onPressed: () => _showSearchDialog(context, ref),
          //   icon: const Icon(Icons.search),
          // ),
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
                    textDetails.value?.textDetail.language.toUpperCase() ??
                        "en".toUpperCase(),
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
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
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
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Jomolhari',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            firstSection.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Jomolhari',
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final segment = firstSection.segments[index];
                      final segmentNumber = segment.segmentNumber
                          .toString()
                          .padLeft(2);
                      final content = segment.content;
                      final isSelected = selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          ref.read(selectedSegmentProvider.notifier).state =
                              ref.read(selectedSegmentProvider) == index
                                  ? null
                                  : index;
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
                                    style: TextStyle(
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
                                  segmentIndex: index,
                                  fontSize: fontSize,
                                  isSelected: isSelected,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: firstSection.segments.length),
                  ),
                ],
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
