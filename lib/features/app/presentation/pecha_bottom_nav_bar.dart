import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'skeleton_screen.dart';
import 'package:go_router/go_router.dart';

class PechaBottomNavBar extends ConsumerWidget {
  const PechaBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark, // MAN 800 - #871C1C
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              ref: ref,
              index: 0,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              isSelected: selectedIndex == 0,
            ),
            _buildNavItem(
              context: context,
              ref: ref,
              index: 1,
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book,
              label: 'Texts',
              isSelected: selectedIndex == 1,
            ),
            _buildNavItem(
              context: context,
              ref: ref,
              index: 2,
              icon: FontAwesomeIcons.handsPraying,
              selectedIcon: FontAwesomeIcons.handsPraying,
              label: 'Recitations',
              isSelected: selectedIndex == 2,
            ),
            _buildNavItem(
              context: context,
              ref: ref,
              index: 3,
              icon: Icons.check_box_outlined,
              selectedIcon: Icons.check_box,
              label: 'Practice',
              isSelected: selectedIndex == 3,
            ),
            _buildNavItem(
              context: context,
              ref: ref,
              index: 4,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: 'Setting',
              isSelected: selectedIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          final currentIndex = ref.read(bottomNavIndexProvider);
          if (index != currentIndex) {
            ref.read(bottomNavIndexProvider.notifier).state = index;
            // Navigate to home when tapping any tab (router will handle the rest)
            context.go('/home');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: AppColors.surfaceLight,
                size: isSelected ? 26 : 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.surfaceLight,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Selected indicator bar
              if (isSelected)
                Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(height: 3),
            ],
          ),
        ),
      ),
    );
  }
}
