import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextReaderScreen extends ConsumerWidget {
  const TextReaderScreen({
    super.key,
    required this.textId,
    required this.section,
    required this.skip,
  });
  final String textId;
  final Section section;
  final String skip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = TextDetailsParams(
      textId: textId,
      contentId: section.contentId,
      skip: skip,
    );
    final segments = ref.watch(textDetailsFutureProvider(params));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 40,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
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
                  "EN",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 20),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFFB6D7D7)),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'The Way of the Bodhisattva',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Jomolhari',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Jomolhari',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          segments.when(
            loading:
                () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (error, stackTrace) => SliverToBoxAdapter(
                  child: Center(child: Text(error.toString())),
                ),
            data:
                (segments) => SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final segment = segments[index];
                    final segmentNumber = segment.segmentNumber
                        .toString()
                        .padLeft(2, '0');
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
                  }, childCount: segments.length),
                ),
          ),
        ],
      ),
    );
  }
}
