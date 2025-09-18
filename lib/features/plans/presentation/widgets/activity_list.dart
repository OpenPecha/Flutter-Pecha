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
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Day $today of $totalDays",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final isSelected = selectedActivities.contains(index);
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
                                isSelected
                                    ? const Color(0xFF1E3A8A)
                                    : Colors.black,
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
                      child: Text(
                        tasks[index].title,
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
              );
            },
          ),
        ],
      ),
    );
  }
}
