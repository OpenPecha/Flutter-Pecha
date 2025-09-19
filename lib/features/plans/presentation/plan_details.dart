import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'widgets/plan_cover_image.dart';
import 'widgets/day_carousel.dart';
import 'widgets/activity_list.dart';

class PlanDetails extends ConsumerStatefulWidget {
  const PlanDetails({super.key, required this.plan});
  final PlansModel plan;

  @override
  ConsumerState<PlanDetails> createState() => _PlanDetailsState();
}

class _PlanDetailsState extends ConsumerState<PlanDetails> {
  int selectedDay = 1; // Day 1 is selected by default
  Set<int> selectedActivities = {}; // No activities selected initially
  int? previousSelectedDay; // Track previous day to reset activities

  @override
  Widget build(BuildContext context) {
    final DateTime startDate = DateTime.now();
    final planDays = ref.watch(planDaysByPlanIdFutureProvider(widget.plan.id));
    final planDayContent = ref.watch(
      planDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
    );

    // Reset selected activities when day changes
    if (previousSelectedDay != null && previousSelectedDay != selectedDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedActivities.clear();
          });
        }
      });
    }
    previousSelectedDay = selectedDay;

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
            DayCarousel(
              days: planDays.value ?? [],
              selectedDay: selectedDay,
              startDate: startDate,
              onDaySelected: (day) {
                setState(() {
                  selectedDay = day;
                });
              },
            ),
            Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDayTitle(selectedDay),
                  const SizedBox(height: 16),
                  planDayContent.when(
                    data:
                        (dayContent) => ActivityList(
                          tasks: dayContent.tasks ?? [],
                          today: selectedDay,
                          totalDays: widget.plan.totalDays,
                          selectedActivities: selectedActivities,
                          onActivityToggled: (activity) {
                            setState(() {
                              if (selectedActivities.contains(activity)) {
                                selectedActivities.remove(activity);
                              } else {
                                selectedActivities.add(activity);
                              }
                            });
                          },
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
                                ref.invalidate(planDayContentFutureProvider);
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

  Widget _buildDayTitle(int day) {
    return Text(
      "Day $day of ${widget.plan.totalDays}",
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
