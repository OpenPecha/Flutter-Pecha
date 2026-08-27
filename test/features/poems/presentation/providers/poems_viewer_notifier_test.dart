import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poems_page.dart';
import 'package:flutter_pecha/features/poems/domain/repositories/poems_repository.dart';
import 'package:flutter_pecha/features/poems/presentation/providers/poems_providers.dart';
import 'package:flutter_pecha/features/poems/presentation/providers/poems_viewer_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

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
    for (final poem in _allPoems) {
      if (poem.id == poemId) return Right(poem);
    }
    return const Left(NotFoundFailure('Poem not found'));
  }
}

void main() {
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

      final notifier = container.read(poemsViewerProvider(null).notifier);
      await notifier.loadInitial();

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

      final notifier = container.read(poemsViewerProvider('p2').notifier);
      await notifier.loadInitial();

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

        final notifier =
            container.read(poemsViewerProvider('later-poem').notifier);
        await notifier.loadInitial();

        final state = container.read(poemsViewerProvider('later-poem'));
        expect(state.poems.first.id, 'later-poem');
        expect(state.initialIndex, 0);
        // One call for the first page, one for the individual poem lookup.
        expect(repo.fetchPagesCalled, 1);
      },
    );

    test(
      'keeps the loaded page when a requested poem id does not exist',
      () async {
        final repo = FakePoemsRepository(
          allPoems: List.generate(5, (i) => _poem('p$i')),
        );
        final container = buildContainer(repo);
        addTearDown(container.dispose);

        final notifier =
            container.read(poemsViewerProvider('missing-id').notifier);
        await notifier.loadInitial();

        final state = container.read(poemsViewerProvider('missing-id'));
        expect(state.hasLoaded, isTrue);
        expect(state.poems.map((p) => p.id), ['p0', 'p1', 'p2', 'p3', 'p4']);
        expect(state.initialIndex, 0);
      },
    );

    test('surfaces a failure and keeps poems empty', () async {
      final repo = FakePoemsRepository(allPoems: const [])
        ..nextPageFailure = const NetworkFailure('offline');
      final container = buildContainer(repo);
      addTearDown(container.dispose);

      final notifier = container.read(poemsViewerProvider(null).notifier);
      await notifier.loadInitial();

      final state = container.read(poemsViewerProvider(null));
      expect(state.hasLoaded, isTrue);
      expect(state.poems, isEmpty);
      expect(state.error, 'offline');
    });
  });

  group('PoemsViewerNotifier.loadMore', () {
    test('appends the next page and advances skip', () async {
      final repo = FakePoemsRepository(
        allPoems: List.generate(25, (i) => _poem('p$i')),
      );
      final container = buildContainer(repo);
      addTearDown(container.dispose);

      final notifier = container.read(poemsViewerProvider(null).notifier);
      await notifier.loadInitial();
      expect(container.read(poemsViewerProvider(null)).poems.length, 20);
      expect(container.read(poemsViewerProvider(null)).hasMore, isTrue);

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

      final notifier = container.read(poemsViewerProvider(null).notifier);
      await notifier.loadInitial();
      expect(container.read(poemsViewerProvider(null)).hasMore, isFalse);

      final callsBefore = repo.fetchPagesCalled;
      await notifier.loadMore();
      expect(repo.fetchPagesCalled, callsBefore);
    });
  });
}
