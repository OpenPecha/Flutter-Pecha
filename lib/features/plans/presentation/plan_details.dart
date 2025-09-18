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
  int selectedDay = 1; // Day 3 is selected by default
  Set<int> selectedActivities = {}; // No activities selected initially

  final List<String> activities = [
    'Read verse of the day',
    'Guided Scripture',
    'Meditate on the verse',
    'Pray',
    'Habit',
  ];

  final List<Map<String, dynamic>> days = [
    {'day': 1, 'date': 'Mar 04', 'completed': true},
    {'day': 2, 'date': 'Mar 05', 'completed': true},
    {'day': 3, 'date': 'Mar 06', 'completed': true},
    {'day': 4, 'date': 'Mar 07', 'completed': false},
    {'day': 5, 'date': 'Mar 08', 'completed': false},
    {'day': 6, 'date': 'Mar 09', 'completed': false},
    {'day': 7, 'date': 'Mar 10', 'completed': false},
    {'day': 8, 'date': 'Mar 11', 'completed': false},
    {'day': 9, 'date': 'Mar 12', 'completed': false},
    {'day': 10, 'date': 'Mar 13', 'completed': false},
  ];

  @override
  Widget build(BuildContext context) {
    final DateTime startDate = DateTime.now();
    final DateTime endDate = DateTime.now().add(
      Duration(days: widget.plan.totalDays),
    );
    final planDays = ref.watch(planDaysByPlanIdFutureProvider(widget.plan.id));
    final planDayContent = ref.watch(
      planDayContentFutureProvider(
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
              imageUrl:
                  // widget.plan.imageUrl ??
                  'https://drive.google.com/uc?export=view&id=1v94uQ1YInSQCXub1_cUOQDeZZm0KuM7H',
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
            ActivityList(
              tasks: planDayContent.value?.tasks ?? [],
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
          ],
        ),
      ),
    );
  }
}
