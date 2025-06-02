import 'dart:async';
import 'package:flutter_pecha/features/auth/presentation/login_page.dart';
import 'package:flutter_pecha/features/app/presentation/skeleton_screen.dart';
import 'package:flutter_pecha/features/meditation_of_day/presentation/meditation_of_day_screen.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/presentation/prayer_of_the_day_screen.dart';
import 'package:flutter_pecha/features/splash/presentation/splash_screen.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/term/term.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:flutter_pecha/features/texts/presentation/category_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/library_catalog_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/text_detail_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/text_reader_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/text_toc_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/version_selection/language_selection.dart';
import 'package:flutter_pecha/features/texts/presentation/version_selection/version_selection_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authProvider.notifier).stream,
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      // home page routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const SkeletonScreen(),
      ),
      GoRoute(
        path: '/home/meditation_of_the_day',
        builder: (context, state) => const MeditationOfTheDayScreen(),
      ),
      GoRoute(
        path: '/home/prayer_of_the_day',
        builder: (context, state) => const PrayerOfTheDayScreen(),
      ),
      GoRoute(
        path: '/texts',
        builder: (context, state) => const LibraryCatalogScreen(),
      ),
      GoRoute(
        path: '/texts/category',
        builder: (context, state) {
          final extra = state.extra;
          late Term term;
          if (extra is Term) {
            term = extra;
          } else if (extra is Map<String, dynamic>) {
            term = Term.fromJson(extra);
          } else {
            throw Exception('Invalid extra type for /texts/category');
          }
          return CategoryScreen(term: term);
        },
      ),
      GoRoute(
        path: '/texts/detail',
        builder: (context, state) {
          final extra = state.extra;
          late Term term;
          if (extra is Term) {
            term = extra;
          } else if (extra is Map<String, dynamic>) {
            term = Term.fromJson(extra);
          } else {
            throw Exception('Invalid extra type for /texts/detail');
          }
          return TextDetailScreen(term: term);
        },
      ),
      GoRoute(
        path: '/texts/toc',
        builder: (context, state) {
          final extra = state.extra;
          late Texts text;
          if (extra is Texts) {
            text = extra;
          } else if (extra is Map<String, dynamic>) {
            text = Texts.fromJson(extra);
          } else {
            throw Exception('Invalid extra type for /texts/toc');
          }
          return TextTocScreen(text: text);
        },
      ),
      GoRoute(
        path: '/texts/reader',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null ||
              extra is! Map ||
              !extra.containsKey('skip') ||
              !extra.containsKey('textId')) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return TextReaderScreen(
            textId: extra['textId'] as String,
            section: extra['section'] as Section?,
            version: extra['version'] as Version?,
            skip: extra['skip'] as String,
          );
        },
      ),
      GoRoute(
        path: '/texts/version_selection',
        builder: (context, state) {
          return const VersionSelectionScreen();
        },
      ),
      GoRoute(
        path: '/texts/language_selection',
        builder: (context, state) {
          return const LanguageSelectionScreen();
        },
      ),
    ],
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.isLoggedIn;
      final onSplash = state.fullPath == '/splash';
      final onLogin = state.fullPath == '/login';

      // // 1. If loading, stay on splash screen
      if (isLoading) {
        return '/login';
      }

      // 2. If not loading and on splash, go to login or home
      if (!isLoading && onSplash) {
        return isLoggedIn ? '/home' : '/login';
      }

      // 3. If not logged in and not on login/splash, go to login
      if (!isLoggedIn && !onLogin && !onSplash) {
        return '/login';
      }

      // 4. If logged in and on login, go to home
      if (isLoggedIn && onLogin) {
        return '/home';
      }

      // 5. No redirect needed
      return null;
    },
  );
});

/// Utility for GoRouter to listen to Riverpod StateNotifier
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListener = () => notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListener());
  }
  late final void Function() notifyListener;
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
