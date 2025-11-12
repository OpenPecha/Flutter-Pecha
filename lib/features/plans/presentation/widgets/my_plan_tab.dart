import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/my_plans_paginated_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/user_plan_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyPlansTab extends ConsumerStatefulWidget {
  final TabController controller;
  const MyPlansTab({super.key, required this.controller});

  @override
  ConsumerState<MyPlansTab> createState() => _MyPlansTabState();
}

class _MyPlansTabState extends ConsumerState<MyPlansTab> {
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
      ref.read(myPlansPaginatedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Check if user is guest - show login prompt instead of calling APIs
    if (authState.isGuest) {
      return _GuestLoginPrompt(
        onLogin: () {
          LoginDrawer.show(context, ref);
        },
      );
    }

    final myPlansState = ref.watch(myPlansPaginatedProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(myPlansPaginatedProvider.notifier).refresh(),
      child: _buildContent(context, myPlansState),
    );
  }

  Widget _buildContent(BuildContext context, MyPlansState myPlansState) {
    // Initial loading state
    if (myPlansState.isLoading && myPlansState.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state with no plans
    if (myPlansState.error != null && myPlansState.plans.isEmpty) {
      return _ErrorState(
        message: myPlansState.error!,
        onRetry: () => ref.read(myPlansPaginatedProvider.notifier).retry(),
      );
    }

    // Empty state
    if (myPlansState.plans.isEmpty && !myPlansState.isLoading) {
      return _EmptyMyPlansState(
        onBrowsePlans: () {
          widget.controller.animateTo(1);
        },
      );
    }

    // Plans list with pagination
    return ListView.separated(
      controller: _scrollController,
      separatorBuilder: (context, index) => const SizedBox(height: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: myPlansState.plans.length + (myPlansState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at bottom
        if (index == myPlansState.plans.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child:
                  myPlansState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        final plan = myPlansState.plans[index];
        final selectedDay = PlanUtils.calculateSelectedDay(
          plan.startedAt,
          plan.totalDays,
        );

        return UserPlanCard(
          plan: plan,
          onTap: () {
            context.push(
              '/plans/details',
              extra: {
                'plan': plan,
                'selectedDay': selectedDay,
                'startDate': plan.startedAt,
              },
            );
          },
        );
      },
    );
  }
}

/// Login prompt widget shown to guest users
class _GuestLoginPrompt extends StatelessWidget {
  const _GuestLoginPrompt({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 60,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Sign in to view your plans',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create an account or sign in to track your practice plans and progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMyPlansState extends StatelessWidget {
  final VoidCallback onBrowsePlans;

  const _EmptyMyPlansState({required this.onBrowsePlans});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No enrolled plans yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start your practice journey by enrolling in a plan',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onBrowsePlans,
              icon: const Icon(Icons.explore),
              label: const Text('Browse Plans'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
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
