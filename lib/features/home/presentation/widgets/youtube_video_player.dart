import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/reusable_youtube_player.dart';

class YoutubeVideoPlayer extends StatelessWidget {
  final String videoUrl;
  final String title;
  const YoutubeVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(title),
      ),
      body: ReusableYoutubePlayer(
        videoUrl: videoUrl,
        aspectRatio: 9 / 16,
        autoPlay: true,
        mute: false,
      ),
    );
  }
}
