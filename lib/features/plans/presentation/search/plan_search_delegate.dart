import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanSearchDelegate extends SearchDelegate<PlansModel?> {
  final WidgetRef ref;
  final String hintText;

  PlanSearchDelegate({required this.ref, required this.hintText});

  @override
  String get searchFieldLabel => hintText;

  @override
  TextStyle? get searchFieldStyle => const TextStyle(fontSize: 14);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () {
            query = '';
            ref.read(planSearchProvider.notifier).clear();
          },
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
        ref.read(planSearchProvider.notifier).clear();
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Trigger search when user submits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planSearchProvider.notifier).search(query);
    });

    return _SearchResultsView(ref: ref);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Trigger search as user types
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planSearchProvider.notifier).search(query);
    });

    return _SearchResultsView(ref: ref);
  }
}

class _SearchResultsView extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _SearchResultsView({required this.ref});

  @override
  ConsumerState<_SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends ConsumerState<_SearchResultsView> {
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
      ref.read(planSearchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(planSearchProvider);
    final localizations = AppLocalizations.of(context)!;
    // Empty query state
    if (searchState.query.trim().isEmpty) {
      return _EmptySearchState(
        icon: Icons.search,
        title: localizations.search_for_plans,
      );
    }

    // Loading initial results
    if (searchState.isLoading && searchState.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (searchState.error != null && searchState.results.isEmpty) {
      return _ErrorState(
        message: searchState.error!,
        onRetry: () => ref.read(planSearchProvider.notifier).retry(),
      );
    }

    // No results found
    if (searchState.results.isEmpty && !searchState.isLoading) {
      return _EmptySearchState(
        icon: Icons.search_off,
        title: localizations.no_plans_found,
      );
    }

    // Results list with pagination
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      itemCount: searchState.results.length + (searchState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at bottom
        if (index == searchState.results.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child:
                  searchState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        final plan = searchState.results[index];
        final author = plan.author;
        return PlanCard(
          plan: plan,
          onTap: () {
            context.push(
              '/plans/info',
              extra: {'plan': plan, 'author': author},
            );
          },
        );
      },
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _EmptySearchState({
    required this.icon,
    required this.title,
    this.subtitle,
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
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
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
