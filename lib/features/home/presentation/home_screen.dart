// This file contains the presentation layer for the home screen feature.
// It handles the UI for the main home screen after splash.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/action_of_the_day_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/view_illustration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            VerseOfTheDayCard(),
            SizedBox(height: 16),
            ActionOfTheDayCard(
              title: "Guided Scripture",
              subtitle: "Read a scripture with a guided meditation",
              iconWidget: Image.asset(
                'assets/images/home/scripture.png',
                width: 100,
                height: 100,
              ),
              onTap: () => context.push('/home/meditation_of_the_day'),
            ),
            SizedBox(height: 16),
            ActionOfTheDayCard(
              title: localizations.home_meditationTitle,
              subtitle: localizations.home_meditationSubtitle,
              iconWidget: Icon(Icons.self_improvement, size: 100),
              onTap: () => context.push('/home/meditation_of_the_day'),
            ),
            SizedBox(height: 16),
            ActionOfTheDayCard(
              title: localizations.home_prayerTitle,
              subtitle: localizations.home_prayerSubtitle,
              isSpace: true,
              iconWidget: FaIcon(FontAwesomeIcons.handsPraying, size: 60),
              onTap: () => context.push('/home/prayer_of_the_day'),
            ),
            SizedBox(height: 16),
            ActionOfTheDayCard(
              title: "Mind Training",
              subtitle: "",
              iconWidget: Image.asset(
                'assets/images/home/brain.png',
                width: 100,
                height: 100,
              ),
              onTap:
                  () => showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: "Close",
                    transitionDuration: const Duration(milliseconds: 200),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return ViewIllustration(
                        imageUrl:
                            "https://drive.google.com/uc?export=view&id=1H8r8pspaXqnF-_bWT53cBPJww7_ebcvs",
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

class VerseOfTheDayCard extends StatelessWidget {
  const VerseOfTheDayCard({super.key});

  void handleShare() {
    // TODO: implement handleShare
  }

  void handleFavorite() {
    // TODO: implement handleFavorite
  }

  void handleText() {
    // TODO: implement handleText
  }

  @override
  Widget build(BuildContext context) {
    final illustrationUrl =
        "https://drive.google.com/uc?export=view&id=1M_IFmQGMrlBOHDWpSID_kesZiFUsV9zS";
    return GestureDetector(
      onTap: () {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Close",
          transitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) {
            return ViewIllustration(imageUrl: illustrationUrl);
          },
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.brown[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '''ཇི་སྲིད་ནམ་མཁའ་གནས་པ་དང་།
འགྲོ་བ་ཇི་སྲིད་གནས་གྱུར་པ།
དེ་སྲིད་བདག་ནི་གནས་གྱུར་ནས།
འགྲོ་བའི་སྡུག་བསྔལ་སེལ་བ་ཤོག།''',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 2,
                  fontFamily: 'MonlamTibetan',
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Spacer(),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     StatButton(
              //       icon: Icons.favorite_border,
              //       label: '392.5k',
              //       onTap: () {
              //         // Handle favorite tap
              //       },
              //     ),
              //     StatButton(
              //       icon: Icons.share,
              //       label: '129.2k',
              //       onTap: () {
              //         // Handle share tap
              //         handleShare();
              //       },
              //     ),
              //     StatButton(
              //       icon: Icons.text_snippet,
              //       label: 'Text',
              //       onTap: () {
              //         // Handle text tap
              //       },
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
