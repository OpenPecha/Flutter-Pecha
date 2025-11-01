// a widget that create a story item

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/author/author_dto_model.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/story_author_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:story_view/story_view.dart';

class Stories extends StatelessWidget {
  final List<StoryItem> storyItems;
  final StoryController controller;
  final AuthorDtoModel? author;
  const Stories({
    super.key,
    required this.storyItems,
    required this.controller,
    this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StoryView(
          storyItems: storyItems,
          controller: controller,
          onComplete: () {
            context.pop();
          },
          onVerticalSwipeComplete: (direction) {
            if (direction == Direction.down) {
              context.pop();
            }
          },
        ),
        if (author != null) StoryAuthorAvatar(author: author),
      ],
    );
  }
}
