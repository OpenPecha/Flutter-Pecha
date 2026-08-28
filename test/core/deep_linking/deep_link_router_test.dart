import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Stub router mirroring the app's `/home` -> group -> group-accumulator
/// route shape, so back-stack behavior can be asserted without the real app.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const Text('home'),
        routes: [
          GoRoute(
            path: 'group/:groupId',
            builder: (_, state) =>
                Text('group:${state.pathParameters['groupId']}'),
          ),
          GoRoute(
            path: 'group-accumulator/:accumulatorId',
            builder: (_, state) => Text(
              'accumulator:${state.pathParameters['accumulatorId']}',
            ),
          ),
          GoRoute(
            path: 'poems',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final poemId =
                  extra?['initialPoemId'] as String? ??
                  state.uri.queryParameters['poemId'];
              return Text('poems:${poemId ?? ''}');
            },
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('DeepLinkRouter group accumulator links', () {
    testWidgets(
      'pushes group page beneath accumulator so back unwinds '
      'accumulator -> group -> root, and selects the Connect tab',
      (tester) async {
        final router = _buildTestRouter();
        int? selectedTab;
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));

        final routed = DeepLinkRouter.route(
          Uri.parse(
            'https://webuddhist.com/open/group-accumulator/acc-1?group=grp-1',
          ),
          router,
          source: 'test',
          baseLocation: '/home',
          tabSetter: (index) => selectedTab = index,
        );
        await tester.pumpAndSettle();

        expect(routed, isTrue);
        expect(find.text('accumulator:acc-1'), findsOneWidget);
        // MainTab.connect.index == 2
        expect(selectedTab, 2);

        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('group:grp-1'), findsOneWidget);

        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('home'), findsOneWidget);
      },
    );

    testWidgets(
      'opens accumulator directly on root when the group param is missing',
      (tester) async {
        final router = _buildTestRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));

        final routed = DeepLinkRouter.route(
          Uri.parse('https://webuddhist.com/open/group-accumulator/acc-2'),
          router,
          source: 'test',
          baseLocation: '/home',
        );
        await tester.pumpAndSettle();

        expect(routed, isTrue);
        expect(find.text('accumulator:acc-2'), findsOneWidget);

        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('home'), findsOneWidget);
      },
    );

    testWidgets('existing group link still opens the group page', (
      tester,
    ) async {
      final router = _buildTestRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      final routed = DeepLinkRouter.route(
        Uri.parse('https://webuddhist.com/open/group/grp-9'),
        router,
        source: 'test',
        baseLocation: '/home',
      );
      await tester.pumpAndSettle();

      expect(routed, isTrue);
      expect(find.text('group:grp-9'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('poem link opens poems viewer on the shared poem', (
      tester,
    ) async {
      final router = _buildTestRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      final routed = DeepLinkRouter.route(
        Uri.parse('https://webuddhist.com/open/poem/poem-7'),
        router,
        source: 'test',
        baseLocation: '/home',
      );
      await tester.pumpAndSettle();

      expect(routed, isTrue);
      expect(find.text('poems:poem-7'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });
  });
}
