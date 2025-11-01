import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/route_config.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/story_author_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:story_view/story_view.dart';

typedef StoryItemsBuilder =
    List<StoryItem> Function(StoryController controller);

class StoryFeature extends StatefulWidget {
  const StoryFeature({super.key, required this.storyItemsBuilder, this.author});

  final StoryItemsBuilder storyItemsBuilder;
  final dynamic author;

  @override
  State<StoryFeature> createState() => _StoryFeatureState();
}

class _StoryFeatureState extends State<StoryFeature> {
  late final StoryController storyController;
  late final List<StoryItem> storyItems;

  @override
  void initState() {
    super.initState();
    storyController = StoryController();
    storyItems = widget.storyItemsBuilder(storyController);
  }

  @override
  void dispose() {
    storyController.dispose();
    super.dispose();
  }

  void _closeStory() {
    // Pop all story screens and return to home
    context.go(RouteConfig.home);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StoryView(
          storyItems: storyItems,
          controller: storyController,
          onComplete: () {
            context.pop();
          },
          onVerticalSwipeComplete: (direction) {
            if (direction == Direction.down) {
              context.pop();
            }
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
