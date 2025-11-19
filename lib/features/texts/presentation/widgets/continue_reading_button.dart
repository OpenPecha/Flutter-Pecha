import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';

/// Continue reading button widget
/// Standard button for starting/continuing text reading
class ContinueReadingButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ContinueReadingButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: TextScreenConstants.continueReadingButtonWidth,
      height: TextScreenConstants.continueReadingButtonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: TextScreenConstants.subtitleFontSize,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
