import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/data/providers/term_providers.dart';
import 'package:flutter_pecha/features/texts/models/term.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.term});
  final Term term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termCategory = ref.watch(termCategoryFutureProvider(term.id));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: Color(0xFFB6D7D7), width: 3)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
            child: Text(
              term.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
            child: Text(
              term.description,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: termCategory.when(
              data:
                  (terms) => ListView.builder(
                    itemCount: terms.length,
                    itemBuilder: (context, index) {
                      final term = terms[index];
                      return _CategoryBookItem(
                        title: term.title,
                        subtitle: term.description,
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
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: ''),
        ],
        currentIndex: 1, // Book icon selected
        onTap: (index) {},
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}

class _CategoryBookItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const _CategoryBookItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(thickness: 1, color: Color(0xFFB6D7D7)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
          ),
          // const SizedBox(height: 4),
          // Text(
          //   subtitle,
          //   style: const TextStyle(fontSize: 14, color: Colors.grey),
          // ),
        ],
      ),
    );
  }
}
