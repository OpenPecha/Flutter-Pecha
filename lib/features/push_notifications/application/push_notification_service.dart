import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:uuid/uuid.dart';

/// Background / terminated-state FCM handler. Must be a top-level function with
/// `@pragma` so it survives AOT and runs in its own isolate. Notification
/// messages are displayed by the OS automatically in this state, so this only
/// re-initialises Firebase and logs.
@pragma('vm:entry-point')
Future<void> pushNotificationBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  AppLogger('PushBackground').info('Background message: ${message.messageId}');
}

/// Drives the push-notification lifecycle:
///   1. Requests permission + creates the Android channel.
///   2. Captures the FCM token (install) and listens for rotations (refresh).
///   3. Registers the token with the backend once a user signs in.
///   4. Shows foreground messages and handles notification taps.
///
/// Depends only on [PushMessagingRepository], so Firebase stays out of this
/// layer and the service is unit-testable.
class PushNotificationService {
  PushNotificationService({
    required PushMessagingRepository repository,
    required LocalStorageService storage,
  }) : _repository = repository,
       _storage = storage;

  final PushMessagingRepository _repository;
  final LocalStorageService _storage;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _logger = AppLogger('PushNotificationService');
  final _subscriptions = <StreamSubscription<dynamic>>[];

  /// Invoked when a notification is opened from the background or terminated
  /// state. Set by the bootstrap layer to route via [PushMessageNavigator].
  /// Foreground taps reach the navigator separately (through the shared
  /// flutter_local_notifications callback), so they don't pass through here.
  void Function(PushMessage message)? onOpenMessage;

  /// Asked before a foreground message is shown as a heads-up. Return true to
  /// drop the banner (the payload is still handled by whoever owns the
  /// screen, e.g. the open chat room receiving it live). Set by the bootstrap
  /// layer, which knows which screen is on top.
  bool Function(PushMessage message)? shouldSuppressForeground;

  String? _token;
  bool _loggedIn = false;

  /// Mirrors the app's master notification switch. While false the device is
  /// kept unregistered on the backend so no server push of any kind reaches
  /// it; the OS shows background pushes before the app can filter them, so
  /// this has to be enforced server-side. Fed by [setMasterEnabled].
  bool _masterEnabled = true;
  bool _initialized = false;
  Future<void>? _initializing;
  int _initRetryCount = 0;
  Timer? _initRetryTimer;

  /// Max automatic retries after a failed init (bootstrap + scheduled backoff).
  static const maxInitRetries = 3;

  static const _initRetryBaseDelay = Duration(seconds: 5);

  /// One-time setup. Concurrent calls share the in-flight attempt, and calls
  /// after a successful run are ignored. A failed attempt does NOT latch — it
  /// tears down any partial wiring, schedules a backoff retry, and leaves the
  /// service ready for resume-triggered retries too.
  Future<void> initialize() {
    if (_initialized) return Future.value();
    return _initializing ??= _runInitialize();
  }

  Future<void> _runInitialize() async {
    try {
      await _createAndroidChannel();
      final granted = await _repository.requestPermission();
      _logger.info('Notification permission granted: $granted');

      _subscriptions
        ..add(_repository.onForegroundMessage.listen(_showNotification))
        ..add(_repository.onMessageOpenedApp.listen(_onNotificationTapped))
        ..add(_repository.onTokenRefresh.listen(_onToken));

      // Terminated-state launch via a notification tap.
      final launchMessage = await _repository.getInitialMessage();
      if (launchMessage != null) _onNotificationTapped(launchMessage);

      // Token for this install.
      final token = await _repository.getToken();
      if (token != null) await _onToken(token);

      // Only latch once the full setup has succeeded.
      _initialized = true;
      _initRetryCount = 0;
      _initRetryTimer?.cancel();
      _initRetryTimer = null;
    } catch (e, st) {
      _logger.warning('Push initialization failed: $e', e, st);
      // Drop any listeners added before the failure so a retry starts clean
      // and we don't double-subscribe.
      for (final sub in _subscriptions) {
        unawaited(sub.cancel());
      }
      _subscriptions.clear();
      _scheduleInitRetry();
    } finally {
      _initializing = null;
    }
  }

  /// Backoff retry so a transient cold-start failure doesn't require backgrounding.
  void _scheduleInitRetry() {
    if (_initialized || _initRetryCount >= maxInitRetries) return;

    _initRetryCount++;
    final delay = _initRetryBaseDelay * _initRetryCount;
    _initRetryTimer?.cancel();
    _initRetryTimer = Timer(delay, () {
      if (_initialized) return;
      _logger.info(
        'Retrying push initialization (attempt $_initRetryCount/$maxInitRetries)',
      );
      unawaited(initialize());
    });
  }

  /// Feeds in the latest auth snapshot. Registers the token with the backend on
  /// sign-in (the backend keys the device on the JWT, so no profile data is
  /// needed). Guests are treated as signed out for push targeting.
  void onAuthChanged({required bool loggedIn}) {
    final signedIn = loggedIn && !_loggedIn;
    _loggedIn = loggedIn;
    if (!signedIn) return;
    if (_masterEnabled) {
      unawaited(_registerToken());
    } else {
      // Master was switched off while signed out (or before auth resolved on
      // launch), so the registration left from an earlier session must go now
      // that the JWT is available.
      unawaited(unregisterDevice());
    }
  }

  /// Re-sends the device registration so the backend picks up the latest
  /// notification-category preferences. Called when the user flips a
  /// notification toggle. No-op until a token is captured, the user is
  /// signed in and the master switch is on (the guards live in
  /// [_registerToken]).
  void refreshRegistration() => unawaited(_registerToken());

  /// Applies the master notification switch. OFF unregisters the device from
  /// the backend so every server push stops; ON registers it again. Safe to
  /// call with the same value repeatedly.
  void setMasterEnabled(bool enabled) {
    if (_masterEnabled == enabled) return;
    _masterEnabled = enabled;
    if (enabled) {
      unawaited(_registerToken());
    } else {
      unawaited(unregisterDevice());
    }
  }

  /// Removes this device's registration from the backend using the id kept
  /// from the last successful register call. Nothing to do when the device
  /// was never registered or the user is signed out (the endpoint needs the
  /// user's JWT). The stored id is kept on failure so a later attempt can
  /// still find the registration.
  Future<void> unregisterDevice() async {
    final serverId = await _storage.get<String>(StorageKeys.pushDeviceServerId);
    if (serverId == null || serverId.isEmpty) return;
    if (!_loggedIn) return;

    final result = await _repository.unregisterDeviceToken(serverId);
    await result.fold(
      (failure) async =>
          _logger.warning('Device unregister failed: ${failure.message}'),
      (_) async {
        await _storage.remove(StorageKeys.pushDeviceServerId);
        _logger.info('Device unregistered');
      },
    );
  }

  Future<void> _onToken(String token) async {
    if (token == _token) return;
    _token = token;
    await _storage.set(StorageKeys.fcmToken, token);
    // Full token logged at debug level only (stripped from release builds) so
    // you can copy it into the Firebase console to send a test push.
    _logger.debug('FCM token: $token');
    await _registerToken();
  }

  Future<void> _registerToken() async {
    final token = _token;
    if (token == null || !_loggedIn) return;
    if (!_masterEnabled) {
      _logger.info('Skipping token registration: master switch is off');
      return;
    }
    final deviceId = await _deviceId();
    final result = await _repository.registerDeviceToken(
      token,
      deviceId: deviceId,
      preferences: await _readPreferences(),
    );
    await result.fold(
      (failure) async =>
          _logger.warning('Token registration failed: ${failure.message}'),
      (serverId) async {
        if (serverId != null) {
          await _storage.set(StorageKeys.pushDeviceServerId, serverId);
        }
        _logger.info('Token registered');
      },
    );
  }

  /// Reads the only notification preference that FCM cares about: whether
  /// plan/series pushes are enabled — the sole category delivered via push.
  ///
  /// It is the AND of the master switch and the "routine" toggle: master is the
  /// global kill-switch, so master OFF disables plan/series push regardless of
  /// the routine toggle. Recitation, mala and timer are local-only (handled
  /// on-device) and never go to the backend. Both flags default to `true` (the
  /// settings-screen default) when never set.
  ///
  /// This must be gated server-side: for background / terminated notification
  /// messages the OS displays the push before the app runs, so a local check
  /// can't suppress them — only the backend can.
  Future<Map<String, bool>> _readPreferences() async {
    Future<bool> read(String key) async =>
        (await _storage.get<bool>(key)) ?? true;
    final masterOn = await read(StorageKeys.notificationMasterEnabled);
    final routineOn = await read(StorageKeys.notificationRoutineEnabled);
    return {'routine': masterOn && routineOn};
  }

  /// Returns the stable per-install device id, generating and persisting one on
  /// first use. Lets backend token refreshes update the same record.
  Future<String> _deviceId() async {
    final existing = await _storage.get<String>(StorageKeys.pushDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _storage.set(StorageKeys.pushDeviceId, id);
    return id;
  }

  Future<void> _showNotification(PushMessage message) async {
    if (!message.hasNotification) return;
    if (shouldSuppressForeground?.call(message) ?? false) {
      _logger.info('Foreground message suppressed: ${message.title}');
      return;
    }
    _logger.info('Foreground message: ${message.title}');
    await _localNotifications.show(
      // Time-based id kept within the 32-bit range Android requires.
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      message.title,
      message.body,
      NotificationChannels.pushDefaultDetails,
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(PushMessage message) {
    _logger.info('Notification opened: ${message.title} data=${message.data}');
    onOpenMessage?.call(message);
  }

  Future<void> _createAndroidChannel() async {
    // Resolver returns null off-Android, so this is a no-op on iOS/macOS.
    final android =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await android?.createNotificationChannel(
      NotificationChannels.pushDefaultChannel,
    );
  }

  void dispose() {
    _initRetryTimer?.cancel();
    _initRetryTimer = null;
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
  }
}
