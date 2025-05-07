import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MeditationOfTheDayScreen extends StatelessWidget {
  const MeditationOfTheDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('Meditation of the Day'),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const Divider(thickness: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/meditation.png',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          // Audio player controls
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 0.0,
              bottom: 16.0,
            ),
            child: Column(
              children: [
                const Column(
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
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, size: 32),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.pause_circle_filled, size: 44),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, size: 32),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 28),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.music_note, size: 28),
                      onPressed: () {},
                    ),
                    const Text('x1', style: TextStyle(fontSize: 20)),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, size: 32),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
