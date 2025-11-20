import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/constants/text_routes.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/collections_providers.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/library_search_state_provider.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections_response.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/collections_section.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/loading_state_widget.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/search_result_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsListResponse = ref.watch(collectionsListFutureProvider);
    final searchState = ref.watch(librarySearchStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _SearchField(),
            Expanded(
              child:
                  searchState.hasSubmitted &&
                          searchState.submittedQuery.isNotEmpty
                      ? _SearchResultsView(query: searchState.submittedQuery)
                      : _CollectionsListView(
                        collectionsResponse: collectionsListResponse,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: TextScreenConstants.screenPadding,
      child: Text(
        AppLocalizations.of(context)!.text_browseTheLibrary,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: TextScreenConstants.headerFontSize,
        ),
      ),
    );
  }
}

/// Search field widget with state management
class _SearchField extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final searchNotifier = ref.read(librarySearchStateProvider.notifier);

    return Padding(
      padding: TextScreenConstants.screenPadding,
      child: TextField(
        controller: _controller,
        onChanged: (value) => searchNotifier.updateSearchQuery(value),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            searchNotifier.submitSearch(value);
          }
        },
        decoration: InputDecoration(
          fillColor: Theme.of(context).colorScheme.surface,
          hintText: localizations.text_search,
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _controller.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      searchNotifier.clearSearch();
                    },
                  )
                  : null,
        ),
      ),
    );
  }
}

/// Collections list view
class _CollectionsListView extends StatelessWidget {
  final AsyncValue<CollectionsResponse> collectionsResponse;

  const _CollectionsListView({required this.collectionsResponse});

  @override
  Widget build(BuildContext context) {
    return collectionsResponse.when(
      data: (response) {
        final collections = response.collections;
        if (collections.isEmpty) {
          return const Center(child: Text('No collections available'));
        }
        return ListView.builder(
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection = collections[index];
            return GestureDetector(
              onTap: () {
                context.push(TextRoutes.works, extra: collection);
              },
              child: CollectionsSection(
                title: collection.title,
                subtitle: collection.description,
                dividerColor: TextScreenConstants.collectionDividerColor,
                slug: collection.slug,
              ),
            );
          },
        );
      },
      loading: () => const LoadingStateWidget(),
      error:
          (error, stackTrace) =>
              const Center(child: Text('Unable to load collections')),
    );
  }
}

/// Search results view
class _SearchResultsView extends ConsumerWidget {
  final String query;

  const _SearchResultsView({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.text_search,
          style: const TextStyle(
            fontSize: TextScreenConstants.bodyFontSize,
            color: Colors.grey,
          ),
        ),
      );
    }

    final searchParams = LibrarySearchParams(query: query, textId: null);
    // final searchResults = ref.watch(librarySearchProvider(searchParams));
    final multilingualSearchResults = ref.watch(
      multilingualSearchProvider(searchParams),
    );

    // return searchResults.when(
    return multilingualSearchResults.when(
      loading: () => const LoadingStateWidget(),
      error:
          (error, stackTrace) => ErrorStateWidget(
            error: error,
            customMessage: 'Unable to perform search.\nPlease try again.',
          ),
      data: (searchResponse) {
        if (searchResponse.sources.isEmpty) {
          return _buildNoResults(query);
        }

        final groupedResults = _groupSearchResults(searchResponse.sources);

        if (groupedResults.isEmpty) {
          return _buildNoResults(query);
        }

        return _buildSearchResultsList(groupedResults, query);
      },
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Text(
        'No results found for "$query"',
        style: const TextStyle(fontSize: TextScreenConstants.bodyFontSize),
      ),
    );
  }

  /// Group segment matches by textId
  Map<String, Map<String, dynamic>> _groupSearchResults(List<dynamic> sources) {
    final groupedResults = <String, Map<String, dynamic>>{};

    for (final source in sources) {
      if (!groupedResults.containsKey(source.text.textId)) {
        groupedResults[source.text.textId] = {
          'textId': source.text.textId,
          'textTitle': source.text.title,
          'segments': <Map<String, String>>[],
        };
      }
      for (final segmentMatch in source.segmentMatches) {
        (groupedResults[source.text.textId]!['segments']
                as List<Map<String, String>>)
            .add({
              'segmentId': segmentMatch.segmentId as String,
              'content': segmentMatch.content as String,
            });
      }
    }

    return groupedResults;
  }

  Widget _buildSearchResultsList(
    Map<String, Map<String, dynamic>> groupedResults,
    String query,
  ) {
    final groupedList = groupedResults.values.toList();

    return ListView.builder(
      itemCount: groupedList.length,
      itemBuilder: (context, index) {
        final textGroup = groupedList[index];
        final textId = textGroup['textId'] as String;
        final textTitle = textGroup['textTitle'] as String;
        final segments = textGroup['segments'] as List<Map<String, String>>;

        return SearchResultCard(
          textId: textId,
          textTitle: textTitle,
          segments: segments,
          searchQuery: query,
        );
      },
    );
  }
}
