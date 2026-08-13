import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/route_guard.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Builds a [GoRouter] whose redirect calls [RouteGuard.redirect] with the
  /// supplied [authState]. Because the onboarding flag now lives on [AuthState]
  /// there is nothing to mock — the guard is fully synchronous.
  GoRouter _buildRouter(AuthState authState, {String initialLocation = '/home'}) {
    return GoRouter(
      initialLocation: initialLocation,
      redirect: (context, state) => RouteGuard.redirect(
        context,
        state,
        authState,
        getPendingRoute: () => null,
        setPendingRoute: (_) {},
      ),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Text('home')),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const Text('onboarding'),
        ),
        GoRoute(path: '/splash', builder: (_, __) => const Text('splash')),
        GoRoute(path: '/login', builder: (_, __) => const Text('login')),
      ],
    );
  }

  testWidgets('stays on /home when onboarding is completed', (tester) async {
    final router = _buildRouter(
      const AuthState(isLoggedIn: true, hasCompletedOnboarding: true),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('redirects to /onboarding when onboarding is not completed', (
    tester,
  ) async {
    final router = _buildRouter(
      const AuthState(isLoggedIn: true, hasCompletedOnboarding: false),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('onboarding'), findsOneWidget);
  });

  testWidgets('does not enforce onboarding when status is null (e.g. offline launch)', (
    tester,
  ) async {
    final router = _buildRouter(
      const AuthState(isLoggedIn: true, hasCompletedOnboarding: null),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // null = status unknown — skip enforcement, stay on /home
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('redirects authenticated user away from /onboarding when completed', (
    tester,
  ) async {
    final router = _buildRouter(
      const AuthState(isLoggedIn: true, hasCompletedOnboarding: true),
      initialLocation: '/onboarding',
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('redirects unauthenticated user from /home to /login', (
    tester,
  ) async {
    final router = _buildRouter(const AuthState(isLoggedIn: false));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('shows /splash while auth is loading', (tester) async {
    final router = _buildRouter(
      const AuthState(isLoggedIn: false, isLoading: true),
      initialLocation: '/splash',
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('splash'), findsOneWidget);
  });
}
