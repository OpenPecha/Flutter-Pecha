import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/localization/data/languages_remote_datasource.dart';
import 'package:flutter_pecha/core/localization/languages_providers.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory storage so notifiers persist without SharedPreferences.
class _FakeStorage implements LocalStorageService {
  _FakeStorage([Map<String, Object?>? initial]) : _store = {...?initial};
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

/// Datasource stub: returns a fixed list, or throws to simulate offline.
class _FakeLanguagesDatasource extends LanguagesRemoteDatasource {
  _FakeLanguagesDatasource(this._onFetch) : super(dio: Dio());
  final Future<List<AppLanguage>> Function() _onFetch;
  bool? lastRecitationOnly;

  @override
  Future<List<AppLanguage>> fetchLanguages({bool recitationOnly = false}) {
    lastRecitationOnly = recitationOnly;
    return _onFetch();
  }
}

ProviderContainer _container(
  _FakeStorage storage,
  Future<List<AppLanguage>> Function() onFetch,
) {
  return ProviderContainer(
    overrides: [
      localStorageServiceProvider.overrideWithValue(storage),
      languagesRemoteDatasourceProvider.overrideWithValue(
        _FakeLanguagesDatasource(onFetch),
      ),
    ],
  );
}

AppLanguage _lang(String code) =>
    AppLanguage(code: code, name: code, nativeName: code);

void main() {
  test(
    'disabled stored language is reconciled and UI locale stays paired',
    () async {
      // Stored bo, backend now only serves en/zh.
      final storage = _FakeStorage({
        StorageKeys.contentLanguage: 'bo',
        StorageKeys.preferredLanguage: 'bo',
      });
      final container = _container(
        storage,
        () async => [_lang('en'), _lang('zh')],
      );
      addTearDown(container.dispose);

      await container.read(availableContentLanguagesProvider.future);

      // Content switched off the disabled language...
      expect(container.read(contentLanguageProvider), 'en');
      // ...and the UI locale switched with it (no split-brain state).
      expect(container.read(localeProvider).languageCode, 'en');
      expect(await storage.get<String>(StorageKeys.contentLanguage), 'en');
      expect(await storage.get<String>(StorageKeys.preferredLanguage), 'en');
    },
  );

  test(
    'authoritative empty response still reconciles the stored language',
    () async {
      final storage = _FakeStorage({StorageKeys.contentLanguage: 'bo'});
      // Successful response, but the backend enabled nothing.
      final container = _container(storage, () async => <AppLanguage>[]);
      addTearDown(container.dispose);

      final shown = await container.read(
        availableContentLanguagesProvider.future,
      );

      // Reconciliation ran despite the empty list (not treated as offline).
      expect(
        container.read(contentLanguageProvider),
        AppConfig.defaultLanguage,
      );
      // Picker still shows something rather than a blank sheet.
      expect(shown, AppLanguage.bundledFallback);
    },
  );

  test('offline (fetch throws) leaves the stored selection untouched', () async {
    final storage = _FakeStorage({
      StorageKeys.contentLanguage: 'bo',
      StorageKeys.preferredLanguage: 'bo',
    });
    final container = _container(
      storage,
      () async => throw DioException(requestOptions: RequestOptions()),
    );
    addTearDown(container.dispose);

    final shown = await container.read(
      availableContentLanguagesProvider.future,
    );

    // Load the persisted selection the way app startup would (the offline path
    // never touches these notifiers). ensureInitialized awaits the shared
    // in-flight storage read on both notifiers.
    await container.read(contentLanguageProvider.notifier).ensureInitialized();
    await container.read(localeProvider.notifier).ensureInitialized();

    // Kill switch must NOT fire on the offline fallback path.
    expect(container.read(contentLanguageProvider), 'bo');
    expect(container.read(localeProvider).languageCode, 'bo');
    expect(shown, AppLanguage.bundledFallback);
  });

  test('recitation languages are fetched with recitation_only', () async {
    final fake = _FakeLanguagesDatasource(() async => [_lang('en')]);
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(_FakeStorage()),
        languagesRemoteDatasourceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    await container.read(recitationContentLanguagesProvider.future);

    expect(fake.lastRecitationOnly, isTrue);
  });

  test('recitation languages do not reconcile the stored selection', () async {
    final storage = _FakeStorage({
      StorageKeys.contentLanguage: 'bo',
      StorageKeys.preferredLanguage: 'bo',
    });
    final container = _container(storage, () async => [_lang('en')]);
    addTearDown(container.dispose);

    final shown = await container.read(
      recitationContentLanguagesProvider.future,
    );

    await container.read(contentLanguageProvider.notifier).ensureInitialized();
    await container.read(localeProvider.notifier).ensureInitialized();

    expect(shown, [_lang('en')]);
    expect(container.read(contentLanguageProvider), 'bo');
    expect(container.read(localeProvider).languageCode, 'bo');
  });
}
