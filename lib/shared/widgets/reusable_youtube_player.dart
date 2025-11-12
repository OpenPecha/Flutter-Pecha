import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ReusableYoutubePlayer extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;
  final bool autoPlay;
  final bool mute;
  final VoidCallback? onReady;
  final ValueChanged<bool>? onStateChanged;
  final ValueChanged<YoutubePlayerController>? onControllerCreated;

  const ReusableYoutubePlayer({
    super.key,
    required this.videoUrl,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
    this.mute = false,
    this.onReady,
    this.onStateChanged,
    this.onControllerCreated,
  });

  @override
  State<ReusableYoutubePlayer> createState() => _ReusableYoutubePlayerState();
}

class _ReusableYoutubePlayerState extends State<ReusableYoutubePlayer> {
  late YoutubePlayerController _controller;
  bool _hasCalledOnReady = false;
  bool? _previousIsPlaying;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: widget.mute,
        hideControls: true, // Hide controls to reduce context menu triggers
        controlsVisibleAtStart: false,
        useHybridComposition: true, // Better performance
        enableCaption: false,
      ),
    );

    // Notify parent widget about controller creation
    if (widget.onControllerCreated != null) {
      widget.onControllerCreated!(_controller);
    }

    // Listen to player state changes
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    // Handle onReady callback
    if (_controller.value.isReady &&
        !_hasCalledOnReady &&
        widget.onReady != null) {
      _hasCalledOnReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onReady!();
        }
      });
    }

    // Handle state change callback
    if (widget.onStateChanged != null && _controller.value.isReady) {
      final currentState = _controller.value.playerState;
      final isPlaying = currentState == PlayerState.playing;
      if (isPlaying != _previousIsPlaying) {
        _previousIsPlaying = isPlaying;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onStateChanged!(isPlaying);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: widget.aspectRatio,
        showVideoProgressIndicator: false, // Hide progress indicator
        onReady: widget.onReady,
      ),
    );
  }
}
