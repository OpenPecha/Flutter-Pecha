import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller for managing recitation save/unsave operations.
///
/// This class handles:
/// - Checking if user is authenticated
/// - Saving/unsaving recitations
/// - Error handling and user feedback
/// - Provider invalidation after operations
class RecitationSaveController {
  final WidgetRef ref;
  final BuildContext context;

  RecitationSaveController({
    required this.ref,
    required this.context,
  });

  /// Toggles the save state of a recitation.
  ///
  /// If the user is a guest, shows the login drawer.
  /// Otherwise, saves or unsaves the recitation based on current state.
  ///
  /// [textId] - The ID of the recitation to toggle
  /// [isSaved] - Whether the recitation is currently saved
  Future<void> toggleSave({
    required String textId,
    required bool isSaved,
  }) async {
    // Check if user is authenticated
    final authState = ref.read(authProvider);
    if (authState.isGuest) {
      _showLoginDrawer();
      return;
    }

    try {
      // Perform save or unsave operation
      isSaved
          ? await _unsaveRecitation(textId)
          : await _saveRecitation(textId);

      // Invalidate the saved recitations provider to refresh the UI
      ref.invalidate(savedRecitationsFutureProvider);
    } catch (e, stackTrace) {
      // Log error for debugging
      debugPrint('Error ${isSaved ? 'unsaving' : 'saving'} recitation: $e');
      debugPrint('Stack trace: $stackTrace');

      // Show user-friendly error message
      _showErrorSnackBar(isSaved);
    }
  }

  /// Saves a recitation.
  Future<void> _saveRecitation(String textId) async {
    await ref.read(saveRecitationProvider(textId).future);
  }

  /// Unsaves a recitation.
  Future<void> _unsaveRecitation(String textId) async {
    await ref.read(unsaveRecitationProvider(textId).future);
  }

  /// Shows the login drawer for guest users.
  void _showLoginDrawer() {
    LoginDrawer.show(context, ref);
  }

  /// Shows an error snack bar when save/unsave operation fails.
  void _showErrorSnackBar(bool wasSaved) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to ${wasSaved ? 'unsave' : 'save'} recitation',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
