import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/models/user/user_tasks_dto.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'widgets/plan_cover_image.dart';
import 'widgets/day_carousel.dart';
import 'widgets/activity_list.dart';

class PlanDetails extends ConsumerStatefulWidget {
  const PlanDetails({
    super.key,
    required this.plan,
    required this.selectedDay,
    required this.startDate,
  });
  final UserPlansModel plan;
  final int selectedDay;
  final DateTime startDate;

  @override
  ConsumerState<PlanDetails> createState() => _PlanDetailsState();
}

class _PlanDetailsState extends ConsumerState<PlanDetails> {
  late int selectedDay; // Day 1 is selected by default

  @override
  void initState() {
    super.initState();
    selectedDay = widget.selectedDay;
  }

  @override
  Widget build(BuildContext context) {
    final planDays = ref.watch(planDaysByPlanIdFutureProvider(widget.plan.id));
    final dayCompletionStatus = ref.watch(
      userPlanDaysCompletionStatusProvider(widget.plan.id),
    );

    final userPlanDayContent = ref.watch(
      userPlanDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plan.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PlanCoverImage(
              imageUrl: widget.plan.imageUrl ?? '',
              heroTag: widget.plan.title,
            ),
            planDays.when(
              data: (days) {
                if (days.isEmpty) {
                  return _buildEmptyDayCarouselState(context);
                }
                return dayCompletionStatus.when(
                  data:
                      (completionStatus) => DayCarousel(
                        days: days,
                        selectedDay: selectedDay,
                        startDate: widget.startDate,
                        dayCompletionStatus: completionStatus,
                        onDaySelected: (day) {
                          setState(() {
                            selectedDay = day;
                          });
                        },
                      ),
                  loading:
                      () => DayCarousel(
                        days: days,
                        selectedDay: selectedDay,
                        startDate: widget.startDate,
                        onDaySelected: (day) {
                          setState(() {
                            selectedDay = day;
                          });
                        },
                      ),
                  error:
                      (error, stackTrace) => DayCarousel(
                        days: days,
                        selectedDay: selectedDay,
                        startDate: widget.startDate,
                        onDaySelected: (day) {
                          setState(() {
                            selectedDay = day;
                          });
                        },
                      ),
                );
              },
              loading: () => _buildDayCarouselLoadingPlaceholder(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDayTitle(selectedDay),
                  const SizedBox(height: 8),
                  userPlanDayContent.when(
                    data:
                        (dayContent) => ActivityList(
                          tasks: dayContent.tasks,
                          today: selectedDay,
                          totalDays: dayContent.tasks.length,
                          planId: widget.plan.id,
                          dayNumber: selectedDay,
                          onActivityToggled:
                              (taskId) =>
                                  _handleTaskToggle(taskId, dayContent.tasks),
                        ),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, stackTrace) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unable to load the tasks for the day',
                              style: TextStyle(color: Colors.red[600]),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                ref.invalidate(
                                  userPlanDayContentFutureProvider,
                                );
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDayCarouselState(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(child: Text('No days available')),
    );
  }

  Widget _buildDayTitle(int day) {
    return Text(
      "Day $day of ${widget.plan.totalDays}",
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDayCarouselLoadingPlaceholder() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 70,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleTaskToggle(
    String taskId,
    List<UserTasksDto> tasks,
  ) async {
    final task = tasks.firstWhere((t) => t.id == taskId);
    final repository = ref.read(userPlansRepositoryProvider);

    try {
      bool success;
      if (task.isCompleted) {
        success = await repository.deleteTask(taskId);
      } else {
        success = await repository.completeTask(taskId);
      }

      if (success && mounted) {
        ref.invalidate(
          userPlanDayContentFutureProvider(
            PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
          ),
        );
        // Also invalidate completion status to refresh checkmarks
        ref.invalidate(userPlanDaysCompletionStatusProvider(widget.plan.id));
      } else if (!success && mounted) {
        _showErrorSnackbar('Unable to update task status');
      }
    } catch (e) {
      debugPrint('Error toggling task: $e');
      if (mounted) {
        _showErrorSnackbar('Error: $e');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
