import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Custom widget for audio-only stories
class CustomAudioStory extends StatefulWidget {
  const CustomAudioStory({super.key, required this.audioPlayer});

  final AudioPlayer audioPlayer;

  @override
  State<CustomAudioStory> createState() => _CustomAudioStoryState();
}

class _CustomAudioStoryState extends State<CustomAudioStory> {
  bool _isPlaying = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAudioListener();
  }

  void _setupAudioListener() {
    widget.audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
          _isLoading = false;
        });
      }
    });

    widget.audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isLoading =
              state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.black54],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading)
            const CircularProgressIndicator(color: Colors.white)
          else
            Icon(
              _isPlaying
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              color: Colors.white,
              size: 80,
            ),
          const SizedBox(height: 24),
          const Text(
            'Audio Story',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
