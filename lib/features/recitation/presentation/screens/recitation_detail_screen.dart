import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/domain/content_type.dart';
import 'package:flutter_pecha/features/recitation/domain/recitation_language_config.dart';
import 'package:flutter_pecha/features/recitation/presentation/controllers/recitation_save_controller.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_content.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen that displays the detailed content of a recitation.
///
/// This screen:
/// - Loads recitation content based on user's language preference
/// - Allows authenticated users to save/unsave recitations
/// - Displays content in a language-appropriate order
/// - Handles loading and error states
/// - Supports navigation to next recitation when provided with a list
class RecitationDetailScreen extends ConsumerStatefulWidget {
  final RecitationModel recitation;
  final List<RecitationModel>? allRecitations;
  final int? currentIndex;

  const RecitationDetailScreen({
    super.key,
    required this.recitation,
    this.allRecitations,
    this.currentIndex,
  });

  @override
  ConsumerState<RecitationDetailScreen> createState() =>
      _RecitationDetailScreenState();
}

class _RecitationDetailScreenState
    extends ConsumerState<RecitationDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showNextButton = false;
  bool _isNavigating = false;

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
    if (!_scrollController.hasClients || _isNavigating) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    bool shouldShow;

    if (maxScroll == 0) {
      // Content doesn't need scrolling - show button if there's a next recitation
      shouldShow = _hasNextRecitation();
    } else if (maxScroll < 200) {
      shouldShow = currentScroll >= maxScroll * 0.7 && _hasNextRecitation();
    } else {
      shouldShow = currentScroll >= maxScroll - 100 && _hasNextRecitation();
    }

    if (shouldShow != _showNextButton) {
      setState(() {
        _showNextButton = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLanguageCode = ref.watch(
      localeProvider.select((locale) => locale.languageCode),
    );

    final effectiveLanguageCode =
        widget.recitation.language ?? userLanguageCode;

    final isGuest = ref.watch(authProvider.select((state) => state.isGuest));
    final isSaved = _checkIfSaved(ref, isGuest);

    final showSecondSegment = ref.watch(showSecondSegmentProvider);
    final showThirdSegment = ref.watch(showThirdSegmentProvider);

    final recitationParams = RecitationLanguageConfig.getContentParams(
      effectiveLanguageCode,
      widget.recitation.textId,
    );
    final contentOrder = RecitationLanguageConfig.getContentOrder(
      effectiveLanguageCode,
    );

    // Get the content types at positions 2 and 3 (index 1 and 2)
    final secondContentType = contentOrder.length > 1 ? contentOrder[1] : null;
    final thirdContentType = contentOrder.length > 2 ? contentOrder[2] : null;

    // Filter content order based on visibility toggles
    final filteredContentOrder = _filterContentOrder(
      contentOrder,
      showSecondSegment: showSecondSegment,
      showThirdSegment: showThirdSegment,
    );

    // Watch recitation content
    final contentAsync = ref.watch(recitationContentProvider(recitationParams));
    final localizations = AppLocalizations.of(context)!;

    // Check if content is loaded and not empty
    final isContentLoaded =
        contentAsync.hasValue && !contentAsync.value!.isEmpty;

    if (isContentLoaded && !_isNavigating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onScroll();
      });
    }

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackNavigation(context),
        ),
        actions: [
          // Only show toggle icons when content is loaded
          if (isContentLoaded) ...[
            // Second segment toggle
            if (secondContentType != null)
              IconButton(
                onPressed:
                    () =>
                        ref.read(showSecondSegmentProvider.notifier).state =
                            !showSecondSegment,
                icon: Icon(
                  _getIconForContentType(secondContentType, showSecondSegment),
                  color:
                      showSecondSegment
                          ? null
                          : Theme.of(context).disabledColor,
                ),
                tooltip: _getTooltipForContentType(
                  secondContentType,
                  showSecondSegment,
                  localizations,
                ),
              ),
            // Third segment toggle
            if (thirdContentType != null)
              IconButton(
                onPressed:
                    () =>
                        ref.read(showThirdSegmentProvider.notifier).state =
                            !showThirdSegment,
                icon: Icon(
                  _getIconForContentType(thirdContentType, showThirdSegment),
                  color:
                      showThirdSegment ? null : Theme.of(context).disabledColor,
                ),
                tooltip: _getTooltipForContentType(
                  thirdContentType,
                  showThirdSegment,
                  localizations,
                ),
              ),
          ],
          // Save/unsave toggle (always visible)
          IconButton(
            onPressed: () => _handleSaveToggle(context, ref, isSaved),
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            tooltip:
                isSaved
                    ? localizations.recitations_unsave
                    : localizations.recitations_save,
          ),
        ],
      ),
      body: Stack(
        children: [
          contentAsync.when(
            data: (content) {
              if (content.isEmpty) {
                return _buildEmptyContentState(context, content.title);
              }

              return RecitationContent(
                content: content,
                contentOrder: filteredContentOrder,
                scrollController: _scrollController,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => RecitationErrorState(error: error),
          ),
        ],
      ),
      floatingActionButton:
          _showNextButton
              ? _buildFloatingNextButton(context, localizations)
              : null,
    );
  }

  /// Checks if there's a next recitation available.
  bool _hasNextRecitation() {
    if (widget.allRecitations == null || widget.currentIndex == null) {
      return false;
    }
    return widget.currentIndex! < widget.allRecitations!.length - 1;
  }

  /// Builds the floating next recitation button.
  Widget _buildFloatingNextButton(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final localizations = AppLocalizations.of(context)!;
    return AnimatedOpacity(
      opacity: _showNextButton ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton.extended(
        onPressed: () => _navigateToNextRecitation(context),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        elevation: 4,
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: Text(
          localizations.next_recitation,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Navigates to the next recitation.
  void _navigateToNextRecitation(BuildContext context) {
    if (!_hasNextRecitation() || _isNavigating) return;

    // Hide button immediately during navigation
    setState(() {
      _isNavigating = true;
      _showNextButton = false;
    });

    final nextIndex = widget.currentIndex! + 1;
    final nextRecitation = widget.allRecitations![nextIndex];

    // Replace current route with next recitation
    context.go(
      '/recitations/detail',
      extra: {
        'recitation': nextRecitation,
        'allRecitations': widget.allRecitations,
        'currentIndex': nextIndex,
      },
    );
  }

  /// Handles back navigation.
  /// If navigated from My Recitations with a list, goes back to recitations screen.
  /// Otherwise, uses default back behavior.
  void _handleBackNavigation(BuildContext context) {
    // If we have a list context, we came from My Recitations tab
    // Go back to home/recitations screen
    if (widget.allRecitations != null && widget.currentIndex != null) {
      context.go('/home');
    } else {
      // Default back behavior for other entry points (search, browse)
      context.pop();
    }
  }

  /// Returns the appropriate icon for a content type.
  IconData _getIconForContentType(ContentType type, bool isVisible) {
    return switch (type) {
      ContentType.translation =>
        isVisible ? Icons.translate : Icons.translate_outlined,
      ContentType.transliteration => isVisible ? Icons.abc : Icons.abc_outlined,
      ContentType.recitation =>
        isVisible ? Icons.record_voice_over : Icons.record_voice_over_outlined,
      ContentType.adaptation =>
        isVisible ? Icons.auto_fix_high : Icons.auto_fix_high_outlined,
    };
  }

  /// Returns the appropriate tooltip for a content type.
  String _getTooltipForContentType(
    ContentType type,
    bool isVisible,
    AppLocalizations localizations,
  ) {
    return switch (type) {
      ContentType.translation =>
        isVisible
            ? localizations.recitations_hide_translation
            : localizations.recitations_show_translation,
      ContentType.transliteration =>
        isVisible
            ? localizations.recitations_hide_transliteration
            : localizations.recitations_show_transliteration,
      ContentType.recitation =>
        isVisible
            ? localizations.recitations_hide_recitation
            : localizations.recitations_show_recitation,
      ContentType.adaptation =>
        isVisible
            ? localizations.recitations_hide_adaptation
            : localizations.recitations_show_adaptation,
    };
  }

  /// Filters the content order based on visibility toggles.
  List<ContentType> _filterContentOrder(
    List<ContentType> contentOrder, {
    required bool showSecondSegment,
    required bool showThirdSegment,
  }) {
    return contentOrder
        .asMap()
        .entries
        .where((entry) {
          final index = entry.key;
          if (index == 0) return true;
          if (index == 1 && !showSecondSegment) return false;
          if (index == 2 && !showThirdSegment) return false;
          return true;
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Checks if the current recitation is saved by the user.
  ///
  /// Returns false for guest users without checking the saved list.
  bool _checkIfSaved(WidgetRef ref, bool isGuest) {
    if (isGuest) return false;

    final savedRecitationsAsync = ref.watch(savedRecitationsFutureProvider);
    final savedRecitationIds =
        savedRecitationsAsync.valueOrNull?.map((e) => e.textId).toSet() ?? {};

    return savedRecitationIds.contains(widget.recitation.textId);
  }

  /// Handles the save/unsave toggle action.
  void _handleSaveToggle(BuildContext context, WidgetRef ref, bool isSaved) {
    final controller = RecitationSaveController(ref: ref, context: context);

    controller.toggleSave(textId: widget.recitation.textId, isSaved: isSaved);
  }

  /// Builds a user-friendly empty state when recitation content is not available.
  Widget _buildEmptyContentState(BuildContext context, String title) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              localizations.no_availabel,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.recitations_no_data_message,
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
