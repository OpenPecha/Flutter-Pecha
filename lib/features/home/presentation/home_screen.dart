import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/services/service_providers.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/home/data/providers/featured_day_provider.dart';
import 'package:flutter_pecha/features/home/presentation/featured_content_factory.dart';
import 'package:flutter_pecha/features/home/presentation/home_screen_constants.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('HomeScreen');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _dayCheckTimer;
  DateTime? _lastFetchedDate;
  bool _hasRequestedPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastFetchedDate = DateTime.now();
    _startDayCheckTimer();

    // Request notification permissions when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermissionsIfNeeded();
    });
  }

  Future<void> _requestNotificationPermissionsIfNeeded() async {
    if (_hasRequestedPermissions) return;
    _hasRequestedPermissions = true;

    final notificationService = ref.read(notificationServiceProvider);
    if (notificationService == null) {
      _log.warning(
        'NotificationService not initialized, skipping permission request',
      );
      return;
    }

    try {
      // Check if permissions are already granted
      final alreadyEnabled =
          await notificationService.areNotificationsEnabled();
      if (!alreadyEnabled) {
        _log.info('Requesting notification permissions...');
        final granted = await notificationService.requestPermission();
        if (granted) {
          _log.info('Notification permissions granted');
        } else {
          _log.info('Notification permissions denied');
        }
      }
    } catch (e) {
      _log.warning('Error requesting notification permissions: $e');
    }
  }

  void _startDayCheckTimer() {
    _dayCheckTimer = Timer.periodic(HomeScreenConstants.dayCheckInterval, (
      timer,
    ) {
      _checkAndUpdateDay();
    });
  }

  void _checkAndUpdateDay() {
    final today = DateTime.now();
    final lastFetched = _lastFetchedDate;

    // Check if day has changed (compare year, month, day)
    if (lastFetched == null ||
        today.year != lastFetched.year ||
        today.month != lastFetched.month ||
        today.day != lastFetched.day) {
      _lastFetchedDate = today;
      _refreshFeaturedDay();
    }
  }

  void _refreshFeaturedDay() {
    // Invalidate the provider to force refresh
    ref.invalidate(featuredDayFutureProvider);
  }

  /// Manual refetch/retry method that can be called from UI
  void refetchFeaturedDay() {
    // Refresh the provider to immediately fetch fresh data
    // ignore: unused_result
    ref.refresh(featuredDayFutureProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndUpdateDay();
    }
  }

  @override
  void dispose() {
    _dayCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(authState, localizations),
                _buildBody(context, localizations),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build the top bar
  Widget _buildTopBar(AuthState authState, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HomeScreenConstants.topBarHorizontalPadding,
        vertical: HomeScreenConstants.topBarVerticalPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            localizations.home_today,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: HomeScreenConstants.titleFontSize,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed:
                    () => context.push(NotificationSettingsScreen.routeName),
                icon: const Icon(
                  Icons.notifications_none,
                  size: HomeScreenConstants.notificationIconSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations localizations) {
    final featuredDayAsync = ref.watch(featuredDayFutureProvider);
    final language = ref.watch(localeProvider).languageCode;
    final fontSize = language == 'bo' ? 22.0 : 18.0;
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: HomeScreenConstants.bodyHorizontalPadding,
          vertical: HomeScreenConstants.bodyVerticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            featuredDayAsync.when(
              data: (planItems) {
                if (planItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        HomeScreenConstants.emptyStatePadding,
                      ),
                      child: Text(
                        localizations.no_feature_content,
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    ...planItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final planItem = entry.value;

                      return FeaturedContentFactory.createCard(
                        context: context,
                        index: index,
                        planItem: planItem,
                        allPlanItems: planItems,
                        localizations: localizations,
                      );
                    }),
                    const SizedBox(height: 10),
                  ],
                );
              },
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(
                        HomeScreenConstants.emptyStatePadding,
                      ),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (error, stackTrace) => ErrorStateWidget(
                    error: error,
                    onRetry: refetchFeaturedDay,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
