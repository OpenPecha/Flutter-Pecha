// This file is the overall app shell with a bottom navigation bar for main sections.
// Tabs: Home, Texts, Recitations, Plans, Settings.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/presentation/screens/plans_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/screens/collections/collections_screen.dart';
import 'package:flutter_pecha/features/recitation/presentation/screens/recitations_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/home/presentation/home_screen.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';

/// Riverpod provider for bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class SkeletonScreen extends ConsumerWidget {
  const SkeletonScreen({super.key});

  static final List<Widget> _pages = <Widget>[
    HomeScreen(), // Home tab
    CollectionsScreen(), // Texts tab
    RecitationsScreen(), // Recitations tab
    PlansScreen(), // Practice Plans tab
    MoreScreen(), // Settings/More tab
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    return Scaffold(
      body: _pages[selectedIndex],
      bottomNavigationBar: PechaBottomNavBar(),
    );
  }
}
