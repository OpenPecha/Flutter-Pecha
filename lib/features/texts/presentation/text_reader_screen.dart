import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/version_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_reading_params_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TextReaderScreen extends ConsumerWidget {
  const TextReaderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingParams = ref.watch(textReadingParamsProvider);
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pop(context),
          ),
          GestureDetector(
            onTap: () async {
              await context.push(
                '/texts/version_selection',
                extra: {
                  "textId": textDetails.value?.textDetail.id,
                  "language": textDetails.value?.textDetail.language,
                },
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
                  const Text(
                    "EN",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
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
          return CustomScrollView(
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
                  return Padding(
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
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: firstSection.segments.length),
              ),
            ],
          );
        },
      ),
    );
  }
}
