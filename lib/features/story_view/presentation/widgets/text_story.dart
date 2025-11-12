import 'package:flutter/material.dart';

class TextStory extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final bool roundedTop;
  final bool roundedBottom;

  const TextStory({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textStyle,
    this.padding,
    this.roundedTop = false,
    this.roundedBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = backgroundColor ?? theme.primaryColor;

    // Calculate contrast for text color
    final brightness = ThemeData.estimateBrightnessForColor(
      defaultBackgroundColor,
    );
    final textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;

    final imageUrl =
        "https://images.unsplash.com/photo-1685495856559-5d96a0e51acb?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=2624";

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Image.network(imageUrl).image,
          fit: BoxFit.cover,
        ),
        color: defaultBackgroundColor,
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
          // Decorative element
          Container(
            width: 60,
            height: 4,
            margin: const EdgeInsets.only(bottom: 32),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Main text content
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                text,
                style:
                    textStyle?.copyWith(color: textColor) ??
                    TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.left,
              ),
            ),
          ),

          // Bottom decorative element
          Container(
            width: 60,
            height: 4,
            margin: const EdgeInsets.only(top: 32),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
