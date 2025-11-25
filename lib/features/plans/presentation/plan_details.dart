import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/plans/data/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
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
  late int selectedDay;

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
    final language = widget.plan.language;
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final fontSize = language == 'bo' ? 22.0 : 18.0;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plan.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
            height: lineHeight,
            fontSize: fontSize,
          ),
        ),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'unenroll') {
                _showUnenrollDialog(context);
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'unenroll',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, size: 20),
                        SizedBox(width: 12),
                        Text(localizations.plan_unenroll),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PlanCoverImage(imageUrl: widget.plan.imageUrl ?? ''),
            planDays.when(
              data: (days) {
                if (days.isEmpty) {
                  return _buildEmptyDayCarouselState(context);
                }
                return dayCompletionStatus.when(
                  data:
                      (completionStatus) => DayCarousel(
                        language: language,
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
                        language: language,
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
                        language: language,
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
                  _buildDayTitle(language, selectedDay),
                  const SizedBox(height: 8),
                  userPlanDayContent.when(
                    data:
                        (dayContent) => ActivityList(
                          language: language,
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
    final localizations = AppLocalizations.of(context)!;
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(child: Text(localizations.no_days_available)),
    );
  }

  Widget _buildDayTitle(String language, int day) {
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final fontSize = language == 'bo' ? 22.0 : 18.0;
    return Text(
      "Day $day of ${widget.plan.totalDays}",
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
        height: lineHeight,
      ),
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

    try {
      bool success;
      if (task.isCompleted) {
        success = await ref.read(deleteTaskFutureProvider(taskId).future);
      } else {
        success = await ref.read(completeTaskFutureProvider(taskId).future);
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

  void _showUnenrollDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final language = locale.languageCode;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(localizations.plan_unenroll),
          content: Text(
            language == 'bo'
                ? '${widget.plan.title} ${localizations.unenroll_confirmation}\n\n ${localizations.unenroll_message}'
                : '${localizations.unenroll_confirmation} "${widget.plan.title}"?\n\n ${localizations.unenroll_message}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(localizations.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleUnenroll();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(localizations.plan_unenroll),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleUnenroll() async {
    try {
      final success = await ref.read(
        userPlanUnsubscribeFutureProvider(widget.plan.id).future,
      );

      if (success) {
        // Invalidate plans to refresh the list
        ref.invalidate(myPlansPaginatedProvider);
        ref.invalidate(findPlansPaginatedProvider);
        ref.invalidate(userPlansFutureProvider);

        if (mounted) {
          // Pop back to plans list
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have been unenrolled from "${widget.plan.title}"',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorSnackbar(
            'Unable to unenroll at this time. Please try again.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error unenrolling from plan: $e');
      if (mounted) {
        _showErrorSnackbar(
          'Something went wrong. Please check your connection and try again.',
        );
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
