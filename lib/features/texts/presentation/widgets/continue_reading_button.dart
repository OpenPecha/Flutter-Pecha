import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Continue reading button widget
/// Standard button for starting/continuing text reading
class ContinueReadingButton extends StatelessWidget {
  final String label;
  final String language;
  final VoidCallback onPressed;

  const ContinueReadingButton({
    super.key,
    required this.label,
    required this.language,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = Color(0xFF18345d);
    return SizedBox(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              TextScreenConstants.buttonBorderRadius,
            ),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontFamily: getFontFamily(language),
            fontWeight: FontWeight.w500,
            fontSize: TextScreenConstants.bodyFontSize,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
