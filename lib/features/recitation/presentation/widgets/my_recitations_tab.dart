import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyRecitationsTab extends ConsumerWidget {
  const MyRecitationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final localizations = AppLocalizations.of(context)!;

    // Show login prompt for guest users
    if (authState.isGuest) {
      return _buildLoginPrompt(context, localizations, ref);
    }

    final savedRecitationsAsync = ref.watch(savedRecitationsFutureProvider);

    return savedRecitationsAsync.when(
      data: (recitations) {
        if (recitations.isEmpty) {
          return _buildEmptyState(context, localizations);
        }
        return _buildRecitationsList(context, recitations, ref);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => ErrorStateWidget(
            error: error,
            customMessage:
                'Unable to load your saved recitations.\nPlease try again later.',
          ),
    );
  }

  Widget _buildRecitationsList(
    BuildContext context,
    List<RecitationModel> recitations,
    WidgetRef ref,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: recitations.length,
      onReorder: (oldIndex, newIndex) async {
        // Handle reorder
        // 2 - 5 -> 2 - 4 (oldIndex < newIndex)
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }

        final updatedList = List<RecitationModel>.from(recitations);
        final item = updatedList.removeAt(oldIndex);
        updatedList.insert(newIndex, item);

        // Build the request payload with id (text_id) and display_order
        final recitationsPayload =
            updatedList.asMap().entries.map((entry) {
              final index = entry.key;
              final recitation = entry.value;
              return {'text_id': recitation.textId, 'display_order': index};
            }).toList();

        try {
          await ref
              .read(recitationsRepositoryProvider)
              .updateRecitationsOrder(recitationsPayload);

          // Refresh the list
          ref.invalidate(savedRecitationsFutureProvider);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update order'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      itemBuilder: (context, index) {
        final recitation = recitations[index];
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

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved recitations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save recitations to access them here',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(
    BuildContext context,
    AppLocalizations localizations,
    WidgetRef ref,
  ) {
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
              'Sign in to view your saved recitations',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                LoginDrawer.show(context, ref);
              },
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
