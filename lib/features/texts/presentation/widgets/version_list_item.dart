import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// List item widget for displaying text versions
class VersionListItem extends StatelessWidget {
  final Version version;
  final String languageLabel;
  final VoidCallback onTap;

  const VersionListItem({
    super.key,
    required this.version,
    required this.languageLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  version.title,
                  style: TextStyle(
                    fontSize: TextScreenConstants.largeTitleFontSize,
                    fontWeight: FontWeight.w500,
                    fontFamily: getFontFamily(version.language),
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
            "License: ${version.license}",
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
