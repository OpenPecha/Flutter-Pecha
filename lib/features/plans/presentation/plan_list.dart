import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanList extends ConsumerWidget {
  const PlanList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans'),
        scrolledUnderElevation: 0,

        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: PlanSearchDelegate(plans: [], ref: ref),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      // Use ListView.builder directly instead of SingleChildScrollView
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 10,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              context.push('/plans/info');
            },
            child: Container(
              height: 100,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/bg.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Plan Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Plan Description',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlanSearchDelegate extends SearchDelegate<int?> {
  final List<String> plans;
  final WidgetRef ref;

  PlanSearchDelegate({required this.plans, required this.ref});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [];
  }

  @override
  Widget buildResults(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }
}
