import 'dart:async';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poems_page.dart';
import 'package:flutter_pecha/features/poems/domain/repositories/poems_repository.dart';
import 'package:flutter_pecha/features/poems/presentation/providers/poems_providers.dart';
import 'package:flutter_pecha/features/poems/presentation/providers/poems_viewer_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _InMemoryStorage implements LocalStorageService {
  final Map<String, Object?> _store = {};

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

Poem _poem(String id, {String title = 'Title'}) => Poem(
  id: id,
  title: title,
  content: 'Content for $id',
  authorName: 'Author',
  status: PoemStatus.published,
);

/// In-memory fake standing in for the real repository so notifier tests
/// don't need a Dio mock or code generation.
class FakePoemsRepository implements PoemsRepositoryInterface {
  FakePoemsRepository({required List<Poem> allPoems}) : _allPoems = allPoems;

  final List<Poem> _allPoems;
  int fetchPagesCalled = 0;
  Failure? nextPageFailure;
  Failure? nextPoemFailure;

  @override
  Future<Either<Failure, PoemsPage>> getPoems({
    required String language,
    int skip = 0,
    int limit = 20,
    String? chapterName,
    String? authorName,
  }) async {
    fetchPagesCalled++;
    if (nextPageFailure != null) {
      final failure = nextPageFailure!;
      nextPageFailure = null;
      return Left(failure);
    }
    final page = _allPoems.skip(skip).take(limit).toList();
    return Right(
      PoemsPage(
        poems: page,
        skip: skip,
        limit: limit,
        hasMore: skip + page.length < _allPoems.length,
      ),
    );
  }

  @override
  Future<Either<Failure, Poem>> getPoem(String poemId) async {
    if (nextPoemFailure != null) {
      final failure = nextPoemFailure!;
      nextPoemFailure = null;
      return Left(failure);
    }
    for (final poem in _allPoems) {
      if (poem.id == poemId) return Right(poem);
    }
    return const Left(NotFoundFailure('Poem not found'));
  }
}

void main() {
  Future<void> pumpUntilSettled(
    ProviderContainer container,
    String? initialPoemId,
  ) async {
    final sub = container.listen(
      poemsViewerProvider(initialPoemId),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    for (var i = 0; i < 100; i++) {
      final state = container.read(poemsViewerProvider(initialPoemId));
      if (!state.isLoading && (state.hasLoaded || state.error != null)) {
        return;
      }
      await Future<void>.delayed(Duration.zero);
    }
    fail('Timed out waiting for poems viewer to settle');
  }

  ProviderContainer buildContainer(PoemsRepositoryInterface repository) {
    return ProviderContainer(
      overrides: [poemsRepositoryProvider.overrideWithValue(repository)],
    );
  }

  group('PoemsViewerNotifier.loadInitial', () {
    test('loads the first page and defaults to index 0', () async {
      final repo = FakePoemsRepository(
        allPoems: List.generate(5, (i) => _poem('p$i')),
      );
      final container = buildContainer(repo);
      addTearDown(container.dispose);

      container.read(poemsViewerProvider(null));
      await pumpUntilSettled(container, null);

      final state = container.read(poemsViewerProvider(null));
      expect(state.hasLoaded, isTrue);
      expect(state.poems.map((p) => p.id), ['p0', 'p1', 'p2', 'p3', 'p4']);
      expect(state.initialIndex, 0);
      expect(state.error, isNull);
    });

    test('resolves initialIndex when the poem is in the first page', () async {
      final repo = FakePoemsRepository(
        allPoems: List.generate(5, (i) => _poem('p$i')),
      );
      final container = buildContainer(repo);
      addTearDown(container.dispose);

      container.read(poemsViewerProvider('p2'));
      await pumpUntilSettled(container, 'p2');

      final state = container.read(poemsViewerProvider('p2'));
      expect(state.initialIndex, 2);
      // No extra single-poem fetch was needed beyond the page fetch.
      expect(repo.fetchPagesCalled, 1);
    });

    test(
      'fetches and pins the poem to the front when missing from the first page',
      () async {
        // A page-1-limit of 20 means a poem that exists but sits beyond the
        // first page (simulated here with a small custom limit via a long
        // list) won't be found by index — the notifier should fall back to
        // `getPoem` and pin it to the front instead of leaving the reader on
        // the wrong poem.
        final repo = FakePoemsRepository(
          allPoems: [
            ...List.generate(20, (i) => _poem('p$i')),
            _poem('later-poem'),
          ],
        );
        final container = buildContainer(repo);
        addTearDown(container.dispose);

        container.read(poemsViewerProvider('later-poem'));
        await pumpUntilSettled(container, 'later-poem');

        final state = container.read(poemsViewerProvider('later-poem'));
        expect(state.poems.first.id, 'later-poem');
        expect(state.initialIndex, 0);
        // One call for the first page, one for the individual poem lookup.
        expect(repo.fetchPagesCalled, 1);
      },
    );

    test(
      'surfaces an error when a requested poem id does not exist',
      () async {
        final repo = FakePoemsRepository(
          allPoems: List.generate(5, (i) => _poem('p$i')),
        );
        final container = buildContainer(repo);
        addTearDown(container.dispose);

        container.read(poemsViewerProvider('missing-id'));
        await pumpUntilSettled(container, 'missing-id');

        final state = container.read(poemsViewerProvider('missing-id'));
        expect(state.hasLoaded, isFalse);
        expect(state.poems, isEmpty);
        expect(state.error, 'Poem not found');
      },
    );

    test(
      'surfaces an error when a missing first-page poem lookup fails',
      () async {
        final repo = FakePoemsRepository(
          allPoems: [
            ...List.generate(20, (i) => _poem('p$i')),
            _poem('later-poem'),
          ],
        )..nextPoemFailure = const NetworkFailure('offline');
        final container = buildContainer(repo);
        addTearDown(container.dispose);

        container.read(poemsViewerProvider('later-poem'));
        await pumpUntilSettled(container, 'later-poem');

        final state = container.read(poemsViewerProvider('later-poem'));
        expect(state.hasLoaded, isFalse);
        expect(state.poems, isEmpty);
        expect(state.error, 'offline');
      },
    );

    test(
      'allows retry after a selected poem lookup failure',
      () async {
        final repo = FakePoemsRepository(
          allPoems: [
            ...List.generate(20, (i) => _poem('p$i')),
            _poem('later-poem'),
          ],
        )..nextPoemFailure = const NetworkFailure('offline');
        final container = buildContainer(repo);
        addTearDown(container.dispose);

        container.read(poemsViewerProvider('later-poem'));
        await pumpUntilSettled(container, 'later-poem');

        expect(
          container.read(poemsViewerProvider('later-poem')).error,
          'offline',
        );

        await container
            .read(poemsViewerProvider('later-poem').notifier)
            .loadInitial();
        await pumpUntilSettled(container, 'later-poem');

        final state = container.read(poemsViewerProvider('later-poem'));
        expect(state.hasLoaded, isTrue);
        expect(state.error, isNull);
        expect(state.poems.first.id, 'later-poem');
        expect(state.initialIndex, 0);
      },
    );

    test('surfaces a failure and keeps poems empty', () async {
      final repo = FakePoemsRepository(allPoems: const [])
        ..nextPageFailure = const NetworkFailure('offline');
      final container = buildContainer(repo);
      addTearDown(container.dispose);

      container.read(poemsViewerProvider(null));
      await pumpUntilSettled(container, null);

      final state = container.read(poemsViewerProvider(null));
      expect(state.hasLoaded, isFalse);
      expect(state.poems, isEmpty);
      expect(state.error, 'offline');
    });

    test('allows retry after an initial load failure', () async {
      final repo = FakePoemsRepository(
        allPoems: List.generate(3, (i) => _poem('p$i')),
      )..nextPageFailure = const NetworkFailure('offline');
      final container = buildContainer(repo);
      addTearDown(container.dispose);

      container.read(poemsViewerProvider(null));
      await pumpUntilSettled(container, null);

      expect(container.read(poemsViewerProvider(null)).error, 'offline');
      expect(container.read(poemsViewerProvider(null)).poems, isEmpty);

      await container.read(poemsViewerProvider(null).notifier).loadInitial();
      await pumpUntilSettled(container, null);

      final state = container.read(poemsViewerProvider(null));
      expect(state.hasLoaded, isTrue);
      expect(state.error, isNull);
      expect(state.poems.map((p) => p.id), ['p0', 'p1', 'p2']);
    });
  });

  group('PoemsViewerNotifier.loadMore', () {
    test('appends the next page and advances skip', () async {
      final repo = FakePoemsRepository(
        allPoems: List.generate(25, (i) => _poem('p$i')),
      );
      final container = buildContainer(repo);
      addTearDown(container.dispose);

      container.read(poemsViewerProvider(null));
      await pumpUntilSettled(container, null);
      final notifier = container.read(poemsViewerProvider(null).notifier);
      expect(container.read(poemsViewerProvider(null)).poems.length, 20);
      expect(container.read(poemsViewerProvider(null)).hasMore, isTrue);

      await notifier.loadMore();

      final state = container.read(poemsViewerProvider(null));
      expect(state.poems.length, 25);
      expect(state.hasMore, isFalse);
    });

    test('keeps hasMore true after a pagination failure so scroll retry works',
        () async {
      final repo = FakePoemsRepository(
        allPoems: List.generate(25, (i) => _poem('p$i')),
      );
      final container = buildContainer(repo);
      addTearDown(container.dispose);

      container.read(poemsViewerProvider(null));
      await pumpUntilSettled(container, null);
      final notifier = container.read(poemsViewerProvider(null).notifier);
      expect(container.read(poemsViewerProvider(null)).hasMore, isTrue);
      expect(container.read(poemsViewerProvider(null)).poems.length, 20);

      repo.nextPageFailure = const NetworkFailure('offline');
      await notifier.loadMore();

      final failedState = container.read(poemsViewerProvider(null));
      expect(failedState.hasMore, isTrue);
      expect(failedState.poems.length, 20);
      expect(failedState.isLoadingMore, isFalse);

      await notifier.loadMore();

      final state = container.read(poemsViewerProvider(null));
      expect(state.poems.length, 25);
      expect(state.hasMore, isFalse);
    });

    test('does nothing once hasMore is false', () async {
      final repo = FakePoemsRepository(
        allPoems: List.generate(3, (i) => _poem('p$i')),
      );
      final container = buildContainer(repo);
      addTearDown(container.dispose);

      container.read(poemsViewerProvider(null));
      await pumpUntilSettled(container, null);
      final notifier = container.read(poemsViewerProvider(null).notifier);
      expect(container.read(poemsViewerProvider(null)).hasMore, isFalse);

      final callsBefore = repo.fetchPagesCalled;
      await notifier.loadMore();
      expect(repo.fetchPagesCalled, callsBefore);
    });
  });

  group('PoemsViewerNotifier language changes', () {
    ProviderContainer buildLanguageContainer(PoemsRepositoryInterface repository) {
      return ProviderContainer(
        overrides: [
          poemsRepositoryProvider.overrideWithValue(repository),
          contentLanguageProvider.overrideWith((ref) {
            final notifier = ContentLanguageNotifier(
              localStorageService: _InMemoryStorage(),
            );
            notifier.ensureInitialized();
            return notifier;
          }),
        ],
      );
    }

    test('reloads when content language changes', () async {
      final repo = FakePoemsRepository(
        allPoems: List.generate(3, (i) => _poem('p$i')),
      );
      final container = buildLanguageContainer(repo);
      addTearDown(container.dispose);

      container.read(poemsViewerProvider(null));
      await pumpUntilSettled(container, null);
      expect(container.read(poemsViewerProvider(null)).hasLoaded, isTrue);
      final callsAfterFirstLoad = repo.fetchPagesCalled;

      await container
          .read(contentLanguageProvider.notifier)
          .setContentLanguage('bo');
      await pumpUntilSettled(container, null);

      expect(repo.fetchPagesCalled, greaterThan(callsAfterFirstLoad));
      expect(container.read(poemsViewerProvider(null)).hasLoaded, isTrue);
      expect(container.read(poemsViewerProvider(null)).poems, isNotEmpty);
    });

    test(
      'does not throw when content language changes during an in-flight load',
      () async {
        final pageCompleter = Completer<Either<Failure, PoemsPage>>();
        final repo = _DelayedPoemsRepository(
          allPoems: List.generate(3, (i) => _poem('p$i')),
          pageCompleter: pageCompleter,
        );
        final container = buildLanguageContainer(repo);
        addTearDown(container.dispose);

        container.read(poemsViewerProvider(null));
        await Future<void>.delayed(Duration.zero);
        expect(container.read(poemsViewerProvider(null)).isLoading, isTrue);

        await container
            .read(contentLanguageProvider.notifier)
            .setContentLanguage('bo');

        pageCompleter.complete(
          Right(
            PoemsPage(
              poems: List.generate(3, (i) => _poem('p$i')),
              skip: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
        );
        await pumpUntilSettled(container, null);

        expect(container.read(poemsViewerProvider(null)).hasLoaded, isTrue);
        expect(container.read(poemsViewerProvider(null)).poems, isNotEmpty);
      },
    );
  });
}

/// Holds [getPoems] until [pageCompleter] is completed so tests can change
/// language mid-request.
class _DelayedPoemsRepository extends FakePoemsRepository {
  _DelayedPoemsRepository({
    required super.allPoems,
    required this.pageCompleter,
  });

  final Completer<Either<Failure, PoemsPage>> pageCompleter;

  @override
  Future<Either<Failure, PoemsPage>> getPoems({
    required String language,
    int skip = 0,
    int limit = 20,
    String? chapterName,
    String? authorName,
  }) async {
    fetchPagesCalled++;
    if (nextPageFailure != null) {
      final failure = nextPageFailure!;
      nextPageFailure = null;
      return Left(failure);
    }
    return pageCompleter.future;
  }
}
