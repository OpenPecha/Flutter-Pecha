import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/route_config.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/story_author_avatar.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/story_loading_overlay.dart';
import 'package:flutter_pecha/features/story_view/services/story_media_preloader.dart';
import 'package:flutter_story_presenter/flutter_story_presenter.dart';
import 'package:go_router/go_router.dart';

typedef FlutterStoryItemsBuilder =
    List<StoryItem> Function(FlutterStoryController controller);

class StoryPresenter extends StatefulWidget {
  const StoryPresenter({
    super.key,
    required this.storyItemsBuilder,
    this.author,
    this.subtasks,
  });

  final FlutterStoryItemsBuilder storyItemsBuilder;
  final dynamic author;
  final List<UserSubtasksDto>? subtasks;

  @override
  State<StoryPresenter> createState() => _StoryPresenterState();
}

class _StoryPresenterState extends State<StoryPresenter> {
  late final FlutterStoryController flutterStoryController;
  late final List<StoryItem> storyItems;
  bool _isDisposing = false;

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

    // Check if first item is ready and handle loading state
    _checkFirstItemReady();
  }

  /// Checks if first story item is ready and shows loading overlay if needed
  Future<void> _checkFirstItemReady() async {
    // Only check if we have subtasks for preloading
    if (widget.subtasks == null || widget.subtasks!.isEmpty) {
      _isFirstItemReady = true;
      return;
    }

    final firstSubtask = widget.subtasks!.firstWhere(
      (s) => s.content.isNotEmpty,
      orElse: () => widget.subtasks!.first,
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
    if (widget.subtasks == null || widget.subtasks!.length <= 1) return;

    // Preload next 2-3 items in background
    final remainingItems = widget.subtasks!.skip(1).take(3).toList();
    if (remainingItems.isNotEmpty) {
      Future.microtask(() {
        if (mounted) {
          unawaited(_preloader.preloadStoryItems(remainingItems, context));
        }
      });
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    // Let the FlutterStoryPresenter package handle controller disposal
    // The package manages its own controller lifecycle
    super.dispose();
  }

  void _closeStory() {
    if (!mounted || _isDisposing) return;
    while (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(RouteConfig.home);
      }
    });
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
          onCompleted: () async {
            if (_isDisposing) return;
            while (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDisposing) {
                context.go(RouteConfig.home);
              }
            });
          },
          onSlideDown: (details) {
            if (_isDisposing) return;
            while (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDisposing) {
                context.go(RouteConfig.home);
              }
            });
          },
        ),
        if (widget.author != null) StoryAuthorAvatar(author: widget.author),
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
