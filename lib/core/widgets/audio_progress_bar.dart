// audio progress bar widget
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class AudioProgressBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeModeProvider);
    return Column(
      children: [
        Slider(
          value: position.inSeconds.toDouble().clamp(
            0,
            duration.inSeconds.toDouble(),
          ),
          onChangeStart: (value) {
            audioPlayer.pause();
          },
          onChanged: (value) {
            audioPlayer.seek(Duration(seconds: value.toInt()));
          },
          onChangeEnd: (value) {
            audioPlayer.play();
          },
          min: 0,
          max:
              duration.inSeconds.toDouble() > 0
                  ? duration.inSeconds.toDouble()
                  : 1,
          padding: EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0),
          activeColor:
              themeProvider == ThemeMode.dark ? Colors.white : Colors.black,
          inactiveColor:
              themeProvider == ThemeMode.dark ? Colors.grey : Colors.grey,
          thumbColor:
              themeProvider == ThemeMode.dark ? Colors.white : Colors.black,
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
