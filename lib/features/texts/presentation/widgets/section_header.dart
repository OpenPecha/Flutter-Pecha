import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';

/// Consistent section header widget for text screens
/// Used for section titles like "Root Text", "Commentary", etc.
class SectionHeader extends StatelessWidget {
  final String title;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const SectionHeader({
    super.key,
    required this.title,
    this.fontSize,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: fontSize ?? TextScreenConstants.largeTitleFontSize,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? Colors.grey[TextScreenConstants.greyShade700],
      ),
    );
  }
}
