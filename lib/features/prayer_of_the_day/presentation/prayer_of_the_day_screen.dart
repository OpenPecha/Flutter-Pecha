import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/audio_progress_bar.dart';
import 'package:go_router/go_router.dart';

const prayerText = """
སྟོན་པ་བཅོམ་ལྡན་འདས་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་
ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་རིག་པ་དང་ཞབས་སུ་ལྡན་པ། བདེ་བར་གཤེགས་པ། 
འཇིག་རྟེན་མཁྱེན་པ། སྐྱེས་བུ་འདུལ་བའི་ཁ་ལོ་བསྒྱུར་བ། བླ་
ན་མེད་པ་ལྷ་དང་མི་རྣམས་ཀྱི་སྟོན་པ། སངས་རྒྱས་བཅོམ་ལྡན་འདས་དཔལ་རྒྱལ་བ་ཤཱཀྱ་
ཐུབ་པ་ལ་ཕྱག་འཚལ་ལོ། །མཆོད་དོ་སྐྱབས་སུ་མཆིའོ། །གང་ཚེ་རྐང་གཉིས་གཙོ་བོ་
ཁྱོད་བལྟམས་ཚེ། །ས་ཆེན་འདི་ལ་གོམ་པ་བདུན་བོར་ནས། །ང་ནི་འཇིག་
རྟེན་འདི་ན་མཆོག་ཅེས་གསུངས། །དེ་ཚེ་མཁས་པ་ཁྱོད་ལ་ཕྱག་འཚལ་ལོ། །རྣམ་
དག་སྐུ་མངའ་མཆོག་ཏུ་གཟུགས་བཟང་བ། །ཡེ་ཤེས་རྒྱ་མཚོ་གསེར་གྱི་ལྷུན་པོ་
འདྲ། །གྲགས་པ་འཇིག་རྟེན་གསུམ་ན་ལྷམ་མེ་བ། །མགོན་པོ་མཆོག་བརྙེས་ཁྱོད་ལ་ཕྱག་
འཚལ་ལོ། །མཚན་མཆོག་ལྡན་པ་དྲི་མེད་ཟླ་བའི་ཞལ། །གསེར་མདོག་འདྲ་
བ་ཁྱོད་ལ་ཕྱག་འཚལ་ལོ། །
""";

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
                prayerText,
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
                const AudioProgressBar(),
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
                      padding: EdgeInsets.zero,
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
