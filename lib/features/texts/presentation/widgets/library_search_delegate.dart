import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/utils/text_highlight_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibrarySearchDelegate extends SearchDelegate<Map<String, String>?> {
  final WidgetRef ref;
  final String textId;
  String _submittedQuery = '';
  bool _hasSubmitted = false;

  LibrarySearchDelegate({required this.ref, required this.textId});

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
          _submittedQuery = '';
          _hasSubmitted = false;
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
    // Only make API call when user submits search (presses search button)
    if (query.isNotEmpty && !_hasSubmitted) {
      _submittedQuery = query;
      _hasSubmitted = true;
    }

    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Reset submitted state when user starts typing again
    if (_hasSubmitted && query != _submittedQuery) {
      _hasSubmitted = false;
      _submittedQuery = '';
    }

    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const Center(
          child: Text(
            'Type to search',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Use API search only when submitted
    if (!_hasSubmitted || _submittedQuery.isEmpty) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const Center(
          child: Text(
            "Press search button to search",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        // final searchResults = ref.watch(
        //   searchTextFutureProvider(
        //     SearchTextParams(query: _submittedQuery, textId: textId),
        //   ),
        // );

        final searchResults = ref.watch(
          multilingualSearchProvider(
            LibrarySearchParams(query: _submittedQuery, textId: textId),
          ),
        );

        return searchResults.when(
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stackTrace) {
            return ErrorStateWidget(
              error: error,
              customMessage: 'Unable to perform search.\nPlease try again.',
            );
          },
          data: (searchResponse) {
            if (searchResponse.sources == null ||
                searchResponse.sources!.isEmpty) {
              return Center(
                child: Text(
                  'No results found for "$_submittedQuery"',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }

            // Group segment matches by textId
            final groupedResults = <String, Map<String, dynamic>>{};
            for (final source in searchResponse.sources!) {
              if (!groupedResults.containsKey(source.text.textId)) {
                groupedResults[source.text.textId] = {
                  'textId': source.text.textId,
                  'textTitle': source.text.title,
                  'segments': <Map<String, String>>[],
                };
              }
              for (final segmentMatch in source.segmentMatches) {
                (groupedResults[source.text.textId]!['segments'] as List).add({
                  'segmentId': segmentMatch.segmentId,
                  'content': segmentMatch.content,
                });
              }
            }

            if (groupedResults.isEmpty) {
              return Center(
                child: Text(
                  'No results found for "$_submittedQuery"',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }

            final groupedList = groupedResults.values.toList();

            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView.builder(
                itemCount: groupedList.length,
                itemBuilder: (context, index) {
                  final textGroup = groupedList[index];
                  final textId = textGroup['textId'] as String;
                  final textTitle = textGroup['textTitle'] as String;
                  final segments =
                      textGroup['segments'] as List<Map<String, String>>;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text title shown once
                          Text(
                            textTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          // List all segments for this text
                          ...segments.asMap().entries.map((entry) {
                            final segmentIndex = entry.key;
                            final segment = entry.value;
                            final segmentId = segment['segmentId']!;
                            final content = segment['content']!;
                            final cleanContent = content.replaceAll(
                              RegExp(r'<[^>]*>'),
                              '',
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () {
                                    // Return both textId and segmentId
                                    close(context, {
                                      'textId': textId,
                                      'segmentId': segmentId,
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text.rich(
                                      TextSpan(
                                        children: buildHighlightedText(
                                          cleanContent,
                                          _submittedQuery,
                                          TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (segmentIndex < segments.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
