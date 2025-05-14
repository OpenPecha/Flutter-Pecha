// audio controls widget
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioControls extends StatelessWidget {
  const AudioControls({
    super.key,
    required this.audioPlayer,
    required this.duration,
    required this.position,
  });

  final AudioPlayer audioPlayer;
  final Duration duration;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          color: Theme.of(context).appBarTheme.foregroundColor,
          icon: const Icon(Icons.replay_10, size: 32),
          onPressed: () async {
            final newPosition = position - const Duration(seconds: 10);
            await audioPlayer.seek(
              newPosition > Duration.zero ? newPosition : Duration.zero,
            );
          },
          padding: EdgeInsets.zero,
        ),
        IconButton(
          color: Theme.of(context).appBarTheme.foregroundColor,
          icon: Icon(
            audioPlayer.playing
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            size: 44,
          ),
          onPressed: () async {
            if (audioPlayer.playing) {
              await audioPlayer.pause();
            } else {
              await audioPlayer.play();
            }
          },
          padding: EdgeInsets.zero,
        ),
        IconButton(
          color: Theme.of(context).appBarTheme.foregroundColor,
          icon: const Icon(Icons.forward_10, size: 32),
          onPressed: () async {
            final newPosition = position + const Duration(seconds: 10);
            await audioPlayer.seek(
              newPosition < duration ? newPosition : duration,
            );
          },
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
