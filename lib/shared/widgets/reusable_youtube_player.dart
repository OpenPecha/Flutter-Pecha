import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ReusableYoutubePlayer extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;
  final bool autoPlay;
  final bool mute;
  final bool showVideoProgressIndicator;
  final Color progressIndicatorColor;
  final ProgressBarColors? progressColors;
  final VoidCallback? onReady;
  final ValueChanged<bool>? onStateChanged;
  final ValueChanged<YoutubePlayerController>? onControllerCreated;

  const ReusableYoutubePlayer({
    super.key,
    required this.videoUrl,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
    this.mute = false,
    this.showVideoProgressIndicator = true,
    this.progressIndicatorColor = Colors.red,
    this.progressColors = const ProgressBarColors(
      playedColor: Colors.red,
      handleColor: Colors.redAccent,
    ),
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
  PlayerState? _previousPlayerState;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: YoutubePlayerFlags(autoPlay: widget.autoPlay, mute: widget.mute),
    );

    // Notify parent widget about controller creation
    if (widget.onControllerCreated != null) {
      widget.onControllerCreated!(_controller);
    }

    if (widget.onReady != null || widget.onStateChanged != null) {
      _controller.addListener(_onControllerUpdate);
    }
  }

  void _onControllerUpdate() {
    // Handle onReady callback
    if (_controller.value.isReady &&
        !_hasCalledOnReady &&
        widget.onReady != null) {
      _hasCalledOnReady = true;
      widget.onReady!();
    }

    // Handle state change callback
    if (widget.onStateChanged != null && _controller.value.isReady) {
      final currentState = _controller.value.playerState;
      if (currentState != _previousPlayerState) {
        _previousPlayerState = currentState;
        final isPlaying = currentState == PlayerState.playing;
        widget.onStateChanged!(isPlaying);
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
    return AbsorbPointer(
      absorbing: true,
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          aspectRatio: widget.aspectRatio,
          controller: _controller,
          showVideoProgressIndicator: widget.showVideoProgressIndicator,
          progressIndicatorColor: widget.progressIndicatorColor,
          progressColors: widget.progressColors,
          onReady: widget.onReady,
        ),
        builder: (context, player) {
          return player;
        },
      ),
    );
  }
}
