// This file contains the presentation layer for the home screen feature.
// It handles the UI for the main home screen after splash.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/home/data/week_plan.dart';
import 'package:flutter_pecha/features/home/presentation/utils.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/action_of_the_day_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/calendar_banner_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_card.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_pecha/features/plans/models/plan_subtasks_model.dart';
import 'package:flutter_pecha/features/plans/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/story_view/utils/story_dialog_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late List<PlanTasksModel> planItems;
  Timer? _dayCheckTimer;
  String _currentDay = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTodayPlan();
    _startDayCheckTimer();
  }

  void _startDayCheckTimer() {
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _checkAndUpdateDay();
    });
  }

  void _checkAndUpdateDay() {
    final today = DateTime.now();
    final dayName = DateFormat('EEEE').format(today).toLowerCase();
    if (dayName != _currentDay) {
      _currentDay = dayName;
      _updatePlanForNewDay();
    }
  }

  void _updatePlanForNewDay() {
    final weekPlan = ref.read(weekPlanProvider);
    final plan = weekPlan[_currentDay];
    setState(() {
      planItems =
          (plan["plan"] as List<dynamic>)
              .map((item) => PlanTasksModel.fromJson(item))
              .toList();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndUpdateDay();
    }
  }

  @override
  void dispose() {
    _dayCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializeTodayPlan() {
    final today = DateTime.now();
    final dayName = DateFormat('EEEE').format(today).toLowerCase();
    _currentDay = dayName;

    // Get the localized week plan
    final weekPlan = ref.read(weekPlanProvider);
    final plan = weekPlan[_currentDay];
    planItems =
        (plan["plan"] as List<dynamic>)
            .map((item) => PlanTasksModel.fromJson(item))
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(authState, localizations),
                _buildBody(context, localizations),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build the top bar
  Widget _buildTopBar(AuthState authState, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            localizations.home_today,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          Row(
            children: [
              IconButton(
                onPressed:
                    () => context.push(NotificationSettingsScreen.routeName),
                icon: Icon(Icons.notifications_none, size: 28),
              ),
              SizedBox(width: 16),
              if (authState.isGuest)
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Hero(
                    tag: 'profile-avatar',
                    child: Icon(Icons.account_circle, size: 32),
                  ),
                ),
              if (authState.isLoggedIn && !authState.isGuest)
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Hero(
                    tag: 'profile-avatar',
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          (authState.userProfile?.pictureUrl?.toString() ?? '')
                                  .isNotEmpty
                              ? NetworkImage(
                                authState.userProfile!.pictureUrl!.toString(),
                              )
                              : null,
                      child:
                          ((authState.userProfile?.pictureUrl?.toString() ?? '')
                                  .isEmpty)
                              ? const Icon(Icons.person, color: Colors.black54)
                              : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Build the scrollable body
  Widget _buildBody(BuildContext context, AppLocalizations localizations) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Banner
            CalendarBannerCard(
              title: 'Saka Dawa',
              subtitle: 'Full Moon',
              description:
                  'Celebrated in the fourth month of the Tibetan calendar',
              celebratedBy: 'ALL SCHOOL',
              imageUrl: 'https://picsum.photos/200/300',
            ),
            const SizedBox(height: 16),

            // doc: planitems - plan item from api call
            ...planItems.asMap().entries.map((entry) {
              final index = entry.key;
              final planItem = entry.value;

              // Get next plan item for appending to story
              final nextPlanItem =
                  index < planItems.length - 1 ? planItems[index + 1] : null;

              switch (index) {
                case 0:
                  // Verse card
                  return Column(
                    children: [
                      VerseCard(
                        verseText: planItem.subtasks[0].content!,
                        title: planItem.title,
                        nextCard:
                            nextPlanItem != null
                                ? {
                                  'heading': localizations.home_scripture,
                                  'title': nextPlanItem.title,
                                  'subtitle': '1-2 min',
                                  'iconWidget': getVideoThumbnail(
                                    nextPlanItem.subtasks[0].content!,
                                  ),
                                  'subtasks': [
                                    PlanSubtasksModel(
                                      id: 'guided_scripture',
                                      contentType: 'VIDEO',
                                      content:
                                          nextPlanItem.subtasks[0].content!,
                                      displayOrder: 0,
                                    ),
                                  ],
                                  'nextCard':
                                      index + 2 < planItems.length
                                          ? {
                                            'heading':
                                                localizations.home_meditation,
                                            'title': planItems[index + 2].title,
                                            'subtitle': '1-2 min',
                                            'iconWidget': getVideoThumbnail(
                                              planItems[index + 2]
                                                  .subtasks[0]
                                                  .label!,
                                            ),
                                            'subtasks': [
                                              PlanSubtasksModel(
                                                id: 'guided_meditation',
                                                contentType: 'VIDEO',
                                                content:
                                                    planItems[index + 2]
                                                        .subtasks[0]
                                                        .content!,
                                                displayOrder: 0,
                                              ),
                                            ],
                                          }
                                          : null,
                                }
                                : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                case 1:
                  // Go deeper card
                  return Column(
                    children: [
                      ActionOfTheDayCard(
                        heading: localizations.home_scripture,
                        title: planItem.title,
                        subtitle: "1-2 min",
                        iconWidget: getVideoThumbnail(
                          planItem.subtasks[0].content!,
                        ),
                        onTap:
                            () => showStoryDialog(
                              context: context,
                              subtasks: [
                                PlanSubtasksModel(
                                  id: 'guided_scripture',
                                  contentType: 'VIDEO',
                                  content: planItem.subtasks[0].content!,
                                  displayOrder: 0,
                                ),
                              ],
                              nextCard:
                                  nextPlanItem != null
                                      ? {
                                        'heading':
                                            localizations.home_meditation,
                                        'title': nextPlanItem.title,
                                        'subtitle': '1-2 min',
                                        'iconWidget': getVideoThumbnail(
                                          nextPlanItem.subtasks[0].content!,
                                        ),
                                        'subtasks': [
                                          PlanSubtasksModel(
                                            id: 'guided_meditation',
                                            contentType: 'VIDEO',
                                            content:
                                                nextPlanItem
                                                    .subtasks[0]
                                                    .content!,
                                            displayOrder: 0,
                                          ),
                                        ],
                                      }
                                      : null,
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                case 2:
                  // Meditation card - no next card (last item)
                  return Column(
                    children: [
                      ActionOfTheDayCard(
                        heading: localizations.home_meditation,
                        title: planItem.title,
                        subtitle: "1-2 min",
                        iconWidget: getVideoThumbnail(
                          planItem.subtasks[0].content!,
                        ),
                        onTap:
                            () => showStoryDialog(
                              context: context,
                              subtasks: [
                                PlanSubtasksModel(
                                  id: 'guided_meditation',
                                  contentType: 'VIDEO',
                                  content: planItem.subtasks[0].content!,
                                  displayOrder: 0,
                                ),
                              ],
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                default:
                  return const SizedBox.shrink();
              }
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
