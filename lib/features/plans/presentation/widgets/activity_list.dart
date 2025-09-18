import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/plan_tasks_model.dart';

class ActivityList extends StatelessWidget {
  final List<PlanTasksModel> tasks;
  final int today;
  final int totalDays;
  final Set<int> selectedActivities; // Changed from single int to Set<int>
  final Function(int) onActivityToggled; // Changed from onActivitySelected

  const ActivityList({
    super.key,
    required this.tasks,
    required this.today,
    required this.totalDays,
    required this.selectedActivities,
    required this.onActivityToggled,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isNotEmpty && tasks[0].subtasks.isNotEmpty) {
      debugPrint('todays verse of the day: ${tasks[0].subtasks[0].content}');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final isSelected = selectedActivities.contains(index);
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onActivityToggled(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFF1E3A8A) : Colors.black,
                      width: 1,
                    ),
                    color:
                        isSelected
                            ? const Color(0xFF1E3A8A)
                            : Colors.transparent,
                  ),
                  child:
                      isSelected
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
                  onTap: () => handleActivityTap(task),
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
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                        color: Colors.black,
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

  void handleActivityTap(PlanTasksModel task) {
    // Navigate to activity details or perform action
    debugPrint('Activity tapped: ${task.title}');
    // TODO: Add navigation to activity details page when implemented
    if (task.subtasks.isNotEmpty) {}
  }
}
