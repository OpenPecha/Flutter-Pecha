import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/author/author_dto_model.dart';
import 'package:flutter_pecha/features/plans/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/story_view/services/story_media_preloader.dart';
import 'package:go_router/go_router.dart';

class ActivityList extends StatelessWidget {
  final List<UserTasksDto> tasks;
  final int today;
  final int totalDays;
  final Function(String taskId) onActivityToggled;
  final AuthorDtoModel? author;
  final String? planId;
  final int? dayNumber;

  const ActivityList({
    super.key,
    required this.tasks,
    required this.today,
    required this.totalDays,
    required this.onActivityToggled,
    this.author,
    this.planId,
    this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isCompleted = task.isCompleted;
        final taskId = task.id;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onActivityToggled(taskId),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isCompleted
                              ? const Color(0xFF1E3A8A)
                              : Theme.of(context).iconTheme.color!,
                      width: 1,
                    ),
                    color:
                        isCompleted
                            ? const Color(0xFF1E3A8A)
                            : Colors.transparent,
                  ),
                  child:
                      isCompleted
                          ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                          : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => handleActivityTap(context, task),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                        color: Theme.of(context).iconTheme.color!,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void handleActivityTap(BuildContext context, UserTasksDto task) {
    if (task.subTasks.isNotEmpty) {
      // Navigate immediately for best perceived performance
      context.push(
        '/home/plan-stories-presenter',
        extra: {
          'subtasks': task.subTasks,
          if (planId != null) 'planId': planId,
          if (dayNumber != null) 'dayNumber': dayNumber,
        },
      );

      // Start preloading in parallel (fire-and-forget background task)
      // This doesn't block navigation and improves UX
      final preloader = StoryMediaPreloader();
      unawaited(preloader.preloadStoryItems(task.subTasks, context));
    }
  }
}
