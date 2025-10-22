import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/plan_subtasks_model.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/image_story.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/text_story.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/video_story.dart';
import 'package:go_router/go_router.dart';
import 'package:story_view/story_view.dart';

class StoryFeature extends StatefulWidget {
  const StoryFeature({super.key, required this.subtask});
  final List<PlanSubtasksModel> subtask;

  @override
  State<StoryFeature> createState() => _StoryFeatureState();
}

class _StoryFeatureState extends State<StoryFeature> {
  final StoryController storyController = StoryController();
  List<StoryItem> storyItems = [];
  final durationForText = Duration(seconds: 15);
  final durationForVideo = Duration(minutes: 5);
  final durationForImage = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _initializeStoryItems();
  }

  void _initializeStoryItems() {
    storyItems.clear();

    for (final subtask in widget.subtask) {
      if (subtask.content == null || subtask.content!.isEmpty) {
        continue; // Skip items with no content
      }

      switch (subtask.contentType) {
        case "TEXT":
          storyItems.add(
            StoryItem(
              TextStory(
                text: subtask.content!,
                backgroundColor: Colors.black38,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
                roundedTop: true,
                roundedBottom: true,
              ),
              duration: durationForText,
            ),
          );
          break;
        case "VIDEO":
          storyItems.add(
            StoryItem(
              VideoStory(
                videoUrl: subtask.content!,
                controller: storyController,
              ),
              duration: durationForVideo,
            ),
          );
          break;
        case "IMAGE":
          storyItems.add(
            StoryItem(
              ImageStory(
                imageUrl: subtask.content!,
                controller: storyController,
                imageFit: BoxFit.contain,
                roundedTop: true,
                roundedBottom: true,
              ),
              duration: durationForImage,
            ),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoryView(
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
    );
  }
}
