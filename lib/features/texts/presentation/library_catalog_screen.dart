import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/data/providers/term_providers.dart';
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
    final termList = ref.watch(termListFutureProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSearchField(context),
            const SizedBox(height: 10),
            Expanded(
              child: termList.when(
                data: (terms) {
                  final filteredTerms =
                      _searchQuery.isEmpty
                          ? terms
                          : terms
                              .where(
                                (term) =>
                                    term.title.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    term.description.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ),
                              )
                              .toList();
                  return ListView.builder(
                    itemCount: filteredTerms.length,
                    itemBuilder: (context, index) {
                      final term = filteredTerms[index];
                      return GestureDetector(
                        onTap: () {
                          context.push('/texts/category', extra: term);
                        },
                        child: _LibrarySection(
                          title: term.title,
                          subtitle: term.description,
                          dividerColor: Color(0xFF8B3A50),
                          slug: term.slug,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stackTrace) =>
                        const Center(child: Text('Failed to load terms')),
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
        'Browse The Library',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          hintText: 'Search',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: Colors.black, fontSize: 16),
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
