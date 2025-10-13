import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/collections_providers.dart';
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
              child: collectionsListResponse.when(
                data: (response) {
                  final collections = response.collections;
                  if (collections.isEmpty) {
                    return const Center(
                      child: Text('No collections available'),
                    );
                  }
                  final filteredCollections =
                      _searchQuery.isEmpty
                          ? collections
                          : collections
                              .where(
                                (collection) =>
                                    collection.title.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    collection.description
                                        .toLowerCase()
                                        .contains(_searchQuery.toLowerCase()),
                              )
                              .toList();
                  return ListView.builder(
                    itemCount: filteredCollections.length,
                    itemBuilder: (context, index) {
                      final collection = filteredCollections[index];
                      return GestureDetector(
                        onTap: () {
                          context.push('/texts/category', extra: collection);
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stackTrace) =>
                        const Center(child: Text('Failed to load collections')),
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
          });
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.text_search,
          prefixIcon: Icon(Icons.search),
        ),
      ),
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
