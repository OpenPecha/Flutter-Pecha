import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RecitationSearchDelegate extends SearchDelegate<RecitationModel?> {
  final WidgetRef ref;
  final String hintText;
  RecitationSearchDelegate({required this.ref, required this.hintText});

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
            ref.read(recitationSearchProvider.notifier).clear();
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
        ref.read(recitationSearchProvider.notifier).clear();
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Trigger search when user submits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recitationSearchProvider.notifier).search(query);
    });

    return _SearchResultsView(ref: ref);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Trigger search as user types
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recitationSearchProvider.notifier).search(query);
    });

    return _SearchResultsView(ref: ref);
  }
}

class _SearchResultsView extends ConsumerWidget {
  final WidgetRef ref;

  const _SearchResultsView({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(recitationSearchProvider);
    final localizations = AppLocalizations.of(context)!;
    // Empty query state
    if (searchState.query.trim().isEmpty) {
      return _EmptySearchState(
        icon: Icons.search,
        title: localizations.recitations_search_for,
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
        onRetry: () => ref.read(recitationSearchProvider.notifier).retry(),
      );
    }

    // No results found
    if (searchState.results.isEmpty && !searchState.isLoading) {
      return _EmptySearchState(
        icon: Icons.search_off,
        title: localizations.recitations_no_found,
      );
    }

    // Results list
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        final recitation = searchState.results[index];
        return Container(
          key: ValueKey(recitation.textId),
          margin: const EdgeInsets.only(bottom: 12),
          child: RecitationCard(
            recitation: recitation,
            onTap: () {
              context.push('/recitations/detail', extra: recitation);
            },
          ),
        );
      },
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EmptySearchState({required this.icon, required this.title});

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
            const SizedBox(height: 8),
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
