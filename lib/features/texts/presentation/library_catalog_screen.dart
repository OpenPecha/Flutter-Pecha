import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/data/providers/term_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/texts/presentation/category_screen.dart';

class LibraryCatalogScreen extends ConsumerWidget {
  const LibraryCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termList = ref.watch(termListFutureProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Browse The Library',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Serif',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Search',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 22,
                        fontFamily: 'Serif',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: termList.when(
                data:
                    (terms) => ListView.builder(
                      itemCount: terms.length,
                      itemBuilder: (context, index) {
                        final term = terms[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoryScreen(),
                              ),
                            );
                          },
                          child: _LibrarySection(
                            title: term.title,
                            subtitle: term.description,
                            dividerColor: Color(0xFF8B3A50),
                            slug: term.slug,
                          ),
                        );
                      },
                    ),
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
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontFamily: 'Serif',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 15,
              fontFamily: 'Serif',
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
