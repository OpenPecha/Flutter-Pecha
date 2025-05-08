// audio progress bar widget
import 'package:flutter/material.dart';

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Slider(
          value: 0.11,
          onChanged: null,
          min: 0,
          max: 1,
          padding: EdgeInsets.zero,
        ),
        Row(children: [Text('0:47'), Spacer(), Text('7:03')]),
      ],
    );
  }
}
