import 'dart:async';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [LocalStorageService] so notifier tests need no generated mocks.
class _FakeStorage implements LocalStorageService {
  _FakeStorage([Map<String, Object?>? initial])
    : _store = {...?initial};

  final Map<String, Object?> _store;

  @override
  Future<T?> get<T>(String key) async => _store[key] as T?;

  @override
  Future<bool> set<T>(String key, T value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _store.clear();
    return true;
  }

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  @override
  Future<void> setUserData(Map<String, dynamic> userData) async {}

  @override
  Future<Map<String, dynamic>?> getUserData() async => null;

  @override
  Future<void> clearUserData() async {}
}

/// Storage whose reads resolve only when [releaseReads] is called, so a test
/// can inject a selection while initialization is mid-flight.
class _BlockingStorage extends _FakeStorage {
  _BlockingStorage([super.initial]);

  final List<void Function()> _pendingReads = [];

  @override
  Future<T?> get<T>(String key) async {
    final completer = Completer<void>();
    _pendingReads.add(completer.complete);
    await completer.future;
    return _store[key] as T?;
  }

  void releaseReads() {
    for (final release in _pendingReads) {
      release();
    }
    _pendingReads.clear();
  }
}

Future<ContentLanguageNotifier> _createNotifier(_FakeStorage storage) async {
  final notifier = ContentLanguageNotifier(localStorageService: storage);
  await notifier.ensureInitialized();
  // Let the async initializer settle.
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return notifier;
}

void main() {
  group('AppLanguage.fromJson', () {
    test('parses a full payload', () {
      final lang = AppLanguage.fromJson({
        'code': 'bo',
        'name': 'Tibetan',
        'native_name': 'བོད་ཡིག',
        'enabled': true,
      });
      expect(lang.code, 'bo');
      expect(lang.name, 'Tibetan');
      expect(lang.nativeName, 'བོད་ཡིག');
      expect(lang.enabled, isTrue);
    });

    test('defaults enabled to true and falls back for missing names', () {
      final lang = AppLanguage.fromJson({'code': 'th'});
      expect(lang.enabled, isTrue);
      // No name/native_name -> both fall back to the raw code.
      expect(lang.name, 'th');
      expect(lang.nativeName, 'th');
    });

    test('native name falls back to English name when absent', () {
      final lang = AppLanguage.fromJson({'code': 'th', 'name': 'Thai'});
      expect(lang.nativeName, 'Thai');
    });
  });

  group('ContentLanguageNotifier', () {
    test('loads the stored content language', () async {
      final storage = _FakeStorage({StorageKeys.contentLanguage: 'zh'});
      final notifier = await _createNotifier(storage);
      expect(notifier.state, 'zh');
      notifier.dispose();
    });

    test('migrates from the legacy UI locale when unset', () async {
      final storage = _FakeStorage({StorageKeys.preferredLanguage: 'bo'});
      final notifier = await _createNotifier(storage);
      expect(notifier.state, 'bo');
      notifier.dispose();
    });

    test('defaults to English when nothing is stored', () async {
      final notifier = await _createNotifier(_FakeStorage());
      expect(notifier.state, AppConfig.defaultLanguage);
      notifier.dispose();
    });

    test('persists a raw code the app has no UI translation for', () async {
      final storage = _FakeStorage();
      final notifier = await _createNotifier(storage);

      await notifier.setContentLanguage('th');

      expect(notifier.state, 'th');
      expect(await storage.get<String>(StorageKeys.contentLanguage), 'th');
      notifier.dispose();
    });

    group('reconcileToAvailable (kill switch)', () {
      test('switches off a disabled code to the default', () async {
        final storage = _FakeStorage({StorageKeys.contentLanguage: 'bo'});
        final notifier = await _createNotifier(storage);

        // Backend no longer lists 'bo'.
        await notifier.reconcileToAvailable(['en', 'zh']);

        expect(notifier.state, AppConfig.defaultLanguage);
        expect(
          await storage.get<String>(StorageKeys.contentLanguage),
          AppConfig.defaultLanguage,
        );
        notifier.dispose();
      });

      test('keeps a still-enabled code untouched', () async {
        final storage = _FakeStorage({StorageKeys.contentLanguage: 'zh'});
        final notifier = await _createNotifier(storage);

        await notifier.reconcileToAvailable(['en', 'zh']);

        expect(notifier.state, 'zh');
        notifier.dispose();
      });

      test('an authoritative empty response falls back to the default',
          () async {
        final storage = _FakeStorage({StorageKeys.contentLanguage: 'bo'});
        final notifier = await _createNotifier(storage);

        // An empty list is a successful "nothing enabled" answer, not offline —
        // offline is guarded at the provider (it never calls this on error).
        final switched = await notifier.reconcileToAvailable([]);

        expect(switched, AppConfig.defaultLanguage);
        expect(notifier.state, AppConfig.defaultLanguage);
        notifier.dispose();
      });

      test('returns null (no change) when the code is still enabled', () async {
        final storage = _FakeStorage({StorageKeys.contentLanguage: 'zh'});
        final notifier = await _createNotifier(storage);

        expect(await notifier.reconcileToAvailable(['en', 'zh']), isNull);
        notifier.dispose();
      });

      test('falls back to the first enabled code when default is gone',
          () async {
        final storage = _FakeStorage({StorageKeys.contentLanguage: 'bo'});
        final notifier = await _createNotifier(storage);

        await notifier.reconcileToAvailable(['zh', 'hi']);

        expect(notifier.state, 'zh');
        notifier.dispose();
      });
    });

    test(
      'a selection during initialization is not clobbered by the legacy read',
      () async {
        // Existing user upgrading: no content_language yet, but a legacy UI
        // locale is present. Reads are blocked so the selection lands while
        // initialization is still mid-flight.
        final storage = _BlockingStorage({
          StorageKeys.preferredLanguage: 'en',
        });
        final notifier = ContentLanguageNotifier(localStorageService: storage);

        // User picks a language before the startup reads resolve.
        await notifier.setContentLanguage('bo');
        expect(notifier.state, 'bo');

        // Now let the pending initialization reads complete.
        storage.releaseReads();
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }

        // The user's choice must survive.
        expect(notifier.state, 'bo');
        notifier.dispose();
      },
    );
  });
}
