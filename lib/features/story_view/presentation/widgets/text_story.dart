import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/services/background_image/background_image_service.dart';

class TextStory extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final bool roundedTop;
  final bool roundedBottom;
  final String? backgroundImagePath;

  const TextStory({
    super.key,
    required this.text,
    this.textStyle,
    this.padding,
    this.roundedTop = false,
    this.roundedBottom = false,
    this.backgroundImagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Get background image - use provided path or generate from text content
    final imagePath =
        backgroundImagePath ??
        BackgroundImageService().getImageForContent(text);

    // Get screen height to calculate 80% constraint
    final screenHeight = MediaQuery.of(context).size.height;
    final maxTextHeight = screenHeight * 0.8;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image:
            imagePath.isNotEmpty
                ? DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                )
                : null,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(roundedTop ? 8 : 0),
          bottom: Radius.circular(roundedBottom ? 8 : 0),
        ),
      ),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Main text content
          SizedBox(
            height: maxTextHeight,
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
