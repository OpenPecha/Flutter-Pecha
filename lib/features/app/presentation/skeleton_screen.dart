// This file is the overall app shell with a bottom navigation bar for main sections.
// Tabs: Home, Texts, Plans, Settings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/home/presentation/home_screen.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';

/// Riverpod provider for bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class SkeletonScreen extends ConsumerWidget {
  const SkeletonScreen({super.key});

  static final List<Widget> _pages = <Widget>[
    HomeScreen(), // Home tab
    Center(child: Text('Texts')), // Texts tab placeholder
    Center(child: Text('Plans')), // Plans tab placeholder
    MoreScreen(), // Settings tab placeholder
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    return Scaffold(
      body: _pages[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey, // Set your desired color
              width: 0.5, // Set your desired border width
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (idx) => ref.read(bottomNavIndexProvider.notifier).state = idx,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'Texts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_box),
              label: 'Plans',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
          ],
        ),
      ),
    );
  }
}
