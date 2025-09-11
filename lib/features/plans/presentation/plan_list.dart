import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanList extends ConsumerWidget {
  const PlanList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPlans = ref.watch(plansFutureProvider);
    final authState = ref.watch(authProvider);
    final isGuest = authState.isGuest;

    if (!isGuest) {
      // TODO: api call to get the plans subscribed by the user
      // final subscribedPlans = ref.watch(subscribedPlansFutureProvider);
    }

    // TODO: check if the user is logged in and show the plans accordingly
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                  delegate: PlanSearchDelegate(
                    plans: allPlans.valueOrNull ?? [],
                    ref: ref,
                  ),
                );
              },
              icon: const Icon(Icons.search),
            ),
          ],
          bottom: TabBar(
            tabs: [Tab(text: 'My Plans'), Tab(text: 'All Plans')],
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
            labelColor: Theme.of(context).colorScheme.secondary,
            unselectedLabelColor:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        body: TabBarView(
          children: [
            // my plans tab
            isGuest
                ? _buildGuestLoginPrompt(context, ref)
                : _buildMyPlans(allPlans),
            _buildAllPlans(allPlans),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestLoginPrompt(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.login, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'You need to login to access this feature',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => ref.read(authProvider.notifier).logout(),
          icon: const Icon(Icons.login),
          label: const Text('Login'),
        ),
      ],
    );
  }

  Widget _buildMyPlans(AsyncValue<List<PlansModel>> subscribedPlans) {
    return Column(
      children: [
        Expanded(
          child: subscribedPlans.when(
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
        ),
      ],
    );
  }

  Widget _buildAllPlans(AsyncValue<List<PlansModel>> allPlans) {
    return Column(
      children: [
        Expanded(
          child: allPlans.when(
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
            error:
                (error, stackTrace) => Center(
                  child: Text('Unable to load plans. Please try again later.'),
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(PlansModel plan, BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/plans/info', extra: plan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildPlanImage(plan),
              const SizedBox(width: 24),
              Expanded(child: _buildPlanInfo(plan)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanImage(PlansModel plan) {
    return Hero(
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
    );
  }

  Widget _buildPlanInfo(PlansModel plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${plan.totalDays} Days',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          plan.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class PlanSearchDelegate extends SearchDelegate<PlansModel?> {
  final List<PlansModel> plans;
  final WidgetRef ref;

  PlanSearchDelegate({required this.plans, required this.ref});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredPlans =
        plans.where((plan) {
          final titleMatch = plan.title.toLowerCase().contains(
            query.toLowerCase(),
          );
          final descMatch =
              plan.description?.toLowerCase().contains(query.toLowerCase()) ??
              false;
          return titleMatch || descMatch;
        }).toList();

    if (filteredPlans.isEmpty) {
      return const Center(child: Text('No plans found'));
    }

    return ListView.builder(
      itemCount: filteredPlans.length,
      itemBuilder: (context, index) {
        final plan = filteredPlans[index];
        return ListTile(
          title: Text(plan.title),
          subtitle: Text(plan.description ?? ''),
          onTap: () {
            close(context, plan);
            context.push('/plans/info', extra: plan);
          },
        );
      },
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }
}
