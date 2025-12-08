import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/services/background_image/background_image_service.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_card_constants.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/story_view/utils/story_dialog_helper.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerseCard extends ConsumerWidget {
  final String verseText;
  final String title;
  final List<UserSubtasksDto> subtasks;
  final Map<String, dynamic>? nextCard;

  const VerseCard({
    super.key,
    required this.verseText,
    required this.title,
    required this.subtasks,
    this.nextCard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;
    final fontFamily = getFontFamily(languageCode);
    final lineHeight = getLineHeight(languageCode);

    final backgroundImagePath = BackgroundImageService().getImageForContent(
      verseText,
    );

    return GestureDetector(
      onTap: () {
        showStoryDialog(
          context: context,
          subtasks: subtasks,
          nextCard: nextCard,
        );
      },
      child: Stack(
        children: [
          Hero(
            tag: 'verse-image-$backgroundImagePath',
            child: Container(
              width: double.infinity,
              height: VerseCardConstants.cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  VerseCardConstants.cardBorderRadius,
                ),
                image:
                    backgroundImagePath.isNotEmpty
                        ? DecorationImage(
                          image: AssetImage(backgroundImagePath),
                          fit: BoxFit.cover,
                        )
                        : null,
                color: backgroundImagePath.isEmpty ? Colors.brown[700] : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(VerseCardConstants.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: VerseCardConstants.titleFontSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                        fontFamily: fontFamily,
                        height: lineHeight,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height:
                          VerseCardConstants.cardHeight *
                          VerseCardConstants.verseContentHeightRatio,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            verseText,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: VerseCardConstants.verseFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: fontFamily,
                              height: lineHeight,
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
