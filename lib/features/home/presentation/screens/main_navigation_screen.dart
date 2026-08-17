import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/more/presentation/me_screen.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/connect_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/practice_explore_screen.dart';
import 'package:flutter_pecha/shared/widgets/appBottomNavBar/app_bottom_nav_bar.dart';
import 'package:flutter_pecha/shared/widgets/appBottomNavBar/app_bottom_nav_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav tabs in display order. The enum index matches the position in
/// [mainNavigationItems] and the int value stored in
/// [mainNavigationIndexProvider]; prefer `MainTab.x.index` over raw numbers.
enum MainTab { home, practice, connect, me }

final mainNavigationIndexProvider = StateProvider<int>(
  (ref) => MainTab.home.index,
);

/// Holds an enrolled plan that should be opened after the home screen's
/// notification-permission flow completes. Set during onboarding completion,
/// consumed once by [HomeScreen], and cleared immediately after navigation.
final pendingOnboardingPlanProvider = StateProvider<UserPlansModel?>(
  (ref) => null,
);

List<AppBottomBarItemModel<int>> mainNavigationItems(
  BuildContext context, {
  String? meAvatarUrl,
}) {
  final localizations = AppLocalizations.of(context)!;
  return [
    AppBottomBarItemModel(
      type: 0,
      label: localizations.nav_home,
      selectedWidget: const HomeScreen(),
      selectedIconData: AppAssets.homeSelected,
      unSelectedIconData: AppAssets.homeUnselected,
    ),
    AppBottomBarItemModel(
      type: 1,
      label: localizations.nav_practice,
      selectedWidget: const PracticeExploreScreen(),
      selectedIconData: AppAssets.practiceSelected,
      unSelectedIconData: AppAssets.practiceUnselected,
    ),
    AppBottomBarItemModel(
      type: 2,
      label: localizations.nav_connect,
      selectedWidget: const ConnectScreen(),
      selectedIconData: AppAssets.connectSelected,
      unSelectedIconData: AppAssets.connectUnselected,
    ),
    AppBottomBarItemModel(
      type: 3,
      label: localizations.nav_me,
      selectedWidget: const MeScreen(),
      selectedIconData: AppAssets.meSelected,
      unSelectedIconData: AppAssets.meUnselected,
      avatarUrl: meAvatarUrl,
    ),
    //  AppBottomBarItemModel(
    //   type: 1,
    //   label: localizations.nav_learn,
    //   selectedWidget: const LearnScreen(),
    //   selectedIconData: AppAssets.textsSelected,
    //   unSelectedIconData: AppAssets.textsUnselected,
    // ),
    // AppBottomBarItemModel(
    //   type: 4,
    //   label: localizations.nav_explore,
    //   selectedWidget: const ExploreScreen(),
    //   selectedIconData: AppAssets.exploreSelected,
    //   unSelectedIconData: AppAssets.exploreUnselected,
    // ),
  ];
}

class MainNavigationBottomBar extends ConsumerWidget {
  const MainNavigationBottomBar({super.key, this.onTabChanged});

  final ValueChanged<int>? onTabChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = ref.watch(userProvider).user;
    final meAvatarUrl =
        authState.isLoggedIn && !authState.isGuest
            ? user?.avatarUrl
            : null;
    final items = mainNavigationItems(context, meAvatarUrl: meAvatarUrl);
    final selectedIndex = ref.watch(mainNavigationIndexProvider);

    return AppBottomNavBar(
      items: items,
      onChanged: (index) {
        ref.read(mainNavigationIndexProvider.notifier).state = index;
        onTabChanged?.call(index);
      },
      type: selectedIndex,
    );
  }
}

/// Shell scaffold used by the [ShellRoute] in the router.
/// Provides a persistent bottom navigation bar that stays fixed across
/// route transitions — the Flutter equivalent of React's layout.tsx.
///
/// On Android, intercepts the system back gesture so that:
///   1. Any pushed shell route (Settings, Calendar, …) is popped first.
///   2. If no route to pop and the current tab is not Home, return to Home.
///   3. Only when already on the Home tab with nothing to pop is the Activity
///      allowed to finish.
/// iOS is left untouched — there is no system back button and intercepting the
/// swipe-back gesture here would conflict with the native horizontal swipe.
class HomeShellScaffold extends ConsumerWidget {
  const HomeShellScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final hideBottomNav = location.startsWith('/home/timers');

    final bool isAndroid =
        Theme.of(context).platform == TargetPlatform.android;
    final int selectedIndex = ref.watch(mainNavigationIndexProvider);
    final bool isHomeTab = selectedIndex == MainTab.home.index;
    final bool routerCanPop = GoRouter.of(context).canPop();
    final bool shellCanPop =
        shellNavigatorKey.currentState?.canPop() ?? false;
    final bool hasRouteToPop = routerCanPop || shellCanPop;

    // On Android: block exit when there are nested routes to pop OR when we are
    // not yet on the Home tab. On iOS (and other platforms): never block — the
    // platform handles back gestures natively.
    final bool allowPop = !isAndroid || (!hasRouteToPop && isHomeTab);

    final scaffold = Scaffold(
      body: child,
      bottomNavigationBar:
          hideBottomNav
              ? null
              : MainNavigationBottomBar(
                onTabChanged: (_) {
                  final shell = shellNavigatorKey.currentState;
                  if (shell != null && shell.canPop()) {
                    shell.popUntil((route) => route.isFirst);
                  }
                  if (location != '/home') {
                    context.go('/home');
                  }
                },
              ),
    );

    if (!isAndroid) return scaffold;

    return PopScope(
      canPop: allowPop,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) return;
        // Pop a GoRouter-managed shell page first (e.g. /home/settings).
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
          return;
        }
        // Pop an imperatively-pushed Navigator page on the shell stack.
        final NavigatorState? shell = shellNavigatorKey.currentState;
        if (shell != null && shell.canPop()) {
          shell.pop();
          return;
        }
        // At a non-Home tab root: return to Home tab.
        if (ref.read(mainNavigationIndexProvider) != MainTab.home.index) {
          ref.read(mainNavigationIndexProvider.notifier).state =
              MainTab.home.index;
        }
        // If already on Home tab with nothing to pop, allowPop is true so
        // Android handles the exit automatically.
      },
      child: scaffold,
    );
  }
}

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = mainNavigationItems(context);
    final selectedIndex = ref.watch(mainNavigationIndexProvider);

    return items[selectedIndex].selectedWidget ?? const SizedBox.shrink();
  }
}
