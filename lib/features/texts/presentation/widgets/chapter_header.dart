import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Header widget for chapter screens
/// Displays the text title with appropriate font based on language
class ChapterHeader extends StatelessWidget {
  final TextDetail textDetail;

  const ChapterHeader({super.key, required this.textDetail});

  @override
  Widget build(BuildContext context) {
    final fontSize = 22.0;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: TextScreenConstants.screenHorizontalPadding + 4,
        vertical: 8,
      ),
      child: Text(
        textDetail.title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: fontSize,
          fontFamily: getFontFamily(textDetail.language),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
