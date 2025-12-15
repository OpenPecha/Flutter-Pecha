import 'package:flutter/material.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_story_presenter/flutter_story_presenter.dart';

class CustomWidgetStory extends StatefulWidget {
  const CustomWidgetStory({
    super.key,
    required this.heading,
    required this.title,
    required this.subtitle,
    required this.iconWidget,
    required this.controller,
    required this.onTap,
  });

  final String heading;
  final String title;
  final String subtitle;
  final Widget iconWidget;
  final FlutterStoryController controller;
  final void Function(BuildContext) onTap;

  @override
  State<CustomWidgetStory> createState() => _CustomWidgetStoryState();
}

class _CustomWidgetStoryState extends State<CustomWidgetStory> {
  @override
  void initState() {
    super.initState();
    // Pause the story when action card is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.pause();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final fontFamily = getFontFamily(locale.languageCode);
    // Create the card visual
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          // Wrap in GestureDetector with explicit hit test behavior
          child: GestureDetector(
            onTap: () {
              widget.onTap(context);
            },
            // Use translucent to allow the gesture to be detected
            behavior: HitTestBehavior.translucent,
            child: Container(
              // Add explicit size constraints
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 100),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: fontFamily,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.play_arrow, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: fontFamily,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 122,
                      height: 100,
                      child: widget.iconWidget,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
