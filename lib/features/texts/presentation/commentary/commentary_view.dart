import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/data/providers/segment_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_fucntions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// State provider for expanded index
final expandedCommentaryProvider = StateProvider<int?>((ref) => null);

class CommentaryView extends ConsumerWidget {
  const CommentaryView({super.key, required this.segmentId});
  final String segmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedIndex = ref.watch(expandedCommentaryProvider);
    final segmentCommentaries = ref.watch(
      segmentCommentaryFutureProvider(segmentId),
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            ref.read(expandedCommentaryProvider.notifier).state = null;
            context.pop();
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFFB6D7D7)),
        ),
      ),
      body: segmentCommentaries.when(
        data:
            (data) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.commentaries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'All Commentary (${data.commentaries.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }
                final commentary = data.commentaries[index - 1];
                final isExpanded = expandedIndex == index;
                // replace <br> with \n
                final content = commentary.content.replaceAll('<br>', '\n');

                return Container(
                  margin: const EdgeInsets.only(bottom: 16, top: 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commentary.title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontFamily: getFontFamily(commentary.language),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        color: const Color(0xFFB6D7D7),
                        margin: const EdgeInsets.only(bottom: 8),
                      ),
                      Text(
                        isExpanded ? content : _getPreview(content),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: getFontFamily(commentary.language),
                          height: getLineHeight(commentary.language),
                        ),
                      ),
                      if (!isExpanded)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                () =>
                                    ref
                                        .read(
                                          expandedCommentaryProvider.notifier,
                                        )
                                        .state = index,
                            child: Text(
                              'Read more',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      if (isExpanded)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed:
                                  () =>
                                      ref
                                          .read(
                                            expandedCommentaryProvider.notifier,
                                          )
                                          .state = null,
                              child: Text(
                                'Show less',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String _getPreview(String content) {
    const maxLen = 150;
    if (content.length <= maxLen) return content;
    return content.substring(0, maxLen);
  }
}
