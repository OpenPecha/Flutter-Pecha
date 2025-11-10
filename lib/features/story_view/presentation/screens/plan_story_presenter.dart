import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';
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
  });

  final FlutterStoryItemsBuilder storyItemsBuilder;
  final List<UserSubtasksDto> subtasks;

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

  @override
  void initState() {
    super.initState();
    flutterStoryController = FlutterStoryController();
    storyItems = widget.storyItemsBuilder(flutterStoryController);

    // CRITICAL FIX: Build index mapping
    _storyIndexToSubtaskId = _buildIndexMapping();
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

    // Set new debounce timer (300ms to prevent excessive API calls)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      // Double check not disposing (timer might fire after disposal starts)
      if (_isDisposing || !mounted) return;

      // Get actual subtask ID from mapping
      final subtaskId = _storyIndexToSubtaskId[storyIndex];

      if (subtaskId == null) {
        debugPrint('Warning: No subtask mapping for story index $storyIndex');
        return;
      }

      // Check if already tracked or in progress
      if (storyIndex != _lastTrackedIndex &&
          !_completedSubtaskIds.contains(subtaskId) &&
          !_pendingSubtaskIds.contains(subtaskId)) {
        _lastTrackedIndex = storyIndex;

        // Find subtask to check isCompleted flag
        final subtask = widget.subtasks.firstWhere(
          (s) => s.id == subtaskId,
          orElse: () => widget.subtasks.first, // Fallback
        );

        if (!subtask.isCompleted) {
          _markSubtaskComplete(subtaskId);
        }
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
    context.pop();
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
              context.pop();
            }
          },
          onSlideDown: (details) {
            if (!_isDisposing && mounted) {
              context.pop();
            }
          },
        ),
        // if (widget.author != null) StoryAuthorAvatar(author: widget.author),
        // Close button in top-left corner
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _closeStory,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
