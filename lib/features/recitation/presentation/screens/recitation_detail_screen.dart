import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/domain/recitation_language_config.dart';
import 'package:flutter_pecha/features/recitation/presentation/controllers/recitation_save_controller.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_content.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen that displays the detailed content of a recitation.
///
/// This screen:
/// - Loads recitation content based on user's language preference
/// - Allows authenticated users to save/unsave recitations
/// - Displays content in a language-appropriate order
/// - Handles loading and error states
class RecitationDetailScreen extends ConsumerWidget {
  final RecitationModel recitation;

  const RecitationDetailScreen({super.key, required this.recitation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user's language preference
    final userLanguageCode = ref.watch(
      localeProvider.select((locale) => locale.languageCode),
    );

    // Prefer recitation's specified language, fallback to user's preference
    final effectiveLanguageCode = recitation.language ?? userLanguageCode;

    // Check authentication status and saved state
    final isGuest = ref.watch(authProvider.select((state) => state.isGuest));
    final isSaved = _checkIfSaved(ref, isGuest);

    // Get content parameters and display order based on language
    final recitationParams = RecitationLanguageConfig.getContentParams(
      effectiveLanguageCode,
      recitation.textId,
    );
    final contentOrder = RecitationLanguageConfig.getContentOrder(
      effectiveLanguageCode,
    );

    // Watch recitation content
    final contentAsync = ref.watch(recitationContentProvider(recitationParams));

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () => _handleSaveToggle(context, ref, isSaved),
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            tooltip: isSaved ? 'Unsave recitation' : 'Save recitation',
          ),
        ],
      ),
      body: contentAsync.when(
        data: (content) {
          // Check if content is empty and show friendly message
          if (content.isEmpty) {
            return _buildEmptyContentState(context, content.title);
          }

          return RecitationContent(
            content: content,
            contentOrder: contentOrder,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => RecitationErrorState(error: error),
      ),
    );
  }

  /// Checks if the current recitation is saved by the user.
  ///
  /// Returns false for guest users without checking the saved list.
  bool _checkIfSaved(WidgetRef ref, bool isGuest) {
    if (isGuest) return false;

    final savedRecitationsAsync = ref.watch(savedRecitationsFutureProvider);
    final savedRecitationIds =
        savedRecitationsAsync.valueOrNull?.map((e) => e.textId).toSet() ?? {};

    return savedRecitationIds.contains(recitation.textId);
  }

  /// Handles the save/unsave toggle action.
  void _handleSaveToggle(BuildContext context, WidgetRef ref, bool isSaved) {
    final controller = RecitationSaveController(ref: ref, context: context);

    controller.toggleSave(textId: recitation.textId, isSaved: isSaved);
  }

  /// Builds a user-friendly empty state when recitation content is not available.
  Widget _buildEmptyContentState(BuildContext context, String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Content not available',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The content for this recitation is currently not available.\nPlease check back later.',
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
