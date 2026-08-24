import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Minimal test scaffold
//
// Replicates the PopScope logic from HomeShellScaffold without pulling in
// the real MainNavigationBottomBar (which touches auth/GetIt providers).
// ---------------------------------------------------------------------------

/// A lightweight test widget that applies the same Android-back interceptor
/// logic as [HomeShellScaffold] but renders no bottom nav bar, so no auth or
/// GetIt dependencies are needed.
class _TestShellScaffold extends ConsumerWidget {
  const _TestShellScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isAndroid =
        Theme.of(context).platform == TargetPlatform.android;
    final int selectedIndex = ref.watch(mainNavigationIndexProvider);
    final bool isHomeTab = selectedIndex == MainTab.home.index;
    final bool isAtHomeRoute =
        GoRouterState.of(context).uri.path == '/home';
    final bool routerCanPop = GoRouter.of(context).canPop();
    final bool shellCanPop =
        shellNavigatorKey.currentState?.canPop() ?? false;
    final bool hasRouteToPop = routerCanPop || shellCanPop;
    final bool allowPop =
        !isAndroid || (!hasRouteToPop && isHomeTab && isAtHomeRoute);

    final scaffold = Scaffold(body: child);

    if (!isAndroid) return scaffold;

    return PopScope(
      canPop: allowPop,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) return;
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
          return;
        }
        final NavigatorState? shell = shellNavigatorKey.currentState;
        if (shell != null && shell.canPop()) {
          shell.pop();
          return;
        }
        if (ref.read(mainNavigationIndexProvider) != MainTab.home.index) {
          ref.read(mainNavigationIndexProvider.notifier).state =
              MainTab.home.index;
        }
        if (GoRouterState.of(context).uri.path != '/home') {
          context.go('/home');
        }
      },
      child: scaffold,
    );
  }
}

// ---------------------------------------------------------------------------
// Router factory
// ---------------------------------------------------------------------------

/// Builds a minimal GoRouter that uses [_TestShellScaffold] as the shell and
/// exposes /home and /home/settings.
GoRouter _buildRouter({required GlobalKey<NavigatorState> shellKey}) {
  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'root-test'),
    initialLocation: '/home',
    routes: [
      ShellRoute(
        navigatorKey: shellKey,
        builder: (context, state, child) =>
            _TestShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const Text('home-tab'),
            routes: [
              GoRoute(
                path: 'settings',
                builder: (_, __) => const Text('settings-page'),
              ),
            ],
          ),
          // Sibling of /home in the same shell — models /about, /legal, etc.
          GoRoute(
            path: '/about',
            builder: (_, __) => const Text('about-page'),
          ),
        ],
      ),
    ],
  );
}

/// Pumps the test shell and returns the [ProviderContainer].
Future<ProviderContainer> _pumpScaffold(
  WidgetTester tester, {
  required TargetPlatform platform,
  required GlobalKey<NavigatorState> shellKey,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final router = _buildRouter(shellKey: shellKey);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: ThemeData(platform: platform),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Sends the system back signal and returns whether the framework intercepted it.
Future<bool> _triggerSystemBack(WidgetTester tester) async {
  final handled = await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  return handled;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android back navigation (HomeShellScaffold logic)', () {
    late GlobalKey<NavigatorState> shellKey;

    setUp(() {
      shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell-test');
    });

    testWidgets(
      'Home tab + nothing to pop: back is NOT intercepted (allows Activity to finish)',
      (tester) async {
        final container = await _pumpScaffold(
          tester,
          platform: TargetPlatform.android,
          shellKey: shellKey,
        );

        expect(find.text('home-tab'), findsOneWidget);
        expect(container.read(mainNavigationIndexProvider), MainTab.home.index);

        // canPop == true → framework returns false (i.e. Activity may exit).
        final handled = await _triggerSystemBack(tester);
        expect(handled, isFalse);
      },
    );

    testWidgets(
      'Practice tab: back switches to Home tab and does not exit',
      (tester) async {
        final container = await _pumpScaffold(
          tester,
          platform: TargetPlatform.android,
          shellKey: shellKey,
        );

        container.read(mainNavigationIndexProvider.notifier).state =
            MainTab.practice.index;
        await tester.pump();

        final handled = await _triggerSystemBack(tester);

        expect(handled, isTrue);
        expect(container.read(mainNavigationIndexProvider), MainTab.home.index);
        expect(find.byType(_TestShellScaffold), findsOneWidget);
      },
    );

    testWidgets(
      'Connect tab: back switches to Home tab and does not exit',
      (tester) async {
        final container = await _pumpScaffold(
          tester,
          platform: TargetPlatform.android,
          shellKey: shellKey,
        );

        container.read(mainNavigationIndexProvider.notifier).state =
            MainTab.connect.index;
        await tester.pump();

        final handled = await _triggerSystemBack(tester);

        expect(handled, isTrue);
        expect(container.read(mainNavigationIndexProvider), MainTab.home.index);
      },
    );

    testWidgets(
      'Me tab: back switches to Home tab and does not exit',
      (tester) async {
        final container = await _pumpScaffold(
          tester,
          platform: TargetPlatform.android,
          shellKey: shellKey,
        );

        container.read(mainNavigationIndexProvider.notifier).state =
            MainTab.me.index;
        await tester.pump();

        final handled = await _triggerSystemBack(tester);

        expect(handled, isTrue);
        expect(container.read(mainNavigationIndexProvider), MainTab.home.index);
      },
    );

    testWidgets(
      '/home/settings: back pops to /home without changing tab index',
      (tester) async {
        final container = await _pumpScaffold(
          tester,
          platform: TargetPlatform.android,
          shellKey: shellKey,
        );

        final context = tester.element(find.byType(_TestShellScaffold));
        GoRouter.of(context).push('/home/settings');
        await tester.pumpAndSettle();
        expect(find.text('settings-page'), findsOneWidget);

        final handled = await _triggerSystemBack(tester);
        expect(handled, isTrue);
        await tester.pumpAndSettle();

        expect(find.text('home-tab'), findsOneWidget);
        // Tab index stays Home — a route was popped, not a tab switch.
        expect(
          container.read(mainNavigationIndexProvider),
          MainTab.home.index,
        );
      },
    );

    testWidgets(
      'go(/about) with Me tab: back restores /home AND Home tab',
      (tester) async {
        final container = await _pumpScaffold(
          tester,
          platform: TargetPlatform.android,
          shellKey: shellKey,
        );

        container.read(mainNavigationIndexProvider.notifier).state =
            MainTab.me.index;
        final context = tester.element(find.byType(_TestShellScaffold));
        GoRouter.of(context).go('/about');
        await tester.pumpAndSettle();
        expect(find.text('about-page'), findsOneWidget);

        final handled = await _triggerSystemBack(tester);
        expect(handled, isTrue);
        expect(find.text('home-tab'), findsOneWidget);
        expect(find.text('about-page'), findsNothing);
        expect(container.read(mainNavigationIndexProvider), MainTab.home.index);
      },
    );

    testWidgets(
      'go(/about) with Home tab: back restores /home instead of exiting',
      (tester) async {
        await _pumpScaffold(
          tester,
          platform: TargetPlatform.android,
          shellKey: shellKey,
        );

        final context = tester.element(find.byType(_TestShellScaffold));
        GoRouter.of(context).go('/about');
        await tester.pumpAndSettle();
        expect(find.text('about-page'), findsOneWidget);

        final handled = await _triggerSystemBack(tester);
        expect(handled, isTrue);
        expect(find.text('home-tab'), findsOneWidget);
        expect(find.text('about-page'), findsNothing);
      },
    );
  });

  group('iOS back navigation (HomeShellScaffold logic)', () {
    late GlobalKey<NavigatorState> shellKey;

    setUp(() {
      shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell-ios-test');
    });

    testWidgets(
      'non-Home tab: back does NOT switch to Home (no interception on iOS)',
      (tester) async {
        final container = await _pumpScaffold(
          tester,
          platform: TargetPlatform.iOS,
          shellKey: shellKey,
        );

        container.read(mainNavigationIndexProvider.notifier).state =
            MainTab.me.index;
        await tester.pump();

        // No PopScope on iOS → framework does not intercept.
        final handled = await _triggerSystemBack(tester);
        expect(handled, isFalse);
        // Tab index unchanged.
        expect(container.read(mainNavigationIndexProvider), MainTab.me.index);
      },
    );

    testWidgets(
      'Home tab: back is not intercepted on iOS',
      (tester) async {
        final container = await _pumpScaffold(
          tester,
          platform: TargetPlatform.iOS,
          shellKey: shellKey,
        );

        expect(container.read(mainNavigationIndexProvider), MainTab.home.index);

        final handled = await _triggerSystemBack(tester);
        expect(handled, isFalse);
      },
    );
  });
}
