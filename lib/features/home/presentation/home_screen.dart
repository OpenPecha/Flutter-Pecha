// This file contains the presentation layer for the home screen feature.
// It handles the UI for the main home screen after splash.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/home/data/week_plan.dart';
import 'package:flutter_pecha/features/home/models/plan_item.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/action_of_the_day_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/view_illustration.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/models/term/term.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/action_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late List<PlanItem> planItems;
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
              .map((item) => PlanItem.fromJson(item))
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
            .map((item) => PlanItem.fromJson(item))
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);
    final bottomBarVisible = ref.watch(bottomBarVisibleProvider);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(authState, localizations),
                _buildBody(context, localizations),
              ],
            ),
            if (bottomBarVisible) _buildBottomBar(context, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AppLocalizations localizations) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ActionButton(
              icon: Icons.library_books,
              label: 'Library',
              onTap: () {
                // context.push('/library');
                context.push(
                  '/texts/detail',
                  extra: Term(
                    id: "67dd22a8d9f06ab28feedc90",
                    title: "",
                    description: "",
                    slug: "",
                    hasChild: false,
                  ),
                );
              },
            ),
            ActionButton(
              icon: Icons.info_outline,
              label: 'Creator Info',
              onTap: () {
                context.push('/creator_info');
              },
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
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Icon(Icons.notifications_none, size: 28),
              SizedBox(width: 16),
              if (authState.isGuest) Icon(Icons.account_circle, size: 32),
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
    final language = ref.watch(localeProvider);
    final isChinese = language?.languageCode == 'zh';
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...planItems.map((planItem) {
              switch (planItem.contentType) {
                case "text":
                  return Column(
                    children: [
                      VerseCard(
                        verse: planItem.content,
                        author: planItem.author,
                      ),
                      SizedBox(height: 16),
                    ],
                  );
                case "video":
                  return Column(
                    children: [
                      ActionOfTheDayCard(
                        title:
                            isChinese
                                ? planItem.label
                                : localizations.home_goDeeper,
                        subtitle: "4-5 min",
                        iconWidget: Image.asset(
                          'assets/images/home/teaching.png',
                          color: Theme.of(context).iconTheme.color,
                          width: 80,
                          height: 80,
                        ),
                        onTap:
                            () => context.push(
                              '/home/guided_scripture',
                              extra: planItem.content,
                            ),
                      ),
                      SizedBox(height: 16),
                    ],
                  );
                case "audio":
                  return Column(
                    children: [
                      ActionOfTheDayCard(
                        title:
                            planItem.label == "Meditation"
                                ? localizations.home_meditationTitle
                                : localizations.home_recitation,
                        subtitle: "3-4 min",
                        iconWidget:
                            planItem.label == "Meditation"
                                ? Icon(Icons.self_improvement, size: 80)
                                : FaIcon(
                                  FontAwesomeIcons.handsPraying,
                                  size: 60,
                                ),
                        onTap:
                            () => context.push(
                              '/home/meditation_video',
                              extra: planItem.content,
                            ),
                      ),
                      SizedBox(height: 16),
                    ],
                  );
                case "image":
                  return Column(
                    children: [
                      ActionOfTheDayCard(
                        title:
                            planItem.label == "My Intention for Today"
                                ? localizations.home_intention
                                : localizations.home_bringing,
                        subtitle: "1 min",
                        iconWidget: Image.asset(
                          'assets/images/home/mind_free.png',
                          color: Theme.of(context).iconTheme.color,
                          width: 80,
                          height: 80,
                        ),
                        onTap:
                            () => showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: "Close",
                              transitionDuration: const Duration(
                                milliseconds: 200,
                              ),
                              pageBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                              ) {
                                return ViewIllustration(
                                  imageUrl: planItem.content,
                                );
                              },
                            ),
                      ),
                      SizedBox(height: 16),
                    ],
                  );
                default:
                  return SizedBox.shrink();
              }
            }),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
