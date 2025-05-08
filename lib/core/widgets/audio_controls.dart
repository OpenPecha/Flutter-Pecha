// audio controls widget
import 'package:flutter/material.dart';

class AudioControls extends StatelessWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, size: 32),
          onPressed: () {},
          padding: EdgeInsets.zero,
        ),
        IconButton(
          icon: const Icon(Icons.pause_circle_outline, size: 44),
          onPressed: () {},
          padding: EdgeInsets.zero,
        ),
        IconButton(
          icon: const Icon(Icons.forward_10, size: 32),
          onPressed: () {},
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
