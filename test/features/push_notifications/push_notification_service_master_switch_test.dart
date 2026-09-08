import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/push_notifications/application/push_notification_service.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeRepository extends Fake implements PushMessagingRepository {
  final tokenRefresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();

  String? token = 'tok-1';
  String serverIdToReturn = 'dev-1';
  Failure? registerFailure;
  Failure? unregisterFailure;
  final List<String> registered = [];
  final List<String> unregistered = [];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => tokenRefresh.stream;

  @override
  Stream<PushMessage> get onForegroundMessage => foreground.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp => opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => null;

  @override
  Future<Either<Failure, String?>> registerDeviceToken(
    String token, {
    String? deviceId,
    Map<String, bool>? preferences,
  }) async {
    registered.add(token);
    final failure = registerFailure;
    if (failure != null) return Left(failure);
    return Right(serverIdToReturn);
  }

  @override
  Future<Either<Failure, Unit>> unregisterDeviceToken(
    String pushDeviceId,
  ) async {
    unregistered.add(pushDeviceId);
    final failure = unregisterFailure;
    if (failure != null) return Left(failure);
    return const Right(unit);
  }

  Future<void> close() async {
    await tokenRefresh.close();
    await foreground.close();
    await opened.close();
  }
}

class _FakeStorage extends Fake implements LocalStorageService {
  final Map<String, Object?> values = {};

  @override
  Future<T?> get<T>(String key) async => values[key] as T?;

  @override
  Future<bool> set<T>(String key, T value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepository repo;
  late _FakeStorage storage;
  late PushNotificationService service;

  setUp(() {
    // Off Android the service skips the local-notifications channel setup,
    // which has no platform implementation under test.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    repo = _FakeRepository();
    storage = _FakeStorage();
    service = PushNotificationService(repository: repo, storage: storage);
  });

  tearDown(() async {
    service.dispose();
    await repo.close();
    debugDefaultTargetPlatformOverride = null;
  });

  group('master switch', () {
    test('registration stores the backend device id', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      expect(repo.registered, ['tok-1']);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-1');
    });

    test('master off unregisters with the stored id and clears it', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      service.setMasterEnabled(false);
      await _settle();

      expect(repo.unregistered, ['dev-1']);
      expect(
        storage.values.containsKey(StorageKeys.pushDeviceServerId),
        isFalse,
      );
    });

    test('master back on registers again', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();
      service.setMasterEnabled(false);
      await _settle();

      repo.serverIdToReturn = 'dev-2';
      service.setMasterEnabled(true);
      await _settle();

      expect(repo.registered, ['tok-1', 'tok-1']);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-2');
    });

    test('a token refresh while master is off does not re-register', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();
      service.setMasterEnabled(false);
      await _settle();

      repo.tokenRefresh.add('tok-2');
      await _settle();

      expect(repo.registered, ['tok-1']);
    });

    test('the same value twice is a no-op', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      service.setMasterEnabled(true);
      service.setMasterEnabled(true);
      await _settle();

      expect(repo.registered, ['tok-1']);
      expect(repo.unregistered, isEmpty);
    });

    test('signing in with master off removes a registration left from an '
        'earlier session', () async {
      storage.values[StorageKeys.pushDeviceServerId] = 'dev-old';
      service.setMasterEnabled(false);
      await service.initialize();

      service.onAuthChanged(loggedIn: true);
      await _settle();

      expect(repo.registered, isEmpty);
      expect(repo.unregistered, ['dev-old']);
      expect(
        storage.values.containsKey(StorageKeys.pushDeviceServerId),
        isFalse,
      );
    });

    test('master off while signed out waits for sign-in', () async {
      storage.values[StorageKeys.pushDeviceServerId] = 'dev-old';
      await service.initialize();

      service.setMasterEnabled(false);
      await _settle();
      expect(repo.unregistered, isEmpty);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-old');
    });

    test('a failed unregister keeps the id for a later attempt', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      repo.unregisterFailure = const NetworkFailure('offline');
      service.setMasterEnabled(false);
      await _settle();

      expect(repo.unregistered, ['dev-1']);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-1');
    });
  });

  group('foreground suppression', () {
    test('a suppressed message never reaches the heads-up', () async {
      final asked = <PushMessage>[];
      service.shouldSuppressForeground = (message) {
        asked.add(message);
        return true;
      };
      await service.initialize();

      const message = PushMessage(
        title: 'Sangha',
        body: 'Tenzin: hello',
        data: {'session_type': 'CHAT', 'chat_kind': 'GROUP', 'group_id': 'g'},
      );
      repo.foreground.add(message);
      await _settle();

      // Reaching the platform show() would throw MissingPluginException here,
      // so a clean run means the message was dropped before it.
      expect(asked, [message]);
    });
  });
}
