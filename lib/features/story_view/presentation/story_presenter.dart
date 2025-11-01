import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/route_config.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/story_author_avatar.dart';
import 'package:flutter_story_presenter/flutter_story_presenter.dart';
import 'package:go_router/go_router.dart';

typedef FlutterStoryItemsBuilder =
    List<StoryItem> Function(FlutterStoryController controller);

class StoryPresenter extends StatefulWidget {
  const StoryPresenter({
    super.key,
    required this.storyItemsBuilder,
    // required this.storyItems,
    // required this.controller,
    this.author,
  });

  final FlutterStoryItemsBuilder storyItemsBuilder;
  // final List<StoryItem> storyItems;
  // final FlutterStoryController controller;
  final dynamic author;

  @override
  State<StoryPresenter> createState() => _StoryPresenterState();
}

class _StoryPresenterState extends State<StoryPresenter> {
  late final FlutterStoryController flutterStoryController;
  late final List<StoryItem> storyItems;

  @override
  void initState() {
    super.initState();
    flutterStoryController = FlutterStoryController();
    storyItems = widget.storyItemsBuilder(flutterStoryController);
  }

  @override
  void dispose() {
    flutterStoryController.dispose();
    super.dispose();
  }

  void _closeStory() {
    if (!mounted) return;
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
    return Stack(
      children: [
        FlutterStoryPresenter(
          flutterStoryController: flutterStoryController,
          items: storyItems,
          onCompleted: () async {
            while (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go(RouteConfig.home);
              }
            });
          },
          onSlideDown: (details) {
            while (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go(RouteConfig.home);
              }
            });
          },
        ),
        if (widget.author != null) StoryAuthorAvatar(author: widget.author),
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
