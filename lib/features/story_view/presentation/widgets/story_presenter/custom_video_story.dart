import 'package:flutter/material.dart';
import 'package:flutter_pecha/shared/widgets/reusable_youtube_player.dart';
import 'package:flutter_story_presenter/flutter_story_presenter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as yt;

class CustomVideoStory extends StatefulWidget {
  final String videoUrl;
  final FlutterStoryController controller;

  const CustomVideoStory({
    super.key,
    required this.videoUrl,
    required this.controller,
  });

  @override
  State<CustomVideoStory> createState() => _CustomVideoStoryState();
}

class _CustomVideoStoryState extends State<CustomVideoStory> {
  bool _isVideoReady = false;
  bool _isVideoPlaying = false;
  yt.YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    // Pause story progress initially while video loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.pause();
    });
    //Listen to story controller changes to sync video
    widget.controller.addListener(_onStoryControllerChanged);
  }

  void _onStoryControllerChanged() {
    if (_youtubeController != null && _isVideoReady) {
      switch (widget.controller.storyStatus) {
        case StoryAction.play:
        case StoryAction.playCustomWidget:
          if (!_isVideoPlaying) {
            _youtubeController!.play();
          }
          break;
        case StoryAction.pause:
          if (_isVideoPlaying) {
            _youtubeController!.pause();
          }
          break;
        default:
          break;
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStoryControllerChanged);
    super.dispose();
  }

  void _onVideoReady() {
    if (mounted) {
      setState(() {
        _isVideoReady = true;
      });
      // Resume story progress when video is ready and auto-play
      if (mounted) {
        widget.controller.play();
      }
    }
  }

  void _onVideoStateChanged(bool isPlaying) {
    if (mounted) {
      setState(() {
        _isVideoPlaying = isPlaying;
      });

      // Sync story progress with video state
      if (mounted) {
        if (isPlaying) {
          widget.controller.play();
        } else {
          widget.controller.pause();
        }
      }
    }
  }

  void _setYoutubeController(yt.YoutubePlayerController controller) {
    _youtubeController = controller;
  }

  void _handleLongPress() {
    if (_youtubeController != null && _isVideoReady && mounted) {
      _youtubeController!.pause();
      widget.controller.pause();
    }
  }

  void _handleLongPressUp() {
    if (_youtubeController != null && _isVideoReady && mounted) {
      _youtubeController!.play();
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

          // Long press zone for pause/play control
          GestureDetector(
            onLongPress: _handleLongPress,
            onLongPressUp: _handleLongPressUp,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Loading indicator
          if (!_isVideoReady)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Play/Pause indicator
          if (_isVideoReady && !_isVideoPlaying)
            const Center(
              child: Icon(Icons.play_arrow, color: Colors.white70, size: 64),
            ),
        ],
      ),
    );
  }
}
