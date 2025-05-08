// audio progress bar widget
import 'package:flutter/material.dart';

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: 0.11,
          onChanged: (value) {
            // TODO: Implement slider value change
          },
          min: 0,
          max: 1,
          padding: EdgeInsets.only(top: 16.0),
          activeColor: Colors.black,
          inactiveColor: Colors.grey,
          thumbColor: Colors.black,
        ),
        Row(children: [Text('0:47'), Spacer(), Text('7:03')]),
      ],
    );
  }
}
