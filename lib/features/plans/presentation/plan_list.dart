import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanList extends ConsumerWidget {
  const PlanList({super.key});

  static const List<Map<String, dynamic>> plans = [
    {'name': 'Way of the Heart', 'days': 5},
    {'name': 'Train Your Mind', 'days': 12},
    {'name': 'Compassion', 'days': 3},
    {'name': 'Peaceful Mind', 'days': 15},
    {'name': 'Mindfulness', 'days': 12},
    {'name': 'Gratitude Meditation', 'days': 30},
    {'name': 'Others before self', 'days': 15},
    {'name': 'The Way of the Bodhisattva', 'days': 8},
    {'name': 'Bodhisattva Mind', 'days': 10},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansFutureProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plans',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
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
      body: plans.when(
        data:
            (plans) => ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _buildPlanCard(plan, context);
              },
            ),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildPlanCard(PlansModel plan, BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/plans/info', extra: plan);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16.0),
        // decoration: BoxDecoration(
        //   color: Theme.of(context).cardColor,
        //   border: Border.all(color: Colors.black26),
        //   borderRadius: BorderRadius.circular(12),
        // ),
        // padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: plan.title,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/bg.jpg',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text('6 Days', style: TextStyle(fontSize: 12)),
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
