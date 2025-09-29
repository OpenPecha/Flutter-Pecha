import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/plan_subtasks_model.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/image_story.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/text_story.dart';
import 'package:flutter_pecha/shared/widgets/reusable_youtube_player.dart';
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

  // final List<PlanSubtasksModel> subtask = [
  //   PlanSubtasksModel(
  //     id: "1",
  //     contentType: "TEXT",
  //     content:
  //         "Avert enemies, harm, and epidemics,\nPacify all conflicts, expand bodily and mental bliss,\nIncrease wealth, dominion, grain, and lifespan,\nAccomplish all desired aims according to one's wishes,\nAnd always protect and guard without negligence.",
  //     displayOrder: 1,
  //   ),
  //   PlanSubtasksModel(
  //     id: "2",
  //     contentType: "VIDEO",
  //     content: "https://www.youtube.com/watch?v=fusKR990UyE",
  //     displayOrder: 2,
  //   ),
  //   PlanSubtasksModel(
  //     id: "3",
  //     contentType: "VIDEO",
  //     content: "https://youtube.com/shorts/k4kzbi48SVc",
  //     displayOrder: 3,
  //   ),
  //   PlanSubtasksModel(
  //     id: "4",
  //     contentType: "VIDEO",
  //     content: "https://www.youtube.com/watch?v=JoyGCOrgPjY",
  //     displayOrder: 4,
  //   ),
  //   PlanSubtasksModel(
  //     id: "5",
  //     contentType: "IMAGE",
  //     content:
  //         "https://drive.google.com/uc?export=view&id=19dDFtkhowkKg_mtTOGJXp9X_B4B_A6G7",
  //     displayOrder: 5,
  //   ),
  // ];

  @override
  Widget build(BuildContext context) {
    const durationForText = Duration(seconds: 15);
    widget.subtask.map((subtask) {
      if (subtask.contentType == "TEXT") {
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
      }
      if (subtask.contentType == "VIDEO") {
        storyItems.add(
          StoryItem(
            _buildFullScreenVideo(subtask.content!),
            // VideoStory(videoUrl: subtask.content!, controller: storyController),
            duration: const Duration(
              minutes: 10,
            ), // Long duration, controlled by video
          ),
        );
      }
      if (subtask.contentType == "IMAGE") {
        storyItems.add(
          StoryItem(
            ImageStory(
              imageUrl: subtask.content!,
              controller: storyController,
              imageFit: BoxFit.contain,
              roundedTop: true,
              roundedBottom: true,
            ),
            duration: const Duration(
              seconds: 15,
            ), // Long duration, controlled by user interaction
          ),
        );
      }
    }).toList();

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

  Widget _buildFullScreenVideo(String videoUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio:
              MediaQuery.of(context).size.width /
              MediaQuery.of(context).size.height,
          child: ReusableYoutubePlayer(
            videoUrl: videoUrl,
            aspectRatio:
                MediaQuery.of(context).size.width /
                MediaQuery.of(context).size.height,
            autoPlay: true,
            mute: false,
          ),
        ),
      ),
    );
  }
}
