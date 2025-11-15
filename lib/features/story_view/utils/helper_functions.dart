import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/story_presenter/custom_audio_story.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/story_presenter/custom_video_story.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/story_presenter/custom_widget_story.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/text_story.dart';
import 'package:flutter_pecha/features/story_view/utils/story_dialog_helper.dart';
import 'package:flutter_story_presenter/flutter_story_presenter.dart';
import 'package:just_audio/just_audio.dart';

List<StoryItem> createFlutterStoryItems(
  List<UserSubtasksDto> subtasks,
  FlutterStoryController? controller,
  Map<String, dynamic>? nextCard,
) {
  final List<StoryItem> storyItems = [];
  const durationForText = Duration(seconds: 15);
  const durationForVideo = Duration(minutes: 5);
  const durationForImage = Duration(seconds: 15);
  const durationForAudio = Duration(seconds: 15);
  const durationForActionCard = Duration(seconds: 15);
  for (final subtask in subtasks) {
    if (subtask.content.isEmpty) {
      continue;
    }

    switch (subtask.contentType) {
      case "TEXT":
        storyItems.add(
          StoryItem(
            storyItemType: StoryItemType.custom,
            duration: durationForText,
            customWidget: (controller, audioPlayer) {
              return TextStory(
                text: subtask.content,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
                roundedTop: true,
                roundedBottom: true,
              );
            },
          ),
        );
        break;
      case "VIDEO":
        // Use custom widget for YouTube videos
        storyItems.add(
          StoryItem(
            storyItemType: StoryItemType.custom,
            duration: durationForVideo,
            customWidget: (controller, audioPlayer) {
              return CustomVideoStory(
                videoUrl: subtask.content,
                controller: controller!,
              );
            },
          ),
        );
        break;
      case "IMAGE":
        // Note: Images are precached via StoryMediaPreloader.preloadImage()
        // which uses CachedNetworkImageProvider. FlutterStoryPresenter's
        // StoryItem.image type respects Flutter's image cache, so precached
        // images will load instantly.
        storyItems.add(
          StoryItem(
            url: subtask.content,
            storyItemType: StoryItemType.image,
            duration: durationForImage,
            storyItemSource: StoryItemSource.network,
            imageConfig: StoryViewImageConfig(
              fit: BoxFit.fitWidth,
              progressIndicatorBuilder:
                  (context, url, progress) => Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
            ),
          ),
        );
        break;
      case "AUDIO":
        // For audio-only content, use custom widget with audioConfig
        storyItems.add(
          StoryItem(
            storyItemType: StoryItemType.custom,
            duration: durationForAudio,
            audioConfig: StoryViewAudioConfig(
              audioPath: subtask.content,
              source: StoryItemSource.network,
              onAudioStart: (audioPlayer) {
                // Audio playback is handled by the package
              },
            ),
            customWidget: (controller, audioPlayer) {
              return CustomAudioStory(
                audioPlayer: audioPlayer ?? AudioPlayer(),
              );
            },
          ),
        );
        break;
    }
  }
  // Append next card as a story if provided
  if (nextCard != null) {
    storyItems.add(
      StoryItem(
        storyItemType: StoryItemType.custom,
        duration: durationForActionCard,
        customWidget:
            (controller, audioPlayer) => CustomWidgetStory(
              heading: nextCard['heading'] as String,
              title: nextCard['title'] as String,
              subtitle: nextCard['subtitle'] as String,
              iconWidget: nextCard['iconWidget'] as Widget,
              controller: controller!,
              onTap: (context) {
                final nextSubtasks =
                    nextCard['subtasks'] as List<UserSubtasksDto>;
                final nextNextCard =
                    nextCard['nextCard'] as Map<String, dynamic>?;
                Navigator.of(context).pop();
                showStoryDialog(
                  context: context,
                  subtasks: nextSubtasks,
                  nextCard: nextNextCard,
                );
              },
            ),
      ),
    );
  }
  return storyItems;
}
