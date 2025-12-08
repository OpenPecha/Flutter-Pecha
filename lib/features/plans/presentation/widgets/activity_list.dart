import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/author/author_dto_model.dart';
import 'package:flutter_pecha/features/plans/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/story_view/services/story_media_preloader.dart';
import 'package:flutter_pecha/shared/extensions/typography_extensions.dart';
import 'package:go_router/go_router.dart';

class ActivityList extends StatelessWidget {
  final String language;
  final List<UserTasksDto> tasks;
  final int today;
  final int totalDays;
  final Function(String taskId) onActivityToggled;
  final AuthorDtoModel? author;
  final String? planId;
  final int? dayNumber;

  const ActivityList({
    super.key,
    required this.language,
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
    final sortedTasks = List<UserTasksDto>.from(tasks)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        final isCompleted = task.isCompleted;
        final taskId = task.id;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _TaskCheckbox(
                isCompleted: isCompleted,
                onTap: () => onActivityToggled(taskId),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TaskTitleButton(
                  language: language,
                  title: task.title,
                  onTap: () => handleActivityTap(context, task, language),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void handleActivityTap(
    BuildContext context,
    UserTasksDto task,
    String language,
  ) {
    if (task.subTasks.isNotEmpty) {
      context.push(
        '/home/plan-stories-presenter',
        extra: {
          'subtasks': task.subTasks,
          if (planId != null) 'planId': planId,
          if (dayNumber != null) 'dayNumber': dayNumber,
          'language': language,
        },
      );

      // Start preloading in parallel (fire-and-forget background task)
      // This doesn't block navigation and improves UX
      final preloader = StoryMediaPreloader();
      unawaited(preloader.preloadStoryItems(task.subTasks, context));
    }
  }
}

/// Checkbox widget for task completion with ripple effect
class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({required this.isCompleted, required this.onTap});

  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
            color: isCompleted ? const Color(0xFF1E3A8A) : Colors.transparent,
          ),
          child:
              isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
        ),
      ),
    );
  }
}

/// Task title button with ripple effect
class _TaskTitleButton extends StatelessWidget {
  const _TaskTitleButton({
    required this.title,
    required this.onTap,
    required this.language,
  });

  final String title;
  final VoidCallback onTap;
  final String language;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.languageTextStyle(
                    language,
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
    );
  }
}
