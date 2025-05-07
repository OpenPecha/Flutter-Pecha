import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrayerOfTheDayScreen extends StatelessWidget {
  const PrayerOfTheDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('Prayer of the Day'),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const Divider(thickness: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Text(
                '''སྐྱབས་སུ་མཆིའི་སྨོན་ལམ་དང་བཅས་པའི་སྨོན་ལམ།\nབདེ་སྐྱིད་དང་སྡུག་བསྔལ་སོགས་ཀྱི་སྐོར་ལ་བསམ་པ་དག་པའི་སྨོན་ལམ་ཞིག་བསྐུལ་བ་ཡིན།\n... (add full prayer text here)''',
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.5,
                  fontFamily: 'Jomolhari', // Use your Tibetan font here
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 28),
            child: Column(
              children: [
                Column(
                  children: [
                    Slider(
                      value: 0.11,
                      onChanged: null,
                      min: 0,
                      max: 1,
                      padding: EdgeInsets.zero,
                    ),
                    Row(children: const [Text('0:47'), Spacer(), Text('7:03')]),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 28),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
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
                    IconButton(
                      icon: const Text('x1', style: TextStyle(fontSize: 20)),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
