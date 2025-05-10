// audio progress bar widget
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioProgressBar extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final Duration duration;
  final Duration position;
  const AudioProgressBar({
    super.key,
    required this.audioPlayer,
    required this.duration,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: position.inSeconds.toDouble().clamp(
            0,
            duration.inSeconds.toDouble(),
          ),
          onChanged: (value) {
            // TODO: Implement slider value change
          },
          min: 0,
          max:
              duration.inSeconds.toDouble() > 0
                  ? duration.inSeconds.toDouble()
                  : 1,
          padding: EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0),
          activeColor: Colors.black,
          inactiveColor: Colors.grey,
          thumbColor: Colors.black,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(_formatDuration(position)),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(_formatDuration(duration)),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
