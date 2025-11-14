import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RecitationsTab extends ConsumerWidget {
  final TabController controller;
  const RecitationsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recitationsAsync = ref.watch(recitationsFutureProvider);
    final localizations = AppLocalizations.of(context)!;

    return recitationsAsync.when(
      data: (recitations) {
        if (recitations.isEmpty) {
          return _buildEmptyState(context, localizations);
        }
        return _buildRecitationsList(context, recitations, ref);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context, error, localizations),
    );
  }

  Widget _buildRecitationsList(
    BuildContext context,
    List<RecitationModel> recitations,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
      itemCount: recitations.length,
      itemBuilder: (context, index) {
        final recitation = recitations[index];
        return RecitationCard(
          recitation: recitation,
          onTap: () {
            context.push('/recitations/detail', extra: recitation);
          },
          onMoreTap: () {
            _showRecitationOptions(context, recitation, ref);
          },
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
            Icons.menu_book_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No recitations available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    Object error,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load recitations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "Please try again later",
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRecitationOptions(
    BuildContext context,
    RecitationModel recitation,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final authState = ref.watch(authProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined),
                title: const Text('Save Recitation'),
                onTap: () async {
                  if (authState.isGuest) {
                    LoginDrawer.show(context, ref);
                    return;
                  }
                  final result = await ref
                      .watch(recitationsRepositoryProvider)
                      .saveRecitation(recitation.textId);
                  ref.invalidate(savedRecitationsFutureProvider);
                  if (context.mounted && result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recitation saved'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    controller.animateTo(1);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to save recitation'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.share_outlined),
              //   title: const Text('Share'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     // TODO: Implement share functionality
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }
}
