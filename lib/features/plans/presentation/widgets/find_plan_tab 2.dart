import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/find_plans_paginated_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FindPlansTab extends ConsumerStatefulWidget {
  final TabController controller;
  const FindPlansTab({super.key, required this.controller});

  @override
  ConsumerState<FindPlansTab> createState() => _FindPlansTabState();
}

class _FindPlansTabState extends ConsumerState<FindPlansTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when 200px from bottom
      ref.read(findPlansPaginatedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(findPlansPaginatedProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(findPlansPaginatedProvider.notifier).refresh(),
      child: _buildContent(context, plansState),
    );
  }

  Widget _buildContent(BuildContext context, FindPlansState plansState) {
    // Initial loading state
    if (plansState.isLoading && plansState.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state with no plans
    if (plansState.error != null && plansState.plans.isEmpty) {
      return ErrorStateWidget(
        error: plansState.error!,
        onRetry: () => ref.read(findPlansPaginatedProvider.notifier).retry(),
        customMessage: 'Unable to load plans.\nPlease try again later.',
      );
    }

    // Empty state
    if (plansState.plans.isEmpty && !plansState.isLoading) {
      return _EmptyState(
        icon: Icons.explore_outlined,
        title: 'No plans available',
        subtitle: 'Check back later for new practice plans',
      );
    }

    // Plans list with pagination
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      itemCount: plansState.plans.length + (plansState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at bottom
        if (index == plansState.plans.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child:
                  plansState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        final plan = plansState.plans[index];
        final author = plan.author;
        return PlanCard(
          plan: plan,
          onTap: () async {
            final result = await context.push(
              '/plans/info',
              extra: {'plan': plan, 'author': author},
            );
            //  Handle the result from plan_info screen
            if (result == true && context.mounted) {
              // change tab to my plans
              widget.controller.animateTo(0);
              // context.push(
              //   '/plans/details',
              //   extra: {'plan': plan, 'selectedDay': 1, 'startDate': startDate},
              // );
            }
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
