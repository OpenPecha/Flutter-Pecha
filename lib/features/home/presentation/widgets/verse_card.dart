import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_card_constants.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/story_view/utils/story_dialog_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerseCard extends ConsumerWidget {
  final String verseText;
  final String title;
  final UserSubtasksDto subtask;
  final Map<String, dynamic>? nextCard;

  const VerseCard({
    super.key,
    required this.verseText,
    required this.title,
    required this.subtask,
    this.nextCard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const imageUrl = VerseCardConstants.defaultImageUrl;
    return GestureDetector(
      onTap: () {
        showStoryDialog(
          context: context,
          subtasks: [subtask],
          nextCard: nextCard,
        );
      },
      child: Stack(
        children: [
          Hero(
            tag: 'verse-image-$imageUrl',
            child: Container(
              width: double.infinity,
              height: VerseCardConstants.cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  VerseCardConstants.cardBorderRadius,
                ),
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: imageUrl.cachedNetworkImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
                color: imageUrl.isEmpty ? Colors.brown[700] : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(VerseCardConstants.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: VerseCardConstants.titleFontSize,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: VerseCardConstants.cardHeight *
                          VerseCardConstants.verseContentHeightRatio,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            verseText,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: VerseCardConstants.verseFontSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
