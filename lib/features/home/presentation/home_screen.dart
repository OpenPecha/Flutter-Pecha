// This file contains the presentation layer for the home screen feature.
// It handles the UI for the main home screen after splash.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/home/data/providers/featured_day_provider.dart';
import 'package:flutter_pecha/features/home/models/prayer_data.dart';
import 'package:flutter_pecha/features/home/presentation/utils.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/action_of_the_day_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/calendar_banner_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_card.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_pecha/features/plans/models/response/featured_day_response.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/presentation/json_data.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/presentation/prayer_of_the_day_screen.dart';
import 'package:flutter_pecha/features/story_view/utils/story_dialog_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _dayCheckTimer;
  DateTime? _lastFetchedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastFetchedDate = DateTime.now();
    _startDayCheckTimer();
  }

  void _startDayCheckTimer() {
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _checkAndUpdateDay();
    });
  }

  void _checkAndUpdateDay() {
    final today = DateTime.now();
    final lastFetched = _lastFetchedDate;

    // Check if day has changed (compare year, month, day)
    if (lastFetched == null ||
        today.year != lastFetched.year ||
        today.month != lastFetched.month ||
        today.day != lastFetched.day) {
      _lastFetchedDate = today;
      _refreshFeaturedDay();
    }
  }

  void _refreshFeaturedDay() {
    // Invalidate the provider to force refresh
    ref.invalidate(featuredDayFutureProvider);
  }

  /// Manual refetch/retry method that can be called from UI
  void refetchFeaturedDay() {
    // Refresh the provider to immediately fetch fresh data
    // ignore: unused_result
    ref.refresh(featuredDayFutureProvider);
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

  /// Returns a time-based greeting based on the current hour
  String _getTimeBasedGreeting(AppLocalizations localizations) {
    final hour = DateTime.now().hour;
    if (hour >= 1 && hour < 12) {
      return localizations.home_good_morning;
    } else if (hour >= 12 && hour < 17) {
      return localizations.home_good_afternoon;
    } else {
      return localizations.home_good_evening;
    }
  }

  // Build the top bar
  Widget _buildTopBar(AuthState authState, AppLocalizations localizations) {
    // final url = s3AudioUrl;
    // final prayerData =
    //     tibetanAudioJson.map((e) => PrayerData.fromJson(e)).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GestureDetector(
          //   onTap:
          //       () => Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder:
          //               (context) => PrayerOfTheDayScreen(
          //                 audioUrl: url,
          //                 prayerData: prayerData,
          //                 audioHeaders: {},
          //               ),
          //         ),
          //       ),
          //   child:
          Text(
            localizations.home_today,
            // _getTimeBasedGreeting(localizations),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          // ),
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
                              ? authState.userProfile!.pictureUrl!
                                  .toString()
                                  .cachedNetworkImageProvider
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
    final featuredDayAsync = ref.watch(featuredDayFutureProvider);

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Banner
            // CalendarBannerCard(
            //   title: 'Saka Dawa',
            //   subtitle: 'Full Moon',
            //   description:
            //       'Celebrated in the fourth month of the Tibetan calendar',
            //   celebratedBy: 'ALL SCHOOL',
            //   imageUrl: 'https://picsum.photos/200/300',
            // ),
            // const SizedBox(height: 16),

            // Handle loading, error, and data states
            featuredDayAsync.when(
              data: (planItems) {
                if (planItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No featured content available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // doc: planitems - plan item from api call
                    ...planItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final planItem = entry.value;

                      // Get next plan item for appending to story
                      final nextPlanItem =
                          index < planItems.length - 1
                              ? planItems[index + 1]
                              : null;

                      switch (index) {
                        case 0:
                          // Verse card
                          return Column(
                            children: [
                              VerseCard(
                                verseText: planItem.subtasks[0].content,
                                title: planItem.title,
                                subtask: UserSubtasksDto(
                                  id: planItem.id,
                                  contentType: planItem.subtasks[0].contentType,
                                  content: planItem.subtasks[0].content,
                                  displayOrder:
                                      planItem.subtasks[0].displayOrder,
                                  isCompleted: false,
                                ),
                                nextCard:
                                    nextPlanItem != null
                                        ? {
                                          'heading':
                                              localizations.home_scripture,
                                          'title': nextPlanItem.title,
                                          'subtitle': '1-2 min',
                                          'iconWidget': getVideoThumbnail(
                                            nextPlanItem.subtasks[0].content,
                                          ),
                                          'subtasks': [
                                            UserSubtasksDto(
                                              id: nextPlanItem.subtasks[0].id,
                                              contentType:
                                                  nextPlanItem
                                                      .subtasks[0]
                                                      .contentType,
                                              content:
                                                  nextPlanItem
                                                      .subtasks[0]
                                                      .content,
                                              displayOrder:
                                                  nextPlanItem
                                                      .subtasks[0]
                                                      .displayOrder,
                                              isCompleted: false,
                                            ),
                                          ],
                                          'nextCard':
                                              index + 2 < planItems.length
                                                  ? {
                                                    'heading':
                                                        localizations
                                                            .home_meditation,
                                                    'title':
                                                        planItems[index + 2]
                                                            .title,
                                                    'subtitle': '1-2 min',
                                                    'iconWidget':
                                                        getVideoThumbnail(
                                                          planItems[index + 2]
                                                              .subtasks[0]
                                                              .content,
                                                        ),
                                                    'subtasks': [
                                                      UserSubtasksDto(
                                                        id:
                                                            planItems[index + 2]
                                                                .subtasks[0]
                                                                .id,
                                                        contentType:
                                                            planItems[index + 2]
                                                                .subtasks[0]
                                                                .contentType,
                                                        content:
                                                            planItems[index + 2]
                                                                .subtasks[0]
                                                                .content,
                                                        displayOrder:
                                                            planItems[index + 2]
                                                                .subtasks[0]
                                                                .displayOrder,
                                                        isCompleted: false,
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
                                  planItem.subtasks[0].content,
                                ),
                                onTap:
                                    () => showStoryDialog(
                                      context: context,
                                      subtasks: [
                                        UserSubtasksDto(
                                          id: planItem.subtasks[0].id,
                                          contentType:
                                              planItem.subtasks[0].contentType,
                                          content: planItem.subtasks[0].content,
                                          displayOrder:
                                              planItem.subtasks[0].displayOrder,
                                          isCompleted: false,
                                        ),
                                      ],
                                      nextCard:
                                          nextPlanItem != null
                                              ? {
                                                'heading':
                                                    localizations
                                                        .home_meditation,
                                                'title': nextPlanItem.title,
                                                'subtitle': '1-2 min',
                                                'iconWidget': getVideoThumbnail(
                                                  nextPlanItem
                                                      .subtasks[0]
                                                      .content,
                                                ),
                                                'subtasks': [
                                                  UserSubtasksDto(
                                                    id:
                                                        nextPlanItem
                                                            .subtasks[0]
                                                            .id,
                                                    contentType:
                                                        nextPlanItem
                                                            .subtasks[0]
                                                            .contentType,
                                                    content:
                                                        nextPlanItem
                                                            .subtasks[0]
                                                            .content,
                                                    displayOrder:
                                                        nextPlanItem
                                                            .subtasks[0]
                                                            .displayOrder,
                                                    isCompleted: false,
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
                                  planItem.subtasks[0].content,
                                ),
                                onTap:
                                    () => showStoryDialog(
                                      context: context,
                                      subtasks: [
                                        UserSubtasksDto(
                                          id: planItem.subtasks[0].id,
                                          contentType:
                                              planItem.subtasks[0].contentType,
                                          content: planItem.subtasks[0].content,
                                          displayOrder:
                                              planItem.subtasks[0].displayOrder,
                                          isCompleted: false,
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
                );
              },
              loading:
                  () => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load featured day content',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: refetchFeaturedDay,
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
