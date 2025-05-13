// This file contains the presentation layer for the home screen feature.
// It handles the UI for the main home screen after splash.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/stat_button.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/action_of_the_day_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [_buildTopBar(authState), _buildBody(context)]),
      ),
    );
  }

  // Build the top bar
  Widget _buildTopBar(AuthState authState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Today',
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
  Widget _buildBody(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'daily refresh'.toUpperCase(),
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            VerseOfTheDayCard(),
            SizedBox(height: 16),
            ActionOfTheDayCard(
              title: 'Meditation of the Day',
              subtitle: 'Awaken peace within.',
              iconWidget: Icon(
                Icons.self_improvement,
                size: 100,
                color: Colors.black,
              ),
              onTap: () => context.push('/home/meditation_of_the_day'),
            ),
            SizedBox(height: 16),
            ActionOfTheDayCard(
              title: 'Prayer of the Day',
              subtitle: 'Begin your day with a sacred intention.',
              isSpace: true,
              iconWidget: FaIcon(
                FontAwesomeIcons.handsPraying,
                size: 80,
                color: Colors.black,
              ),
              onTap: () => context.push('/home/prayer_of_the_day'),
            ),
            // Add more content here as needed
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
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.brown[700],
        borderRadius: BorderRadius.circular(24),
        // image: DecorationImage(
        //   image: AssetImage('assets/field.jpg'), // Replace with your image
        //   fit: BoxFit.cover,
        //   colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        // ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verse of the Day',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              '1 John 5:14 NIV',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Spacer(),
            Text(
              'This is the confidence we have in approaching God: that if we ask anything according to his will, he hears us.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatButton(
                  icon: Icons.favorite_border,
                  label: '392.5k',
                  onTap: () {
                    // Handle favorite tap
                  },
                ),
                StatButton(
                  icon: Icons.share,
                  label: '129.2k',
                  onTap: () {
                    // Handle share tap
                    handleShare();
                  },
                ),
                StatButton(
                  icon: Icons.text_snippet,
                  label: 'Text',
                  onTap: () {
                    // Handle text tap
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(Icons.home, size: 32),
          Icon(Icons.menu_book, size: 32),
          Icon(Icons.check_box, size: 32),
          Icon(Icons.menu, size: 32),
        ],
      ),
    );
  }
}
