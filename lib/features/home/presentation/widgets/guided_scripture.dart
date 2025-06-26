import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class GuidedScripture extends StatefulWidget {
  final String videoUrl;
  const GuidedScripture({super.key, required this.videoUrl});

  @override
  State<GuidedScripture> createState() => _GuidedScriptureState();
}

class _GuidedScriptureState extends State<GuidedScripture> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        title: const Text("Guided Scripture"),
      ),
      body: Center(
        child: YoutubePlayerBuilder(
          player: YoutubePlayer(
            aspectRatio: 9 / 16,
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.red,
            progressColors: const ProgressBarColors(
              playedColor: Colors.red,
              handleColor: Colors.redAccent,
            ),
            bottomActions: [
              // play/pause button
              IconButton(
                onPressed: () {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                },
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          builder: (context, player) {
            return player;
          },
        ),
      ),
    );
  }
}
