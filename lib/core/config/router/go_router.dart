import 'dart:async';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/login_page.dart';
import 'package:flutter_pecha/features/auth/presentation/profile_page.dart';
import 'package:flutter_pecha/features/app/presentation/skeleton_screen.dart';
import 'package:flutter_pecha/features/creator_info/presentation/creator_info_screen.dart';
import 'package:flutter_pecha/features/onboarding/presentation/onboarding_wrapper.dart';
import 'package:flutter_pecha/features/home/models/prayer_data.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/view_illustration.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/youtube_video_player.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/meditation_video.dart';
import 'package:flutter_pecha/features/meditation_of_day/presentation/meditation_of_day_screen.dart';
import 'package:flutter_pecha/features/plans/models/author/author_dto_model.dart';
import 'package:flutter_pecha/features/plans/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/story_view/presentation/screens/plan_story_presenter.dart';
import 'package:flutter_pecha/features/story_view/presentation/screens/story_feature.dart';
import 'package:flutter_pecha/features/story_view/presentation/screens/story_presenter.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/plan_details.dart';
import 'package:flutter_pecha/features/plans/presentation/plan_info.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/presentation/prayer_of_the_day_screen.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/image_story.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/text_story.dart';
import 'package:flutter_pecha/features/story_view/presentation/widgets/video_story.dart';
import 'package:flutter_pecha/features/story_view/utils/helper_functions.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_pecha/features/texts/presentation/category_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/commentary/commentary_view.dart';
import 'package:flutter_pecha/features/texts/presentation/screens/collections/collections_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_image/choose_image.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_image/create_image.dart';
import 'package:flutter_pecha/features/texts/presentation/screens/chapters/chapters_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/screens/works/works_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/screens/texts/texts_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/version_selection/language_selection.dart';
import 'package:flutter_pecha/features/texts/presentation/version_selection/version_selection_screen.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/screens/recitation_detail_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:story_view/story_view.dart';
import 'package:flutter_story_presenter/flutter_story_presenter.dart' as fsp;
import 'route_config.dart';
import 'package:flutter_pecha/features/onboarding/data/providers/onboarding_datasource_providers.dart';

final _logger = AppLogger('GoRouter');

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final onboardingRepo = ref.watch(onboardingRepositoryProvider);

  return GoRouter(
    initialLocation: RouteConfig.home,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authProvider.notifier).stream,
    ),
    routes: [
      GoRoute(
        path: RouteConfig.onboarding,
        builder: (context, state) => const OnboardingWrapper(),
      ),
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
        path: '/home/stories',
        builder: (context, state) {
          final extra = state.extra;
          List<UserSubtasksDto> subtasks;
          dynamic author;
          if (extra is Map<String, dynamic>) {
            final subtasksValue = extra['subtasks'];
            if (subtasksValue is! List<UserSubtasksDto>) {
              return const Scaffold(
                body: Center(child: Text('Missing required parameters')),
              );
            }
            subtasks = subtasksValue;
            author = extra['author'];
          } else if (extra is List<UserSubtasksDto>) {
            subtasks = extra;
            author = null;
          } else {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }

          // Validate that we have at least one valid subtask
          if (subtasks.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('No content available')),
            );
          }

          return StoryFeature(
            author: author,
            storyItemsBuilder: (controller) {
              final List<StoryItem> storyItems = [];
              const durationForText = Duration(seconds: 15);
              const durationForVideo = Duration(minutes: 5);
              const durationForImage = Duration(seconds: 15);
              for (final subtask in subtasks) {
                if (subtask.content.isEmpty || subtask.contentType.isEmpty) {
                  continue;
                }
                switch (subtask.contentType) {
                  case "TEXT":
                    storyItems.add(
                      StoryItem(
                        TextStory(
                          text: subtask.content,
                          roundedTop: true,
                          roundedBottom: true,
                        ),
                        duration: durationForText,
                      ),
                    );
                    break;
                  case "VIDEO":
                    storyItems.add(
                      StoryItem(
                        VideoStory(
                          videoUrl: subtask.content,
                          controller: controller,
                        ),
                        duration: durationForVideo,
                      ),
                    );
                    break;
                  case "IMAGE":
                    storyItems.add(
                      StoryItem(
                        ImageStory(
                          imageUrl: subtask.content,
                          controller: controller,
                          imageFit: BoxFit.contain,
                          roundedTop: true,
                          roundedBottom: true,
                        ),
                        duration: durationForImage,
                      ),
                    );
                    break;
                }
              }

              // If no valid story items were created, add a placeholder
              if (storyItems.isEmpty) {
                storyItems.add(
                  StoryItem(
                    TextStory(
                      text: 'No content available',
                      roundedTop: true,
                      roundedBottom: true,
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }

              return storyItems;
            },
          );
        },
      ),
      GoRoute(
        path: '/home/stories-presenter',
        builder: (context, state) {
          final extra = state.extra;
          List<UserSubtasksDto> subtasks;
          dynamic author;
          Map<String, dynamic>? nextCard;
          if (extra is Map<String, dynamic>) {
            final subtasksValue = extra['subtasks'];
            if (subtasksValue is! List<UserSubtasksDto>) {
              return const Scaffold(
                body: Center(child: Text('Missing required parameters')),
              );
            }
            subtasks = subtasksValue;
            author = extra['author'];
            nextCard = extra['nextCard'] as Map<String, dynamic>?;
          } else if (extra is List<UserSubtasksDto>) {
            subtasks = extra;
            author = null;
            nextCard = null;
          } else {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }

          // Validate that we have at least one valid subtask
          if (subtasks.isEmpty && nextCard == null) {
            return const Scaffold(
              body: Center(child: Text('No content available')),
            );
          }

          return StoryPresenter(
            author: author,
            subtasks: subtasks,
            storyItemsBuilder: (controller) {
              final items = createFlutterStoryItems(
                subtasks,
                controller,
                nextCard,
                null,
              );
              // Ensure we have at least one item
              if (items.isEmpty) {
                return [
                  fsp.StoryItem(
                    storyItemType: fsp.StoryItemType.custom,
                    duration: const Duration(seconds: 3),
                    customWidget: (controller, audioPlayer) {
                      return const Center(
                        child: Text(
                          'No content available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      );
                    },
                  ),
                ];
              }
              return items;
            },
          );
        },
      ),
      GoRoute(
        path: '/home/plan-stories-presenter',
        builder: (context, state) {
          final extra = state.extra;
          List<UserSubtasksDto> subtasks;
          Map<String, dynamic>? nextCard;
          String? planId;
          int? dayNumber;
          String? language;
          if (extra is Map<String, dynamic>) {
            final subtasksValue = extra['subtasks'];
            if (subtasksValue is! List<UserSubtasksDto>) {
              return const Scaffold(
                body: Center(child: Text('Missing required parameters')),
              );
            }
            subtasks = subtasksValue;
            nextCard = extra['nextCard'] as Map<String, dynamic>?;
            planId = extra['planId'] as String?;
            dayNumber = extra['dayNumber'] as int?;
            language = extra['language'] as String?;
          } else if (extra is List<UserSubtasksDto>) {
            subtasks = extra;
            nextCard = null;
            planId = null;
            dayNumber = null;
            language = null;
          } else {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }

          // Validate that we have at least one valid subtask
          if (subtasks.isEmpty && nextCard == null) {
            return const Scaffold(
              body: Center(child: Text('No content available')),
            );
          }

          return PlanStoryPresenter(
            subtasks: subtasks,
            planId: planId,
            dayNumber: dayNumber,
            storyItemsBuilder: (controller) {
              final items = createFlutterStoryItems(
                subtasks,
                controller,
                nextCard,
                language,
              );
              // Ensure we have at least one item
              if (items.isEmpty) {
                return [
                  fsp.StoryItem(
                    storyItemType: fsp.StoryItemType.custom,
                    duration: const Duration(seconds: 3),
                    customWidget: (controller, audioPlayer) {
                      return const Center(
                        child: Text(
                          'No content available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      );
                    },
                  ),
                ];
              }
              return items;
            },
          );
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
            audioHeaders: extra['audioHeaders'] as Map<String, String>?,
          );
        },
      ),
      GoRoute(
        path: '/texts/collections',
        builder: (context, state) => const CollectionsScreen(),
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
        path: '/texts/works',
        builder: (context, state) {
          final extra = state.extra;
          late Collections collection;
          int? colorIndex;

          if (extra is Collections) {
            collection = extra;
          } else if (extra is Map<String, dynamic>) {
            if (extra.containsKey('collection')) {
              // New format with collection and colorIndex
              collection = extra['collection'] as Collections;
              colorIndex = extra['colorIndex'] as int?;
            } else {
              // Legacy format - try to parse as Collections JSON
              collection = Collections.fromJson(extra);
            }
          } else {
            throw Exception('Invalid extra type for /texts/works');
          }
          return WorksScreen(collection: collection, colorIndex: colorIndex);
        },
      ),
      GoRoute(
        path: '/texts/texts',
        builder: (context, state) {
          final extra = state.extra;
          late Texts text;
          int? colorIndex;

          if (extra is Texts) {
            text = extra;
          } else if (extra is Map<String, dynamic>) {
            if (extra.containsKey('text')) {
              // New format with text and colorIndex
              text = extra['text'] as Texts;
              colorIndex = extra['colorIndex'] as int?;
            } else {
              // Legacy format - try to parse as Texts JSON
              text = Texts.fromJson(extra);
            }
          } else {
            throw Exception('Invalid extra type for /texts/texts');
          }
          return TextsScreen(text: text, colorIndex: colorIndex);
        },
      ),
      GoRoute(
        path: '/texts/chapters',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! Map || !extra.containsKey('textId')) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return ChaptersScreen(
            textId: extra['textId'] as String,
            contentId: extra['contentId'] as String?,
            segmentId: extra['segmentId'] as String?,
            colorIndex: extra['colorIndex'] as int?,
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
      // all plan tab routes
      GoRoute(
        path: '/plans/info',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null ||
              extra is! Map ||
              !extra.containsKey('plan') ||
              !extra.containsKey('author')) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return PlanInfo(
            plan: extra['plan'] as PlansModel,
            author: extra['author'] as AuthorDtoModel,
          );
        },
      ),
      GoRoute(
        path: '/plans/details',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null ||
              extra is! Map ||
              !extra.containsKey('plan') ||
              !extra.containsKey('selectedDay') ||
              !extra.containsKey('startDate')) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }
          return PlanDetails(
            plan: extra['plan'] as UserPlansModel,
            selectedDay: extra['selectedDay'] as int,
            startDate: extra['startDate'] as DateTime,
          );
        },
      ),
      GoRoute(
        path: NotificationSettingsScreen.routeName,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      // recitation tab routes
      GoRoute(
        path: '/recitations/detail',
        builder: (context, state) {
          final extra = state.extra;

          // Support both single recitation and recitation with list
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          }

          if (extra is RecitationModel) {
            // Single recitation mode (from search, browse tab, etc.)
            return RecitationDetailScreen(recitation: extra);
          } else if (extra is Map<String, dynamic>) {
            // Navigation with list mode (from My Recitations tab)
            final recitation = extra['recitation'] as RecitationModel?;
            final allRecitations =
                extra['allRecitations'] as List<RecitationModel>?;
            final currentIndex = extra['currentIndex'] as int?;

            if (recitation == null) {
              return const Scaffold(
                body: Center(child: Text('Missing required parameters')),
              );
            }

            return RecitationDetailScreen(
              recitation: recitation,
              allRecitations: allRecitations,
              currentIndex: currentIndex,
            );
          }

          return const Scaffold(
            body: Center(child: Text('Invalid parameters')),
          );
        },
      ),
    ],
    redirect: (context, state) async {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.isLoggedIn;
      final isGuest = authState.isGuest;
      final currentPath = state.fullPath ?? RouteConfig.home;

      // 1. While auth is loading, redirect to login
      if (isLoading) {
        _logger.debug('Auth is loading, redirecting to login');
        return RouteConfig.login;
      }

      // 2. Check onboarding for authenticated non-guest users
      if (isLoggedIn && !isGuest) {
        final hasCompletedOnboarding =
            await onboardingRepo.hasCompletedOnboarding();

        // Redirect to onboarding if not completed (unless already there or on login)
        if (!hasCompletedOnboarding &&
            currentPath != RouteConfig.onboarding &&
            currentPath != RouteConfig.login) {
          _logger.debug('Redirecting to onboarding');
          return RouteConfig.onboarding;
        }

        // If completed and on onboarding page, redirect to home
        if (hasCompletedOnboarding && currentPath == RouteConfig.onboarding) {
          _logger.debug('Onboarding already completed, redirecting to home');
          return RouteConfig.home;
        }
      }

      // 3. Guest users skip onboarding - allow them to navigate freely
      if (isGuest && currentPath == RouteConfig.onboarding) {
        _logger.debug('Guest user, skipping onboarding');
        return RouteConfig.home;
      }

      // 4. Authenticated user on login page should go to home or onboarding
      if (isLoggedIn && currentPath == RouteConfig.login) {
        // Check if they need onboarding first
        if (!isGuest) {
          final hasCompletedOnboarding =
              await onboardingRepo.hasCompletedOnboarding();
          if (!hasCompletedOnboarding) {
            _logger.debug('New authenticated user, redirecting to onboarding');
            return RouteConfig.onboarding;
          }
        }
        _logger.debug('Authenticated user, redirecting to home');
        return RouteConfig.home;
      }

      // 5. Unauthenticated user trying to access protected route
      if (!isLoggedIn && RouteConfig.isProtectedRoute(currentPath)) {
        _logger.debug('Protected route, redirecting to login');
        return RouteConfig.login;
      }

      // 6. No redirect needed
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
