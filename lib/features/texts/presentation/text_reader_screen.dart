import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_pecha/features/texts/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TextReaderScreen extends ConsumerWidget {
  const TextReaderScreen({
    super.key,
    this.toc,
    required this.skip,
    this.version,
  });
  final Toc? toc;
  final String skip;
  final Version? version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = TextDetailsParams(
      textId: toc?.textId ?? version?.id ?? '',
      contentId:
          toc?.id ??
          ((version?.tableOfContents != null &&
                  version!.tableOfContents.isNotEmpty)
              ? version!.tableOfContents[0]
              : ''),
      versionId: version?.id,
      skip: skip,
    );
    final textDetails = ref.watch(textDetailsFutureProvider(params));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 50,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pop(context),
          ),
          GestureDetector(
            onTap:
                () => context.push(
                  '/texts/version_selection',
                  extra: {
                    "textId": textDetails.value?["textDetail"]?.id,
                    "language": textDetails.value?["textDetail"]?.language,
                  },
                ),
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
        data:
            (textDetail) => CustomScrollView(
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
                          textDetail["textDetail"]?.title ?? '',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Jomolhari',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          textDetail["sectionsList"]?[0]?.title ?? '',
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
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final segment =
                          textDetail["sectionsList"]?[0]?.segments?[index]
                              as Segment?;
                      final segmentNumber = segment?.segmentNumber
                          .toString()
                          .padLeft(2);
                      final content = segment?.content;
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
                                  segmentNumber ?? '',
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
                                htmlContent: content ?? '',
                                segmentIndex: index,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount:
                        textDetail["sectionsList"]?[0]?.segments?.length,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
