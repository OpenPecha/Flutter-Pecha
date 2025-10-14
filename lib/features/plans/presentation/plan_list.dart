import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanList extends ConsumerStatefulWidget {
  const PlanList({super.key});

  @override
  ConsumerState<PlanList> createState() => _PlanListState();
}

class _PlanListState extends ConsumerState<PlanList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPlans = ref.watch(plansFutureProvider);
    final authState = ref.watch(authProvider);
    final isGuest = authState.isGuest;
    final isLoggedIn = authState.isLoggedIn;
    var subscribedPlans = AsyncValue<List<PlansModel>>.data([]);

    if (!isGuest && isLoggedIn) {
      subscribedPlans = ref.watch(userPlansFutureProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plans',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        scrolledUnderElevation: 0,
        centerTitle: false,
        actions: [
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 1) {
                return IconButton(
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
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
        controller: _tabController,
        children: [
          // my plans tab
          isGuest || !isLoggedIn
              ? _buildGuestLoginPrompt(context, ref)
              : _buildMyPlans(subscribedPlans),
          _buildAllPlans(allPlans),
        ],
      ),
    );
  }

  Widget _buildGuestLoginPrompt(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
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
          label: Text(localizations.common_sign_in),
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
                (plans) =>
                    plans.isEmpty
                        ? const Center(child: Text('No plans found'))
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 16.0,
                          ),
                          itemCount: plans.length,
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            return _buildPlanCard(
                              context,
                              plan,
                              showInfo: false,
                            );
                          },
                        ),
            error:
                (error, stackTrace) => Center(
                  child: Text("Unable to load plans. Please try again later."),
                ),
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
                    return _buildPlanCard(context, plan, showInfo: true);
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

  Widget _buildPlanCard(
    BuildContext context,
    PlansModel plan, {
    bool showInfo = false,
  }) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          if (showInfo) {
            final result = await context.push('/plans/info', extra: plan);

            // Handle the result from plan_info screen
            if (result == true && context.mounted) {
              // change tab to my plans
              _tabController.animateTo(0);
              context.push('/plans/details', extra: plan);
            }
          } else {
            context.push('/plans/details', extra: plan);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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
        child: Image.network(
          plan.imageUrl ?? '',
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
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
          return titleMatch;
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
