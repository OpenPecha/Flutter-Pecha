import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/data/providers/term_providers.dart';
import 'package:flutter_pecha/features/texts/models/term/term.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.term});
  final Term term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termCategoryResponse = ref.watch(termCategoryFutureProvider(term.id));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
        shape: Border(bottom: BorderSide(color: Color(0xFFB6D7D7), width: 3)),
      ),
      body: termCategoryResponse.when(
        data:
            (response) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Text(
                      term.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
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
                  const SizedBox(height: 8),
                  ...response.terms.map(
                    (t) => GestureDetector(
                      onTap: () {
                        context.push('/texts/detail', extra: t);
                      },
                      child: _CategoryBookItem(
                        title: t.title,
                        subtitle: t.description,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) =>
                const Center(child: Text('Failed to load terms')),
      ),
      bottomNavigationBar: const PechaBottomNavBar(),
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
          // )
        ],
      ),
    );
  }
}
