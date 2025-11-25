import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/story_loading_overlay.dart';
import 'package:flutter_pecha/features/story_view/services/story_media_preloader.dart';
import 'package:flutter_story_presenter/flutter_story_presenter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef FlutterStoryItemsBuilder =
    List<StoryItem> Function(FlutterStoryController controller);

class PlanStoryPresenter extends ConsumerStatefulWidget {
  const PlanStoryPresenter({
    super.key,
    required this.storyItemsBuilder,
    required this.subtasks,
    this.planId,
    this.dayNumber,
  });

  final FlutterStoryItemsBuilder storyItemsBuilder;
  final List<UserSubtasksDto> subtasks;
  final String? planId;
  final int? dayNumber;

  @override
  ConsumerState<PlanStoryPresenter> createState() => _PlanStoryPresenterState();
}

class _PlanStoryPresenterState extends ConsumerState<PlanStoryPresenter> {
  late final FlutterStoryController flutterStoryController;
  late final List<StoryItem> storyItems;
  late final Map<int, String> _storyIndexToSubtaskId; // NEW: Index mapping

  bool _isDisposing = false;
  Timer? _debounceTimer;
  final Set<String> _completedSubtaskIds = {};
  final Set<String> _pendingSubtaskIds = {};
  int? _lastTrackedIndex;

  // Loading state management
  bool _isFirstItemReady = false;
  bool _showLoadingOverlay = false;
  final StoryMediaPreloader _preloader = StoryMediaPreloader();
  final GlobalKey<StoryLoadingOverlayState> _loadingOverlayKey =
      GlobalKey<StoryLoadingOverlayState>();

  @override
  void initState() {
    super.initState();
    flutterStoryController = FlutterStoryController();
    storyItems = widget.storyItemsBuilder(flutterStoryController);

    // CRITICAL FIX: Build index mapping
    _storyIndexToSubtaskId = _buildIndexMapping();

    // Pre-populate completed Set from initial data
    _initializeCompletedSubtaskIds();

    // Check if first item is ready and handle loading state
    _checkFirstItemReady();
  }

  /// Checks if first story item is ready and shows loading overlay if needed
  Future<void> _checkFirstItemReady() async {
    if (widget.subtasks.isEmpty) {
      _isFirstItemReady = true;
      return;
    }

    final firstSubtask = widget.subtasks.firstWhere(
      (s) => s.content.isNotEmpty,
      orElse: () => widget.subtasks.first,
    );

    // Check if first item is already precached/prepared
    _isFirstItemReady = _preloader.isFirstItemReady(firstSubtask);

    if (!_isFirstItemReady) {
      // Show loading overlay
      if (mounted) {
        setState(() {
          _showLoadingOverlay = true;
        });
      }

      // Pause story controller until first item is ready
      flutterStoryController.pause();

      // Start preloading first item if not already done
      await _preloadFirstItem(firstSubtask);

      // Preload remaining items in background
      _preloadRemainingItems();
    } else {
      // First item is ready, start story immediately
      if (mounted) {
        flutterStoryController.play();
      }
    }
  }

  /// Preloads the first story item
  Future<void> _preloadFirstItem(UserSubtasksDto firstSubtask) async {
    if (firstSubtask.content.isEmpty) {
      _isFirstItemReady = true;
      return;
    }

    try {
      switch (firstSubtask.contentType) {
        case 'IMAGE':
          await _preloader.preloadImage(firstSubtask.content, context);
          break;
        case 'VIDEO':
          await _preloader.prepareVideoMetadata(firstSubtask.content);
          break;
        case 'AUDIO':
        case 'TEXT':
          // These load fast enough, no preloading needed
          break;
      }

      // Mark as ready and hide loading overlay
      if (mounted) {
        setState(() {
          _isFirstItemReady = true;
          _showLoadingOverlay = false;
        });

        // Fade out loading overlay smoothly
        await _loadingOverlayKey.currentState?.fadeOut();

        // Start story
        flutterStoryController.play();
      }
    } catch (e) {
      debugPrint('Error preloading first item: $e');
      // Even if preloading fails, show the story (graceful degradation)
      if (mounted) {
        setState(() {
          _isFirstItemReady = true;
          _showLoadingOverlay = false;
        });
        flutterStoryController.play();
      }
    }
  }

  /// Preloads remaining story items in background
  void _preloadRemainingItems() {
    if (widget.subtasks.length <= 1) return;

    // Preload next 2-3 items in background
    final remainingItems = widget.subtasks.skip(1).take(3).toList();
    if (remainingItems.isNotEmpty) {
      Future.microtask(() {
        unawaited(_preloader.preloadStoryItems(remainingItems, context));
      });
    }
  }

  /// Pre-populate completed subtask IDs from initial data
  /// This prevents unnecessary timer creation for already-completed subtasks
  void _initializeCompletedSubtaskIds() {
    for (final subtask in widget.subtasks) {
      if (subtask.isCompleted) {
        _completedSubtaskIds.add(subtask.id);
      }
    }
  }

  /// Maps story item index to subtask ID
  /// Handles cases where some subtasks are filtered out
  Map<int, String> _buildIndexMapping() {
    final mapping = <int, String>{};
    int storyIndex = 0;

    for (final subtask in widget.subtasks) {
      // Same filtering logic as createFlutterStoryItems
      if (subtask.content.isEmpty) {
        continue; // This subtask was skipped in story creation
      }

      mapping[storyIndex] = subtask.id;
      storyIndex++;
    }

    return mapping;
  }

  void _onStoryChanged(int storyIndex) {
    // Guard: Check if disposing
    if (_isDisposing) return;

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Get actual subtask ID from mapping
    final subtaskId = _storyIndexToSubtaskId[storyIndex];
    if (subtaskId == null) {
      debugPrint('Warning: No subtask mapping for story index $storyIndex');
      return;
    }

    // OPTIMIZATION: Check if already completed BEFORE creating timer
    // This prevents unnecessary timer creation and API calls
    if (_completedSubtaskIds.contains(subtaskId) ||
        _pendingSubtaskIds.contains(subtaskId)) {
      // Already completed or in progress, no need to track
      _lastTrackedIndex = storyIndex;
      return;
    }

    // Find subtask to check isCompleted flag
    final subtask = widget.subtasks.firstWhere(
      (s) => s.id == subtaskId,
      orElse: () => widget.subtasks.first, // Fallback
    );

    // OPTIMIZATION: Check isCompleted flag BEFORE creating timer
    if (subtask.isCompleted) {
      // Already completed on server, add to Set and skip timer
      _completedSubtaskIds.add(subtaskId);
      _lastTrackedIndex = storyIndex;
      return;
    }

    // Only create timer if subtask needs tracking
    // Set new debounce timer (300ms to prevent excessive API calls)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      // Double check not disposing (timer might fire after disposal starts)
      if (_isDisposing || !mounted) return;

      // Re-check conditions (might have changed during debounce)
      if (storyIndex != _lastTrackedIndex &&
          !_completedSubtaskIds.contains(subtaskId) &&
          !_pendingSubtaskIds.contains(subtaskId)) {
        _lastTrackedIndex = storyIndex;
        _markSubtaskComplete(subtaskId);
      }
    });
  }

  Future<void> _markSubtaskComplete(String subtaskId) async {
    // Guard: Don't process if disposing
    if (_isDisposing) return;

    // Mark as pending to prevent duplicates
    _pendingSubtaskIds.add(subtaskId);

    try {
      final repository = ref.read(userPlansRepositoryProvider);

      // Make API call
      final success = await repository.completeSubTask(subtaskId);

      // Only update state if still mounted and not disposing
      if (mounted && !_isDisposing) {
        if (success) {
          _completedSubtaskIds.add(subtaskId);
          debugPrint('✅ Subtask $subtaskId marked complete');
        } else {
          debugPrint('⚠️ Subtask $subtaskId completion returned false');
        }
      }
    } catch (e) {
      debugPrint('❌ Error completing subtask $subtaskId: $e');
      // Note: subtaskId NOT added to _completedSubtaskIds, allowing retry
    } finally {
      // Always remove from pending (allows retry on next view)
      if (mounted) {
        _pendingSubtaskIds.remove(subtaskId);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _isDisposing = true;

    // Clear sets to prevent memory leaks
    _completedSubtaskIds.clear();
    _pendingSubtaskIds.clear();

    // Let the FlutterStoryPresenter package handle controller disposal
    super.dispose();
  }

  void _closeStory() {
    if (!mounted || _isDisposing) return;
    _invalidateProviderIfNeeded();
    context.pop();
  }

  void _invalidateProviderIfNeeded() {
    if (widget.planId != null && widget.dayNumber != null) {
      // Invalidate day content to refresh task completion status
      ref.invalidate(
        userPlanDayContentFutureProvider(
          PlanDaysParams(planId: widget.planId!, dayNumber: widget.dayNumber!),
        ),
      );
      // Invalidate day completion status to refresh checkmarks in carousel
      ref.invalidate(userPlanDaysCompletionStatusProvider(widget.planId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposing) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        FlutterStoryPresenter(
          flutterStoryController: flutterStoryController,
          items: storyItems,
          onStoryChanged: (index) {
            if (!_isDisposing) {
              _onStoryChanged(index);
            }
          },
          onCompleted: () async {
            if (!_isDisposing && mounted) {
              _invalidateProviderIfNeeded();
              context.pop();
            }
          },
          onSlideDown: (details) {
            if (!_isDisposing && mounted) {
              _invalidateProviderIfNeeded();
              context.pop();
            }
          },
          storyViewIndicatorConfig: StoryViewIndicatorConfig(
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        // if (widget.author != null) StoryAuthorAvatar(author: widget.author),
        // Close button in top-right corner
        Positioned(
          top: 24,
          right: 16,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _closeStory,
                borderRadius: BorderRadius.circular(24),
                child: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
        // Loading overlay - shown when first item is not ready
        if (_showLoadingOverlay) StoryLoadingOverlay(key: _loadingOverlayKey),
      ],
    );
  }
}
