import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/story_view/presentation/screens/story_presenter.dart';
import 'package:flutter_pecha/features/story_view/utils/helper_functions.dart';

void showStoryDialog({
  required BuildContext context,
  required List<UserSubtasksDto> subtasks,
  dynamic author,
  Map<String, dynamic>? nextCard,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Story',
    barrierColor: Colors.black,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return StoryPresenter(
        author: author,
        storyItemsBuilder: (controller) {
          return createFlutterStoryItems(subtasks, controller, nextCard, null);
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
