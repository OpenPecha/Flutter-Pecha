import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/collections_providers.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LibraryCatalogScreen extends ConsumerStatefulWidget {
  const LibraryCatalogScreen({super.key});

  @override
  ConsumerState<LibraryCatalogScreen> createState() =>
      _LibraryCatalogScreenState();
}

class _LibraryCatalogScreenState extends ConsumerState<LibraryCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _submittedQuery = '';
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionsListResponse = ref.watch(collectionsListFutureProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSearchField(context),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _hasSubmitted && _submittedQuery.isNotEmpty
                      ? _buildSearchResults(context)
                      : collectionsListResponse.when(
                        data: (response) {
                          final collections = response.collections;
                          if (collections.isEmpty) {
                            return const Center(
                              child: Text('No collections available'),
                            );
                          }
                          return ListView.builder(
                            itemCount: collections.length,
                            itemBuilder: (context, index) {
                              final collection = collections[index];
                              return GestureDetector(
                                onTap: () {
                                  context.push(
                                    '/texts/category',
                                    extra: collection,
                                  );
                                },
                                child: _LibrarySection(
                                  title: collection.title,
                                  subtitle: collection.description,
                                  dividerColor: Color(0xFF8B3A50),
                                  slug: collection.slug,
                                ),
                              );
                            },
                          );
                        },
                        loading:
                            () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        error:
                            (error, stackTrace) => const Center(
                              child: Text('Failed to load collections'),
                            ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        AppLocalizations.of(context)!.text_browseTheLibrary,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            // Reset submitted state when user starts typing again
            if (_hasSubmitted && value != _submittedQuery) {
              _hasSubmitted = false;
              _submittedQuery = '';
            }
            // Clear search if query is empty
            if (value.isEmpty) {
              _hasSubmitted = false;
              _submittedQuery = '';
            }
          });
        },
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            setState(() {
              _submittedQuery = value;
              _hasSubmitted = true;
            });
          }
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.text_search,
          prefixIcon: Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _submittedQuery = '';
                        _hasSubmitted = false;
                      });
                    },
                  )
                  : null,
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_submittedQuery.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.text_search,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final searchParams = LibrarySearchParams(query: _submittedQuery);
    final searchResults = ref.watch(librarySearchProvider(searchParams));

    return searchResults.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Text(
              'Error searching: ${error.toString()}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
      data: (searchResponse) {
        if (searchResponse.sources == null || searchResponse.sources!.isEmpty) {
          return Center(
            child: Text(
              'No results found for "$_submittedQuery"',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        // Flatten all segment matches from all sources
        final allResults = <Map<String, dynamic>>[];
        for (final source in searchResponse.sources!) {
          for (final segmentMatch in source.segmentMatches) {
            allResults.add({
              'textId': source.text.textId,
              'textTitle': source.text.title,
              'segmentId': segmentMatch.segmentId,
              'content': segmentMatch.content,
            });
          }
        }

        if (allResults.isEmpty) {
          return Center(
            child: Text(
              'No results found for "$_submittedQuery"',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          itemCount: allResults.length,
          itemBuilder: (context, index) {
            final result = allResults[index];
            final textTitle = result['textTitle'] as String;
            final content = result['content'] as String;
            // Strip HTML tags from content
            final cleanContent = content.replaceAll(RegExp(r'<[^>]*>'), '');

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: InkWell(
                onTap: () {
                  final textId = result['textId'] as String;
                  final segmentId = result['segmentId'] as String;
                  context.push(
                    '/texts/chapter',
                    extra: {'textId': textId, 'segmentId': segmentId},
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        textTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cleanContent,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LibrarySection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color dividerColor;
  final String slug;

  const _LibrarySection({
    required this.title,
    required this.subtitle,
    required this.dividerColor,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: dividerColor, thickness: 3, height: 4),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
