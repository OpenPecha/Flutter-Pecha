import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

class VersionListItem extends StatelessWidget {
  final String title;
  final String sourceLink;
  final String license;
  final String language;
  final String languageLabel;
  final VoidCallback onTap;

  const VersionListItem({
    super.key,
    required this.title,
    required this.sourceLink,
    required this.license,
    required this.language,
    required this.languageLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final fontSize = language == 'bo' ? 20.0 : 18.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: fontFamily,
                    height: lineHeight,
                    fontSize: fontSize,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8, top: 2),
                padding: TextScreenConstants.languageBadgePadding,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(
                    TextScreenConstants.languageBadgeBorderRadius,
                  ),
                ),
                child: Text(
                  languageLabel,
                  style: const TextStyle(
                    fontSize: TextScreenConstants.subtitleFontSize,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Source: $sourceLink",
            style: TextStyle(
              fontSize: TextScreenConstants.subtitleFontSize,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            "License: $license",
            style: TextStyle(
              fontSize: TextScreenConstants.subtitleFontSize,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
