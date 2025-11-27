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
  bool _hasVideoEnded = false;
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

    // Note: Video metadata is preloaded via StoryMediaPreloader.prepareVideoMetadata()
    // YouTube player initialization still requires time, but metadata preparation
    // helps reduce overall loading time. The loading overlay in PlanStoryPresenter
    // handles the initial delay gracefully.
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
    _youtubeController?.removeListener(_onYoutubePlayerStateChange);
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
    // Listen for video end state
    _youtubeController!.addListener(_onYoutubePlayerStateChange);
  }

  void _onYoutubePlayerStateChange() {
    if (_youtubeController == null || !mounted) return;

    final playerState = _youtubeController!.value.playerState;
    if (playerState == yt.PlayerState.ended && !_hasVideoEnded) {
      _hasVideoEnded = true;
      // Video ended - move to next story or complete
      widget.controller.next();
    }
  }

  void handleTap() {
    if (_youtubeController == null || !_isVideoReady || !mounted) return;

    if (_isVideoPlaying) {
      _youtubeController!.pause();
      widget.controller.pause();
    } else {
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

          // onTap for pause/play control
          GestureDetector(
            onTap: handleTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Loading indicator - shown while YouTube player initializes
          // Note: Even with preloading, YouTube player initialization takes time
          // The loading overlay in PlanStoryPresenter handles initial delay
          if (!_isVideoReady)
            Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

          // Play/Pause indicator
        ],
      ),
    );
  }
}
