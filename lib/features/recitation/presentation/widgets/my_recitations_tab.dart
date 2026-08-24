import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/practice/presentation/utils/recitation_reader_navigation.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_card.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_list_skeleton.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab displaying user's saved recitations with reorderable list.
class MyRecitationsTab extends ConsumerStatefulWidget {
  const MyRecitationsTab({super.key});

  @override
  ConsumerState<MyRecitationsTab> createState() => _MyRecitationsTabState();
}

class _MyRecitationsTabState extends ConsumerState<MyRecitationsTab> {
  /// Local state for optimistic UI updates during reordering
  List<RecitationModel>? _optimisticRecitations;

  // Constants
  static const _horizontalPadding = 16.0;
  static const _verticalPadding = 16.0;
  static const _itemBottomMargin = 12.0;
  static const _errorSnackBarDuration = Duration(seconds: 3);

  @override
  void dispose() {
    _optimisticRecitations = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final localizations = context.l10n;

    // Show login prompt for guest users
    if (authState.isGuest) {
      return _buildLoginPrompt(context, localizations);
    }

    final savedRecitationsAsync = ref.watch(savedRecitationsFutureProvider);

    return savedRecitationsAsync.when(
      data: (recitationsEither) {
        return recitationsEither.fold(
          (failure) => ErrorStateWidget(
            error: failure,
            customMessage: localizations.my_recitations_load_error,
          ),
          (recitations) => _buildDataView(context, recitations),
        );
      },
      loading: () {
        // If we have optimistic data during refetch, show it instead of loading spinner
        if (_optimisticRecitations != null) {
          return _buildRecitationsList(_optimisticRecitations!);
        }
        return const RecitationListSkeleton(showDragHandle: true);
      },
      error:
          (error, stack) => ErrorStateWidget(
            error: error,
            customMessage: localizations.my_recitations_load_error,
          ),
    );
  }

  /// Builds the data view with recitations list or empty state
  Widget _buildDataView(
    BuildContext context,
    List<RecitationModel> recitations,
  ) {
    final displayRecitations = _optimisticRecitations ?? recitations;

    if (displayRecitations.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildRecitationsList(displayRecitations);
  }

  /// Builds the reorderable list of recitations
  Widget _buildRecitationsList(List<RecitationModel> displayRecitations) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
      itemCount: displayRecitations.length,
      onReorder:
          (oldIndex, newIndex) =>
              _handleReorder(oldIndex, newIndex, displayRecitations),
      itemBuilder:
          (context, index) =>
              _buildRecitationItem(context, displayRecitations[index], index),
    );
  }

  /// Builds a single recitation list item
  Widget _buildRecitationItem(
    BuildContext context,
    RecitationModel recitation,
    int index,
  ) {
    return Container(
      key: ValueKey(recitation.textId),
      margin: const EdgeInsets.only(bottom: _itemBottomMargin),
      child: RecitationCard(
        recitation: recitation,
        onTap: () => openRecitationReader(context, recitation),
        dragIndex: index, // Use list index for drag handle, not displayOrder
      ),
    );
  }

  /// Handles the reorder operation with optimistic UI updates
  Future<void> _handleReorder(
    int oldIndex,
    int newIndex,
    List<RecitationModel> displayRecitations,
  ) async {
    _clearOptimisticState();

    final adjustedNewIndex = _adjustNewIndex(oldIndex, newIndex);

    final reorderedList = _reorderRecitations(
      displayRecitations,
      oldIndex,
      adjustedNewIndex,
    );

    _updateOptimisticState(reorderedList);

    final payload = _buildReorderPayload(reorderedList);

    final messenger = ScaffoldMessenger.of(context);
    final errorMessage = context.l10n.updateOrderError;

    await _performReorderApiCall(payload, messenger, errorMessage);
  }

  /// Adjusts the new index based on ReorderableListView behavior
  int _adjustNewIndex(int oldIndex, int newIndex) {
    return oldIndex < newIndex ? newIndex - 1 : newIndex;
  }

  /// Creates a new list with items reordered
  List<RecitationModel> _reorderRecitations(
    List<RecitationModel> recitations,
    int oldIndex,
    int newIndex,
  ) {
    final updatedList = List<RecitationModel>.from(recitations);
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);
    return updatedList;
  }

  /// Builds the API payload for reorder request
  List<Map<String, dynamic>> _buildReorderPayload(
    List<RecitationModel> recitations,
  ) {
    return recitations.asMap().entries.map((entry) {
      return {'text_id': entry.value.textId, 'display_order': entry.key};
    }).toList();
  }

  /// Updates the local optimistic state
  void _updateOptimisticState(List<RecitationModel> reorderedList) {
    setState(() {
      _optimisticRecitations = reorderedList;
    });
  }

  /// Clears the optimistic state
  void _clearOptimisticState() {
    if (mounted) {
      setState(() {
        _optimisticRecitations = null;
      });
    }
  }

  /// Performs the API call to update recitation order
  Future<void> _performReorderApiCall(
    List<Map<String, dynamic>> payload,
    ScaffoldMessengerState messenger,
    String errorMessage,
  ) async {
    final result = await ref.read(
      updateRecitationsOrderProvider(payload).future,
    );

    result.fold(
      (failure) {
        _handleReorderFailure(messenger, errorMessage);
      },
      (_) {
        _handleReorderSuccess();
      },
    );
  }

  /// Handles successful reorder operation
  void _handleReorderSuccess() {
    ref.invalidate(savedRecitationsFutureProvider);
  }

  /// Handles failed reorder operation
  void _handleReorderFailure(
    ScaffoldMessengerState messenger,
    String errorMessage,
  ) {
    // Rollback to original order
    _clearOptimisticState();

    messenger.showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: _errorSnackBarDuration,
      ),
    );
  }

  /// Builds the empty state when no recitations are saved
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.recitations_no_saved,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the login prompt for guest users
  Widget _buildLoginPrompt(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 60,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.recitations_login_prompt,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => LoginDrawer.show(context, ref),
              icon: const Icon(Icons.login),
              label: Text(localizations.sign_in),
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
