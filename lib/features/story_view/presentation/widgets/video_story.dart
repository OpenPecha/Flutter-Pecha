import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/shared/widgets/reusable_youtube_player.dart';
import 'package:story_view/story_view.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoStory extends StatefulWidget {
  final String videoUrl;
  final StoryController controller;

  const VideoStory({
    super.key,
    required this.videoUrl,
    required this.controller,
  });

  @override
  State<VideoStory> createState() => _VideoStoryState();
}

class _VideoStoryState extends State<VideoStory> {
  bool _isVideoReady = false;
  bool _isVideoPlaying = false;
  StreamSubscription<PlaybackState>? _storySubscription;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    // Pause story progress initially while video loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.pause();
    });

    // Listen to story controller changes to sync video
    _storySubscription = widget.controller.playbackNotifier.listen((
      playbackState,
    ) {
      if (_youtubeController != null && _isVideoReady) {
        switch (playbackState) {
          case PlaybackState.play:
            if (!_isVideoPlaying) {
              _youtubeController!.play();
            }
            break;
          case PlaybackState.pause:
            if (_isVideoPlaying) {
              _youtubeController!.pause();
            }
            break;
          default:
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _storySubscription?.cancel();
    super.dispose();
  }

  void _onVideoReady() {
    setState(() {
      _isVideoReady = true;
    });
    // Resume story progress when video is ready and auto-play
    widget.controller.play();
  }

  void _onVideoStateChanged(bool isPlaying) {
    setState(() {
      _isVideoPlaying = isPlaying;
    });

    // Sync story progress with video state
    if (isPlaying) {
      widget.controller.play();
    } else {
      widget.controller.pause();
    }
  }

  void _setYoutubeController(YoutubePlayerController controller) {
    _youtubeController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return
    // return GestureDetector(
    //   onLongPressUp: () {
    //     widget.controller.play();
    //   },
    //   onLongPress: () {
    //     widget.controller.pause();
    //   },
    //   onLongPressStart: (_) {
    //     // Consume the long press gesture
    //   },
    //   // onTap: () {
    //   //   // Toggle story pause/play on tap (not video controls)
    //   //   if (widget.controller.playbackNotifier.value == PlaybackState.play) {
    //   //     widget.controller.pause();
    //   //   } else {
    //   //     widget.controller.play();
    //   //   }
    //   // },
    //   child:
    Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Video Player
          Center(
            child: AspectRatio(
              aspectRatio:
                  MediaQuery.of(context).size.width /
                  MediaQuery.of(context).size.height,
              child: ReusableYoutubePlayer(
                videoUrl: widget.videoUrl,
                aspectRatio:
                    MediaQuery.of(context).size.width /
                    MediaQuery.of(context).size.height,
                autoPlay: true,
                mute: false,
                onReady: _onVideoReady,
                onStateChanged: _onVideoStateChanged,
                onControllerCreated: _setYoutubeController,
              ),
            ),
          ),

          // Gesture overlay to handle long press and prevent context menu
          Positioned.fill(
            child: GestureDetector(
              onLongPressUp: () {
                widget.controller.play();
              },
              onLongPress: () {
                widget.controller.pause();
              },
              // Prevent any other gestures from reaching the video
              onTap: () {},
              onDoubleTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Loading indicator
          if (!_isVideoReady)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Story pause indicator (only when story is paused, not video)
          StreamBuilder<PlaybackState>(
            stream: widget.controller.playbackNotifier.stream,
            builder: (context, snapshot) {
              if (snapshot.data == PlaybackState.pause && _isVideoPlaying) {
                return const Positioned(
                  top: 50,
                  right: 20,
                  child: Icon(
                    Icons.pause_circle_outline,
                    color: Colors.white70,
                    size: 32,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
