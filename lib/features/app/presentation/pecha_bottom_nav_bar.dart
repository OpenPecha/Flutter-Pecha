import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'skeleton_screen.dart';
import 'package:go_router/go_router.dart';

class PechaBottomNavBar extends ConsumerWidget {
  const PechaBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
              label: localizations.nav_home,
              isSelected: selectedIndex == 0,
            ),
            _buildNavItem(
              context: context,
              ref: ref,
              index: 1,
              icon: Icons.book_outlined,
              selectedIcon: Icons.book,
              label: localizations.nav_texts,
              isSelected: selectedIndex == 1,
            ),
            _buildNavItem(
              context: context,
              ref: ref,
              index: 2,
              icon: FontAwesomeIcons.handsPraying,
              selectedIcon: FontAwesomeIcons.handsPraying,
              label: localizations.nav_recitations,
              isSelected: selectedIndex == 2,
            ),
            _buildNavItem(
              context: context,
              ref: ref,
              index: 3,
              icon: Icons.auto_awesome_outlined,
              selectedIcon: Icons.auto_awesome,
              // icon: FontAwesomeIcons.microchip,
              // selectedIcon: FontAwesomeIcons.microchip,
              label: localizations.nav_ai_mode,
              isSelected: selectedIndex == 3,
            ),
            _buildNavItem(
              context: context,
              ref: ref,
              index: 4,
              icon: Icons.check_box_outlined,
              selectedIcon: Icons.check_box,
              label: localizations.nav_practice,
              isSelected: selectedIndex == 4,
            ),
            _buildNavItem(
              context: context,
              ref: ref,
              index: 5,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: localizations.nav_settings,
              isSelected: selectedIndex == 5,
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
    final locale = ref.watch(localeProvider);
    final fontSize = locale.languageCode == 'bo' ? 14.0 : 12.0;
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
                size: isSelected ? 26 : 24,
              ),
              const SizedBox(height: 2),
              MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.0)),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
