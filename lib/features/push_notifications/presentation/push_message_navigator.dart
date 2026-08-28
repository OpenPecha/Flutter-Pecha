import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_nav.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// FCM `session_type` values carried in the push `data` payload.
/// See the "Push Notification Format" doc for the full contract.
class PushSessionType {
  PushSessionType._();

  static const String plan = 'PLAN';
  static const String series = 'SERIES';
  static const String recitation = 'RECITATION';
  static const String recitationCollection = 'RECITATION_COLLECTION';
  static const String accumulation = 'ACCUMULATION';
  static const String timer = 'TIMER';
  static const String verseOfDay = 'VERSE_OF_DAY';
  static const String verse = 'VERSE';
  static const String quote = 'QUOTE';
  static const String dailyVerse = 'DAILY_VERSE';
  static const String verseOfTheDay = 'VERSE_OF_THE_DAY';

  static bool isVerseOfDay(String sessionType) =>
      sessionType == verseOfDay ||
      sessionType == verse ||
      sessionType == quote ||
      sessionType == dailyVerse ||
      sessionType == verseOfTheDay;
}

/// Where a push-notification tap should land.
enum PushTapTarget { home, practice, practiceMyPractices, seriesDetail, timers }

/// Result of mapping an FCM data payload to a navigation target.
class PushTapResolution {
  const PushTapResolution(this.target, {this.sourceId});

  final PushTapTarget target;
  final String? sourceId;
}

/// Maps an FCM data map to a [PushTapResolution] without touching the router.
///
/// Isolated so routing can be unit-tested. Verse-of-day and unknown/empty
/// payloads land on Home (the verse card lives there). Practice is reserved
/// for recitation / accumulation until those have dedicated screens.
PushTapResolution resolvePushTap(Map<String, dynamic> data) {
  final sessionType = _sessionTypeOf(data);
  final sourceId = (data['source_id'] as String?)?.trim() ?? '';

  switch (sessionType) {
    case PushSessionType.plan when sourceId.isNotEmpty:
      return PushTapResolution(
        PushTapTarget.practiceMyPractices,
        sourceId: sourceId,
      );
    case PushSessionType.series when sourceId.isNotEmpty:
      return PushTapResolution(PushTapTarget.seriesDetail, sourceId: sourceId);
    case PushSessionType.timer:
      return const PushTapResolution(PushTapTarget.timers);
    case PushSessionType.recitation:
    case PushSessionType.recitationCollection:
    case PushSessionType.accumulation:
      return const PushTapResolution(PushTapTarget.practice);
    default:
      return const PushTapResolution(PushTapTarget.home);
  }
}

String _sessionTypeOf(Map<String, dynamic> data) {
  final fromSession = (data['session_type'] as String?)?.trim();
  if (fromSession != null && fromSession.isNotEmpty) {
    return fromSession.toUpperCase();
  }
  final fromType = (data['type'] as String?)?.trim();
  return fromType?.toUpperCase() ?? '';
}

/// Single entry point for navigating after a push notification is opened.
///
/// Routing must behave the same no matter how the notification was tapped:
///   • foreground — tap on the locally shown heads-up (arrives via the shared
///     `flutter_local_notifications` callback as a decoded data map)
///   • background — `FirebaseMessaging.onMessageOpenedApp`
///   • terminated — `FirebaseMessaging.getInitialMessage`
///
/// Funnelling all three through this class keeps navigation consistent. The
/// actual navigation is deferred to the next frame so it is safe to call during
/// cold start, before the router and widget tree are ready.
class PushMessageNavigator {
  PushMessageNavigator(this._ref);

  final Ref _ref;

  /// Routes a domain [PushMessage] — used for background / terminated taps.
  void handle(PushMessage message) => _schedule(message.data);

  /// Routes a raw FCM data map — used for foreground taps, which reach us via
  /// the shared local-notifications callback as a decoded JSON payload.
  void handleData(Map<String, dynamic> data) => _schedule(data);

  void _schedule(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _route(data));
  }

  void _route(Map<String, dynamic> data) {
    final resolution = resolvePushTap(data);
    final router = _ref.read(appRouterProvider);
    final sourceId = resolution.sourceId ?? '';

    switch (resolution.target) {
      case PushTapTarget.practiceMyPractices:
        // For PLAN pushes the backend sends `source_id` = the enrolled plan id,
        // so it maps straight onto NotificationNav.planId (same field local
        // routine notifications use). RoutineFilledState then resolves the plan
        // + current day and pushes /practice/details. That widget only mounts
        // on the My Practices screen (the Practice *tab* shows the explore
        // screen, which doesn't consume the pending nav), so go there after
        // seeding it.
        _ref.read(pendingNotificationNavProvider.notifier).state =
            NotificationNav(
              itemId: sourceId,
              itemType: RoutineItemType.plan.name,
              planId: sourceId,
            );
        _ref.read(mainNavigationIndexProvider.notifier).state =
            MainTab.practice.index;
        router.go(AppRoutes.home);
        router.push(AppRoutes.practiceMyPractices);

      case PushTapTarget.seriesDetail:
        router.go(AppRoutes.home);
        router.push('/home/series/$sourceId');

      case PushTapTarget.timers:
        router.go(AppRoutes.home);
        router.push('/home/timers');

      case PushTapTarget.practice:
        _openPracticeTab(router);

      case PushTapTarget.home:
        _openHomeTab(router);
    }
  }

  void _openPracticeTab(GoRouter router) {
    _ref.read(mainNavigationIndexProvider.notifier).state =
        MainTab.practice.index;
    router.go(AppRoutes.home);
  }

  void _openHomeTab(GoRouter router) {
    _ref.read(mainNavigationIndexProvider.notifier).state = MainTab.home.index;
    router.go(AppRoutes.home);
  }
}

/// App-lifetime provider — the navigator only reads other providers on demand.
final pushMessageNavigatorProvider = Provider<PushMessageNavigator>(
  (ref) => PushMessageNavigator(ref),
);
