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

  void _handleCenterTap() {
    if (widget.controller.playbackNotifier.value == PlaybackState.play) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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

          // Center tap zone for play/pause only
          // Let story_view package handle left/right navigation
          Positioned(
            left: 70, // Start after the left gesture zone (70px)
            right: 70, // End before the right gesture zone (70px)
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _handleCenterTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // Loading indicator
          if (!_isVideoReady)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Play/Pause indicator (shows when story is paused)
          StreamBuilder<PlaybackState>(
            stream: widget.controller.playbackNotifier.stream,
            builder: (context, snapshot) {
              if (snapshot.data == PlaybackState.pause) {
                return const Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white70,
                    size: 64,
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
