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
  bool _isDisposing = false;
  Timer? _debounceTimer;
  final Set<String> _completedSubtaskIds = {};
  int? _lastTrackedIndex;

  @override
  void initState() {
    super.initState();
    flutterStoryController = FlutterStoryController();
    storyItems = widget.storyItemsBuilder(flutterStoryController);
  }

  void _onStoryChanged(int index) {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Set new debounce timer (300ms to prevent excessive API calls)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (index != _lastTrackedIndex &&
          index >= 0 &&
          index < widget.subtasks.length) {
        _lastTrackedIndex = index;
        final subtask = widget.subtasks[index];

        // Mark as complete if not already done
        if (!_completedSubtaskIds.contains(subtask.id) &&
            !subtask.isCompleted) {
          _completedSubtaskIds.add(subtask.id);
          _markSubtaskComplete(subtask.id);
        }
      }
    });
  }

  Future<void> _markSubtaskComplete(String subtaskId) async {
    try {
      final repository = ref.read(userPlansRepositoryProvider);
      await repository.completeSubTask(subtaskId);
      debugPrint('Subtask $subtaskId marked complete');
    } catch (e) {
      debugPrint('Error completing subtask: $e');
      // Don't show error to user - this is background tracking
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _isDisposing = true;
    // Let the FlutterStoryPresenter package handle controller disposal
    // The package manages its own controller lifecycle
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
