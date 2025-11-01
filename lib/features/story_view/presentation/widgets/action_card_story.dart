import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';

class ActionCardStory extends StatefulWidget {
  const ActionCardStory({
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
  final StoryController controller;
  final void Function(BuildContext) onTap;

  @override
  State<ActionCardStory> createState() => _ActionCardStoryState();
}

class _ActionCardStoryState extends State<ActionCardStory> {
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
              constraints: const BoxConstraints(minHeight: 150),
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.heading,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Instrument Serif',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
                      height: 122,
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
