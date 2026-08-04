import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_accumulator_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_accumulator_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_accumulator_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/group_accumulation_counts_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final groupAccumulatorRemoteDatasourceProvider =
    Provider<GroupAccumulatorRemoteDatasource>((ref) {
      return GroupAccumulatorRemoteDatasource(dio: ref.watch(dioProvider));
    });

final groupAccumulatorRepositoryProvider =
    Provider<GroupAccumulatorRepositoryInterface>((ref) {
      return GroupAccumulatorRepositoryImpl(
        remote: ref.watch(groupAccumulatorRemoteDatasourceProvider),
      );
    });

final groupAccumulatorsProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupAccumulatorsPage>, String>((
      ref,
      groupId,
    ) async {
      ref.watch(authProvider);
      final repository = ref.watch(groupAccumulatorRepositoryProvider);
      return repository.getGroupAccumulators(groupId, skip: 0, limit: 20);
    });

final groupAccumulatorDetailProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupAccumulatorDetail>, String>((
      ref,
      accumulatorId,
    ) async {
      ref.watch(authProvider);
      final repository = ref.watch(groupAccumulatorRepositoryProvider);
      return repository.getGroupAccumulator(accumulatorId);
    });

@immutable
class GroupAccumulatorMembersKey {
  final String accumulatorId;
  final GroupAccumulatorMemberSort sortBy;

  const GroupAccumulatorMembersKey({
    required this.accumulatorId,
    this.sortBy = GroupAccumulatorMemberSort.total,
  });

  @override
  bool operator ==(Object other) {
    return other is GroupAccumulatorMembersKey &&
        other.accumulatorId == accumulatorId &&
        other.sortBy == sortBy;
  }

  @override
  int get hashCode => Object.hash(accumulatorId, sortBy);
}

List<GroupAccumulatorMember> sortAccumulatorMembers(
  List<GroupAccumulatorMember> members,
  GroupAccumulatorMemberSort sort,
) {
  final sorted = List<GroupAccumulatorMember>.from(members);
  sorted.sort((a, b) {
    final aCount =
        sort == GroupAccumulatorMemberSort.today ? a.todayCount : a.totalCount;
    final bCount =
        sort == GroupAccumulatorMemberSort.today ? b.todayCount : b.totalCount;
    return bCount.compareTo(aCount);
  });
  return sorted;
}

class GroupAccumulatorMembersState {
  final List<GroupAccumulatorMember> members;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoadedOnce;
  final Failure? error;

  const GroupAccumulatorMembersState({
    this.members = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasLoadedOnce = false,
    this.error,
  });

  bool get hasMore => members.length < total;

  GroupAccumulatorMembersState copyWith({
    List<GroupAccumulatorMember>? members,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoadedOnce,
    Failure? error,
    bool clearError = false,
  }) {
    return GroupAccumulatorMembersState(
      members: members ?? this.members,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GroupAccumulatorMembersNotifier
    extends StateNotifier<GroupAccumulatorMembersState> {
  GroupAccumulatorMembersNotifier({
    required GroupAccumulatorRepositoryInterface repository,
    required this.accumulatorId,
    required this.sortBy,
  }) : _repository = repository,
       super(const GroupAccumulatorMembersState());

  final GroupAccumulatorRepositoryInterface _repository;
  final String accumulatorId;
  final GroupAccumulatorMemberSort sortBy;
  static const _pageSize = 20;
  bool _hasLoaded = false;

  Future<void> loadInitial({bool force = false}) async {
    if (_hasLoaded && !force) return;
    _hasLoaded = true;
    state = state.copyWith(
      isLoading: state.members.isEmpty,
      clearError: true,
    );

    final result = await _repository.getGroupAccumulatorMembers(
      accumulatorId,
      skip: 0,
      limit: _pageSize,
      sortBy: sortBy,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        hasLoadedOnce: true,
        error: failure,
      ),
      (page) => state = state.copyWith(
        isLoading: false,
        hasLoadedOnce: true,
        members: page.members,
        total: page.total,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final result = await _repository.getGroupAccumulatorMembers(
      accumulatorId,
      skip: state.members.length,
      limit: _pageSize,
      sortBy: sortBy,
    );

    result.fold(
      (failure) => state = state.copyWith(isLoadingMore: false, error: failure),
      (page) => state = state.copyWith(
        isLoadingMore: false,
        members: [...state.members, ...page.members],
        total: page.total,
      ),
    );
  }

  Future<void> retry() async {
    _hasLoaded = false;
    await loadInitial(force: true);
  }
}

final groupAccumulatorMembersProvider = StateNotifierProvider.autoDispose
    .family<
      GroupAccumulatorMembersNotifier,
      GroupAccumulatorMembersState,
      GroupAccumulatorMembersKey
    >((ref, key) {
      return GroupAccumulatorMembersNotifier(
        repository: ref.watch(groupAccumulatorRepositoryProvider),
        accumulatorId: key.accumulatorId,
        sortBy: key.sortBy,
      );
    });

class GroupAccumulatorJoinCacheNotifier extends StateNotifier<Set<String>> {
  GroupAccumulatorJoinCacheNotifier() : super(const {});

  void markJoined(String accumulatorId) {
    state = {...state, accumulatorId};
  }

  void markUnjoined(String accumulatorId) {
    if (!state.contains(accumulatorId)) return;
    state = {...state}..remove(accumulatorId);
  }

  void clear() => state = const {};

  void syncFromApi(List<GroupAccumulator> accumulators) {
    final joinedIds =
        accumulators
            .where((accumulator) => accumulator.isJoined == true)
            .map((accumulator) => accumulator.id)
            .toSet();
    final notJoinedIds =
        accumulators
            .where((accumulator) => accumulator.isJoined == false)
            .map((accumulator) => accumulator.id)
            .toSet();

    state = {...state, ...joinedIds}..removeAll(notJoinedIds);
  }
}

final groupAccumulatorJoinCacheProvider = StateNotifierProvider.autoDispose
    .family<GroupAccumulatorJoinCacheNotifier, Set<String>, String>((
      ref,
      groupId,
    ) {
      return GroupAccumulatorJoinCacheNotifier();
    });

bool accumulatorHasJoined(
  GroupAccumulator accumulator, {
  Set<String> localJoinedIds = const {},
}) {
  if (localJoinedIds.contains(accumulator.id)) return true;
  return accumulator.isJoined == true;
}

Future<bool> joinGroupAccumulator({
  required WidgetRef ref,
  required String accumulatorId,
  required String groupId,
  GroupProfile? group,
  bool awaitRefresh = true,
}) async {
  final repository = ref.read(groupAccumulatorRepositoryProvider);
  final result = await repository.joinGroupAccumulator(accumulatorId);

  if (result.isLeft()) return false;

  ref
      .read(groupAccumulatorJoinCacheProvider(groupId).notifier)
      .markJoined(accumulatorId);

  GroupProfile? resolvedGroup = group;
  if (resolvedGroup == null) {
    final profileResult = await ref.read(groupProfileProvider(groupId).future);
    resolvedGroup = profileResult.fold((_) => null, (profile) => profile);
  }

  if (resolvedGroup != null) {
    final followKey = GroupFollowKey(
      groupId: groupId,
      groupType: resolvedGroup.groupType,
    );
    ref
        .read(groupFollowProvider(followKey).notifier)
        .markAutoJoinedFromPracticeEnrollment(group: resolvedGroup);
  }

  ref.invalidate(groupAccumulatorsProvider(groupId));
  ref.invalidate(groupAccumulatorDetailProvider(accumulatorId));

  ref.invalidate(
    groupAccumulatorMembersProvider(
      GroupAccumulatorMembersKey(
        accumulatorId: accumulatorId,
        sortBy: GroupAccumulatorMemberSort.total,
      ),
    ),
  );
  ref.invalidate(
    groupAccumulatorMembersProvider(
      GroupAccumulatorMembersKey(
        accumulatorId: accumulatorId,
        sortBy: GroupAccumulatorMemberSort.today,
      ),
    ),
  );

  final refreshFuture = Future.wait([
    ref.read(groupAccumulatorDetailProvider(accumulatorId).future),
    ref.read(groupAccumulatorsProvider(groupId).future),
  ]);

  if (awaitRefresh) {
    await refreshFuture;
  }

  return true;
}

/// Ends a group accumulation chant session:
/// 1. Flushes pending counts (best effort)
/// 2. `DELETE /group-accumulators/{group_accumulator_id}` — the accumulator `id`
///    from `GET /group-accumulators/{id}` (not preset or group id)
/// 3. Clears local session state so a later sync cannot reopen the session
Future<bool> finishGroupAccumulatorSession({
  required WidgetRef ref,
  required String groupAccumulatorId,
  required String presetId,
  String? groupId,
}) async {
  try {
    await ref.read(malaSyncManagerProvider).flush(SyncReason.screenLeave);
  } catch (_) {
    // Still DELETE — ending the session must not depend on flush succeeding.
  }

  final result = await ref
      .read(groupAccumulatorRepositoryProvider)
      .deleteGroupAccumulator(groupAccumulatorId);
  if (result.isLeft()) return false;

  final stored = await ref
      .read(localStorageServiceProvider)
      .get<String>(StorageKeys.currentUserId);
  final userId =
      stored != null && stored.isNotEmpty
          ? stored
          : ref.read(userProvider).user?.id;
  if (userId != null && userId.isNotEmpty) {
    await ref
        .read(malaLocalDataSourceProvider)
        .clearGroupSession(userId, groupAccumulatorId);
  }

  ref
      .read(groupAccumulationCountsProvider(presetId).notifier)
      .markSessionEnded(groupAccumulatorId);

  ref.invalidate(groupAccumulatorDetailProvider(groupAccumulatorId));
  if (groupId != null && groupId.isNotEmpty) {
    ref.invalidate(groupAccumulatorsProvider(groupId));
  }
  ref.invalidate(joinedGroupUserCountsProvider(presetId));
  ref.invalidate(joinedAccumulatorGroupsProvider(presetId));

  return true;
}
