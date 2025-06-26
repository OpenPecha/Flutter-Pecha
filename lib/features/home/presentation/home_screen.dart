// This file contains the presentation layer for the home screen feature.
// It handles the UI for the main home screen after splash.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/home/models/plan_item.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/action_of_the_day_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/view_illustration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

const Map<String, dynamic> dayPlan = {
  "verseText":
      "By thinking of all sentient beings\nAs more precious than a wish-fulfilling jewel\nFor accomplishing the highest aim,\nI will always hold them dear.",
  "verseImageUrl":
      "https://drive.google.com/uc?export=view&id=1M_IFmQGMrlBOHDWpSID_kesZiFUsV9zS",
  "scriptureVideoUrl":
      "https://www.youtube.com/watch?v=oFPVuddzCVA&list=PLEbXpuWAnGgikyJVrbzcNmuLpDYr7atZ2&index=3",
  "meditationAudioUrl":
      "https://drive.google.com/uc?export=view&id=18DxBd030-wbZSfkod8ot6P8_pfN2Y0C_",
  "meditationImageUrl":
      "https://drive.google.com/uc?export=view&id=1L6reDJvyCVGhxRgwQSVsIWkqkQWiuov8",
  "prayerData": [
    {
      "text": "May all sentient beings have happiness And its causes",
      "startTime": "00:00",
      "endTime": "00:05",
    },
    {
      "text": "May all sentient beings be free from suffering And its causes",
      "startTime": "00:05",
      "endTime": "00:11",
    },
    {
      "text": "May all beings never be separate from sorrowless bliss",
      "startTime": "00:11",
      "endTime": "00:15",
    },
    {
      "text":
          "May all beings abide in equanimity, free from bias, attachment, and aversion",
      "startTime": "00:16",
      "endTime": "00:24",
    },
  ],
  "prayerAudioUrl":
      "https://drive.google.com/uc?export=view&id=1uIU4Xp15FtFiu3ve0TZPqmYw1XrRpOfr",
  "mindTrainingImageUrl":
      "https://drive.google.com/uc?export=view&id=1H8r8pspaXqnF-_bWT53cBPJww7_ebcvs",
};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PlanItem planItem;

  @override
  void initState() {
    super.initState();
    planItem = PlanItem.fromJson(dayPlan);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(authState, localizations),
            _buildBody(context, localizations),
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
                // add a user avatar here
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    authState.userProfile?.pictureUrl?.toString() ?? '',
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
            Text(
              localizations.home_dailyRefresh,
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            VerseCard(
              imageUrl: planItem.verseImageUrl,
              verse: planItem.verseText,
            ),
            SizedBox(height: 16),
            ActionOfTheDayCard(
              title: "Guided Scripture",
              subtitle: "Read a scripture with a guided meditation",
              iconWidget: Image.asset(
                'assets/images/home/teaching.png',
                color: Theme.of(context).iconTheme.color,
                width: 80,
                height: 80,
              ),
              onTap:
                  () => context.push(
                    '/home/guided_scripture',
                    extra: planItem.scriptureVideoUrl,
                  ),
            ),
            SizedBox(height: 16),
            ActionOfTheDayCard(
              title: localizations.home_meditationTitle,
              subtitle: localizations.home_meditationSubtitle,
              iconWidget: Icon(Icons.self_improvement, size: 100),
              onTap:
                  () => context.push(
                    '/home/meditation_of_the_day',
                    extra: {
                      "meditationAudioUrl": planItem.meditationAudioUrl,
                      "meditationImageUrl": planItem.meditationImageUrl,
                    },
                  ),
            ),
            SizedBox(height: 16),
            ActionOfTheDayCard(
              title: localizations.home_prayerTitle,
              subtitle: localizations.home_prayerSubtitle,
              isSpace: true,
              iconWidget: FaIcon(FontAwesomeIcons.handsPraying, size: 60),
              onTap:
                  () => context.push(
                    '/home/prayer_of_the_day',
                    extra: {
                      "prayerAudioUrl": planItem.prayerAudioUrl,
                      "prayerData": planItem.prayerData,
                    },
                  ),
            ),
            SizedBox(height: 16),
            ActionOfTheDayCard(
              title: "Mind Training",
              subtitle: "",
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
                    transitionDuration: const Duration(milliseconds: 200),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return ViewIllustration(
                        imageUrl: planItem.mindTrainingImageUrl,
                      );
                    },
                  ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
