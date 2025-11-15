// function to add story items to a list
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/image_story.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/text_story.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/video_story.dart';
import 'package:story_view/story_view.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

List<Widget> createWidgetList(
  List<dynamic> planItems,
  StoryController storyController,
) {
  List<Widget> widgetList = [];
  for (final planItem in planItems) {
    if (planItems.isEmpty) {
      continue;
    }
    switch (planItem.subtasks[0].contentType) {
      case "TEXT":
        widgetList.add(
          TextStory(
            text: planItem.content!,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
            roundedTop: true,
            roundedBottom: true,
          ),
        );
        break;
      case "VIDEO":
        widgetList.add(
          VideoStory(videoUrl: planItem.content!, controller: storyController),
        );
        break;
      case "IMAGE":
        widgetList.add(
          ImageStory(
            imageUrl: planItem.content!,
            controller: storyController,
            imageFit: BoxFit.contain,
            roundedTop: true,
            roundedBottom: true,
          ),
        );
        break;
    }
  }
  return widgetList;
}

Widget getVideoThumbnail(String videoUrl) {
  // Extract YouTube video ID and create thumbnail
  // final uri = Uri.parse(videoUrl);
  String? videoId;

  videoId ??= YoutubePlayer.convertUrlToId(videoUrl);

  if (videoId != null) {
    return CachedNetworkImageWidget(
      imageUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
      fit: BoxFit.cover,
      errorWidget: Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.video_library, size: 48, color: Colors.grey),
      ),
    );
  }

  return Container(
    color: Colors.grey.shade300,
    child: const Icon(Icons.video_library, size: 48, color: Colors.grey),
  );
}

// Returns a time-based greeting based on the current hour
String getTimeBasedGreeting(AppLocalizations localizations) {
  final hour = DateTime.now().hour;
  if (hour >= 1 && hour < 12) {
    return localizations.home_good_morning;
  } else if (hour >= 12 && hour < 17) {
    return localizations.home_good_afternoon;
  } else {
    return localizations.home_good_evening;
  }
}
