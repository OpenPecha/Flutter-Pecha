import 'dart:async';
import 'package:flutter_pecha/features/auth/presentation/login_page.dart';
import 'package:flutter_pecha/features/auth/presentation/profile_page.dart';
import 'package:flutter_pecha/features/app/presentation/skeleton_screen.dart';
import 'package:flutter_pecha/features/creator_info/presentation/creator_info_screen.dart';
import 'package:flutter_pecha/features/home/models/prayer_data.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_text.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/view_illustration.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/youtube_video_player.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/meditation_video.dart';
import 'package:flutter_pecha/features/meditation_of_day/presentation/meditation_of_day_screen.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/plan_details.dart';
import 'package:flutter_pecha/features/plans/presentation/plan_info.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/presentation/prayer_of_the_day_screen.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_pecha/features/texts/presentation/category_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/commentary/commentary_view.dart';
import 'package:flutter_pecha/features/texts/presentation/library_catalog_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_image/choose_image.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_image/create_image.dart';
import 'package:flutter_pecha/features/texts/presentation/text_chapter.dart';
import 'package:flutter_pecha/features/texts/presentation/text_detail_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/text_toc_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/version_selection/language_selection.dart';
import 'package:flutter_pecha/features/texts/presentation/version_selection/version_selection_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'route_config.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
    initialLocation: RouteConfig.home,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authProvider.notifier).stream,
    ),
    routes: [
      GoRoute(
        path: RouteConfig.login,
        builder: (context, state) => const LoginPage(),
      ),
      // home page routes
      GoRoute(
        path: RouteConfig.home,
        builder: (context, state) => const SkeletonScreen(),
      ),
      GoRoute(
        path: RouteConfig.profile,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ProfilePage(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              final fade = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              );
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.0, 0.03),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: animation.drive(offsetTween),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: RouteConfig.creatorInfo,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const CreatorInfoScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              final fade = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              );
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.0, 0.03),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: animation.drive(offsetTween),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/home/video_player',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map &&
              extra.containsKey('videoUrl') &&
              extra.containsKey('title')) {
            return YoutubeVideoPlayer(
              videoUrl: extra['videoUrl'] as String,
              title: extra['title'] as String,
            );
          } else {
            throw Exception('Invalid extra type for /home/video_player');
          }
        },
      ),
      GoRoute(
        path: '/home/view_illustration',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null ||
              extra is! Map ||
              !extra.containsKey('imageUrl') ||
              !extra.containsKey('title')) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return ViewIllustration(
            imageUrl: extra['imageUrl'] as String,
            title: extra['title'] as String,
          );
        },
      ),
      GoRoute(
        path: '/home/verse_text',
        builder: (context, state) {
          final extra = state.extra;
          return VerseText(verse: extra as String);
        },
      ),
      GoRoute(
        path: '/home/meditation_of_the_day',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null ||
              extra is! Map ||
              !extra.containsKey('meditationAudioUrl') ||
              !extra.containsKey('meditationImageUrl')) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return MeditationOfTheDayScreen(
            audioUrl: extra['meditationAudioUrl'] as String,
            imageUrl: extra['meditationImageUrl'] as String,
          );
        },
      ),
      GoRoute(
        path: '/home/meditation_video',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! String) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return MeditationVideo(videoUrl: extra);
        },
      ),
      GoRoute(
        path: '/home/prayer_of_the_day',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null ||
              extra is! Map ||
              !extra.containsKey('prayerAudioUrl') ||
              !extra.containsKey('prayerData')) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return PrayerOfTheDayScreen(
            audioUrl: extra['prayerAudioUrl'] as String,
            prayerData: extra['prayerData'] as List<PrayerData>,
          );
        },
      ),
      GoRoute(
        path: '/texts',
        builder: (context, state) => const LibraryCatalogScreen(),
      ),
      GoRoute(
        path: '/texts/category',
        builder: (context, state) {
          final extra = state.extra;
          late Collections collection;
          if (extra is Collections) {
            collection = extra;
          } else if (extra is Map<String, dynamic>) {
            collection = Collections.fromJson(extra);
          } else {
            throw Exception('Invalid extra type for /texts/category');
          }
          return CategoryScreen(collection: collection);
        },
      ),
      GoRoute(
        path: '/texts/detail',
        builder: (context, state) {
          final extra = state.extra;
          late Collections collection;
          if (extra is Collections) {
            collection = extra;
          } else if (extra is Map<String, dynamic>) {
            collection = Collections.fromJson(extra);
          } else {
            throw Exception('Invalid extra type for /texts/detail');
          }
          return TextDetailScreen(collection: collection);
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
        path: '/texts/chapter',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! Map || !extra.containsKey('textId')) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return TextChapter(
            textId: extra['textId'] as String,
            contentId: extra['contentId'] as String?,
            segmentId: extra['segmentId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/texts/version_selection',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! Map || !extra.containsKey('textId')) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return VersionSelectionScreen(textId: extra['textId'] as String);
        },
      ),
      GoRoute(
        path: '/texts/language_selection',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null ||
              extra is! Map ||
              !extra.containsKey('uniqueLanguages')) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return LanguageSelectionScreen(
            uniqueLanguages: extra['uniqueLanguages'] as List<String>,
          );
        },
      ),
      GoRoute(
        path: '/texts/segment_image/choose_image',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! String) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return ChooseImage(text: extra);
        },
      ),
      GoRoute(
        path: '/texts/segment_image/create_image',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null ||
              extra is! Map ||
              !extra.containsKey('text') ||
              !extra.containsKey('imagePath')) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return CreateImage(
            imagePath: extra['imagePath'] as String,
            text: extra['text'] as String,
          );
        },
      ),
      GoRoute(
        path: '/texts/commentary',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! String) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return CommentaryView(segmentId: extra);
        },
      ),
      // plan tab routes
      GoRoute(
        path: '/plans/info',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! PlansModel) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return PlanInfo(plan: extra);
        },
      ),
      GoRoute(
        path: '/plans/details',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! PlansModel) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return PlanDetails(plan: extra);
        },
      ),
      GoRoute(
        path: NotificationSettingsScreen.routeName,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.isLoggedIn;
      final currentPath = state.fullPath ?? RouteConfig.home;

      // 1. While auth is loading, allow navigation to proceed
      // The native splash will remain visible until Flutter is ready
      if (isLoading) {
        return RouteConfig.login;
      }

      // 2. Authenticated user on login page should go to home
      if (isLoggedIn && currentPath == RouteConfig.login) {
        return RouteConfig.home;
      }

      // 3. Unauthenticated user trying to access protected route
      if (!isLoggedIn && RouteConfig.isProtectedRoute(currentPath)) {
        return RouteConfig.login;
      }

      // 4. No redirect needed
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
