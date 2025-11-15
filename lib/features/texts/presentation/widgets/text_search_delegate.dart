import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/models/search/segment_match.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';

class TextSearchDelegate extends SearchDelegate<String?> {
  final ReaderResponse allContent;
  final WidgetRef ref;
  String _submittedQuery = '';
  bool _hasSubmitted = false;

  TextSearchDelegate({required this.allContent, required this.ref});

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

    final searchParams = SearchTextParams(
      query: _submittedQuery,
      textId: allContent.textDetail.id,
    );

    // Use Consumer to ensure rebuilds when provider changes
    return Consumer(
      builder: (context, ref, child) {
        final searchResults = ref.watch(searchTextFutureProvider(searchParams));

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

            // Flatten all segment matches from all sources
            final allSegmentMatches = <SegmentMatch>[];
            for (final source in searchResponse.sources!) {
              allSegmentMatches.addAll(source.segmentMatches);
            }

            if (allSegmentMatches.isEmpty) {
              return Center(
                child: Text(
                  'No results found for "$_submittedQuery"',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }

            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView.separated(
                itemCount: allSegmentMatches.length,
                separatorBuilder:
                    (context, index) => const Divider(
                      height: 1,
                      color: Colors.grey,
                      indent: 20,
                      endIndent: 20,
                    ),
                itemBuilder: (context, index) {
                  final segmentMatch = allSegmentMatches[index];
                  return ListTile(
                    title: Text(
                      segmentMatch.content.replaceAll(RegExp(r'<[^>]*>'), ''),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    onTap: () {
                      final segmentId = segmentMatch.segmentId;
                      close(context, segmentId);
                    },
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
