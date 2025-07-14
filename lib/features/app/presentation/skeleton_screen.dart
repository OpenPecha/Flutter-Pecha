// This file is the overall app shell with a bottom navigation bar for main sections.
// Tabs: Home, Texts, Plans, Settings.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/presentation/plan_list.dart';
import 'package:flutter_pecha/features/texts/presentation/library_catalog_screen.dart';
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
    LibraryCatalogScreen(), // Texts tab
    Center(child: Text('Coming Soon')), // Plans tab placeholder
    // PlanList(), // Plans tab
    MoreScreen(), // Settings tab placeholder
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
