import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerseCard extends ConsumerWidget {
  final String verse;

  const VerseCard({super.key, required this.verse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return
    // GestureDetector(
    //   onTap: () {
    //     // ref
    //     //     .read(textReadingParamsProvider.notifier)
    //     //     .setParams(
    //     //       textId: '59769286-2787-4181-953d-9149cdeef959',
    //     //       contentId: '29c9e4dd-90b1-4fac-a833-2673f80f65d6',
    //     //       skip: '0',
    //     //     );
    //     // context.push('/texts/reader');
    //     showGeneralDialog(
    //       context: context,
    //       barrierDismissible: true,
    //       barrierLabel: "Close",
    //       transitionDuration: const Duration(milliseconds: 200),
    //       pageBuilder: (context, animation, secondaryAnimation) {
    //         return ViewIllustration(imageUrl: imageUrl);
    //       },
    //     );
    //   },
    //   child:
    Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.brown[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              verse,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
