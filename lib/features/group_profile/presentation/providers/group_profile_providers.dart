import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_profile_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/usecases/get_group_profile_usecase.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final groupProfileRemoteDatasourceProvider =
    Provider<GroupProfileRemoteDatasource>((ref) {
  return GroupProfileRemoteDatasource(dio: ref.watch(dioProvider));
});

final groupProfileRepositoryProvider =
    Provider<GroupProfileRepositoryInterface>((ref) {
  return GroupProfileRepositoryImpl(
    remote: ref.watch(groupProfileRemoteDatasourceProvider),
  );
});

final getGroupProfileUseCaseProvider =
    Provider<GetGroupProfileUseCase>((ref) {
  final repository = ref.watch(groupProfileRepositoryProvider);
  return GetGroupProfileUseCase(repository.getGroupProfile);
});

final groupProfileProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupProfile>, String>((ref, groupId) async {
  // Refetch when auth changes so user-specific fields (e.g. is_group_enrolled)
  // are loaded with the Bearer token attached.
  ref.watch(authProvider);
  final language = ref.watch(contentLanguageProvider);
  final useCase = ref.watch(getGroupProfileUseCaseProvider);
  return useCase(
    GetGroupProfileParams(groupId: groupId, language: language),
  );
});

@immutable
class GroupFollowKey {
  final String groupId;
  final GroupType groupType;
  final bool loadInitialStatus;

  const GroupFollowKey({
    required this.groupId,
    required this.groupType,
    this.loadInitialStatus = true,
  });

  @override
  bool operator ==(Object other) {
    return other is GroupFollowKey &&
        other.groupId == groupId &&
        other.groupType == groupType &&
        other.loadInitialStatus == loadInitialStatus;
  }

  @override
  int get hashCode => Object.hash(groupId, groupType, loadInitialStatus);
}

sealed class GroupFollowState {
  const GroupFollowState();
}

class GroupFollowLoading extends GroupFollowState {
  const GroupFollowLoading();
}

class GroupFollowSuccess extends GroupFollowState {
  final bool isFollowing;
  final int countDelta;

  const GroupFollowSuccess({
    required this.isFollowing,
    this.countDelta = 0,
  });
}

class GroupFollowFailure extends GroupFollowState {
  final Failure failure;
  const GroupFollowFailure(this.failure);
}

class GroupFollowNotifier extends StateNotifier<GroupFollowState> {
  final GroupProfileRepositoryInterface _repository;
  final Ref _ref;
  final GroupFollowKey _key;
  final bool _isAuthenticated;

  GroupFollowNotifier({
    required GroupProfileRepositoryInterface repository,
    required Ref ref,
    required GroupFollowKey key,
    required bool isAuthenticated,
  }) : _repository = repository,
       _ref = ref,
       _key = key,
       _isAuthenticated = isAuthenticated,
       super(
         key.loadInitialStatus
             ? const GroupFollowLoading()
             : const GroupFollowSuccess(isFollowing: false),
       ) {
    if (key.loadInitialStatus) {
      _loadInitialStatus();
    }
  }

  int _currentCountDelta() {
    final current = state;
    return current is GroupFollowSuccess ? current.countDelta : 0;
  }

  void _invalidateGroupProfile() {
    _ref.invalidate(groupProfileProvider(_key.groupId));
  }

  void _refreshGroupMembers() {
    final groupId = _key.groupId;
    if (!_ref.exists(groupMembersProvider(groupId))) return;

    if (_ref.read(groupMembersTabActiveProvider(groupId))) {
      _ref.read(groupMembersProvider(groupId).notifier).loadInitial();
    } else {
      _ref.read(groupMembersNeedsRefreshProvider(groupId).notifier).state =
          true;
    }
  }

  void _invalidateConnectProviders() {
    _ref.invalidate(myGroupsProvider);
    _ref.invalidate(discoverGroupsProvider);
  }

  void _addPendingJoinedGroup(GroupProfile group) {
    final updatedGroup = group.withMemberCountDelta(1);
    _ref.read(pendingJoinedGroupsProvider.notifier).update((groups) {
      if (groups.any((g) => g.id == group.id)) return groups;
      return [updatedGroup, ...groups];
    });
    _clearPendingUnjoined(group.id);
  }

  void _removePendingJoinedGroup(String groupId) {
    _ref.read(pendingJoinedGroupsProvider.notifier).update(
      (groups) => groups.where((g) => g.id != groupId).toList(),
    );
  }

  void _markPendingUnjoined(String groupId) {
    _ref.read(pendingUnjoinedGroupIdsProvider.notifier).update(
      (ids) => {...ids, groupId},
    );
  }

  void _clearPendingUnjoined(String groupId) {
    _ref.read(pendingUnjoinedGroupIdsProvider.notifier).update(
      (ids) => {...ids}..remove(groupId),
    );
  }

  Future<void> _loadInitialStatus() async {
    if (!_isAuthenticated) {
      if (mounted) state = const GroupFollowSuccess(isFollowing: false);
      return;
    }

    final result = await _repository.checkFollowStatus(
      _key.groupId,
      _key.groupType,
    );
    if (!mounted) return;

    result.fold(
      (_) => state = const GroupFollowSuccess(isFollowing: false),
      (isFollowing) => state = GroupFollowSuccess(isFollowing: isFollowing),
    );
  }

  Future<bool> follow({GroupProfile? connectGroup}) async {
    if (state is GroupFollowLoading) return false;
    state = const GroupFollowLoading();

    final result = await _repository.followGroup(
      _key.groupId,
      _key.groupType,
    );
    if (!mounted) return false;

    return await result.fold(
      (failure) async {
        state = GroupFollowFailure(failure);
        return false;
      },
      (_) async {
        _applyJoinedState(connectGroup: connectGroup, incrementCount: true);
        return true;
      },
    );
  }

  /// Backend auto-joins the group when enrolling in a series via group_id.
  /// Updates join UI immediately without a manual refresh.
  void markAutoJoinedFromPracticeEnrollment({required GroupProfile group}) {
    if (!_isAuthenticated) return;

    final alreadyFollowing = switch (state) {
      GroupFollowSuccess(isFollowing: final isFollowing) => isFollowing,
      _ => false,
    };
    if (alreadyFollowing) return;

    _applyJoinedState(connectGroup: group, incrementCount: true);
  }

  /// Re-sync join status after returning from a flow that may have auto-joined.
  Future<void> syncJoinStatusFromServer({GroupProfile? connectGroup}) async {
    if (!_isAuthenticated) return;

    final result = await _repository.checkFollowStatus(
      _key.groupId,
      _key.groupType,
    );
    if (!mounted) return;

    result.fold((_) {}, (isFollowing) {
      if (!isFollowing) return;

      final alreadyFollowing = switch (state) {
        GroupFollowSuccess(isFollowing: final following) => following,
        _ => false,
      };
      _applyJoinedState(
        connectGroup: connectGroup,
        incrementCount: !alreadyFollowing,
      );
    });
  }

  void _applyJoinedState({
    required GroupProfile? connectGroup,
    required bool incrementCount,
  }) {
    final previousDelta = _currentCountDelta();
    state = GroupFollowSuccess(
      isFollowing: true,
      countDelta: incrementCount ? previousDelta + 1 : previousDelta,
    );
    _invalidateGroupProfile();
    _refreshGroupMembers();
    _invalidateConnectProviders();
    if (connectGroup != null) {
      _addPendingJoinedGroup(connectGroup);
      _ref
          .read(discoverGroupsProvider.notifier)
          .removeGroups({connectGroup.id});
    }
  }

  Future<bool> unfollow({GroupProfile? connectGroup}) async {
    if (state is GroupFollowLoading) return false;
    final previousDelta = _currentCountDelta();
    state = const GroupFollowLoading();

    final result = await _repository.unfollowGroup(
      _key.groupId,
      _key.groupType,
    );
    if (!mounted) return false;

    return await result.fold(
      (failure) async {
        state = GroupFollowFailure(failure);
        return false;
      },
      (_) async {
        state = GroupFollowSuccess(
          isFollowing: false,
          countDelta: previousDelta - 1,
        );
        _invalidateGroupProfile();
        _refreshGroupMembers();
        _invalidateConnectProviders();
        if (connectGroup != null) {
          _removePendingJoinedGroup(connectGroup.id);
          _markPendingUnjoined(connectGroup.id);
        }
        return true;
      },
    );
  }
}

final groupFollowProvider = StateNotifierProvider.autoDispose
    .family<GroupFollowNotifier, GroupFollowState, GroupFollowKey>((ref, key) {
  final authState = ref.watch(authProvider);
  final isAuthenticated = !authState.isGuest && authState.isLoggedIn;

  return GroupFollowNotifier(
    repository: ref.watch(groupProfileRepositoryProvider),
    ref: ref,
    key: key,
    isAuthenticated: isAuthenticated,
  );
});

bool isSeriesGroupEnrolledInProfile(GroupProfile profile, String seriesId) {
  return profile.series.any(
    (series) => series.id == seriesId && series.isGroupEnrolled == true,
  );
}

/// Returns the tri-state group enrollment status for a series.
/// - `true`: enrolled with this group
/// - `false`: enrolled with a different group
/// - `null`: not group-enrolled
bool? seriesGroupEnrollmentStatus(
  GroupProfileSeries series, {
  Set<String> localEnrolledSeriesIds = const {},
}) {
  if (localEnrolledSeriesIds.contains(series.id)) return true;
  return series.isGroupEnrolled;
}

bool? seriesGroupEnrollmentStatusFromProfile(
  GroupProfile profile,
  String seriesId, {
  Set<String> localEnrolledSeriesIds = const {},
}) {
  for (final series in profile.series) {
    if (series.id == seriesId) {
      return seriesGroupEnrollmentStatus(
        series,
        localEnrolledSeriesIds: localEnrolledSeriesIds,
      );
    }
  }
  return null;
}

/// Shows the change-group confirmation dialog when [enrollmentStatus] is false.
Future<bool> confirmGroupPracticeChangeIfNeeded(
  BuildContext context,
  bool? enrollmentStatus,
) async {
  if (enrollmentStatus != false) return true;

  final l10n = context.l10n;
  final confirmed = await showConfirmationDialog(
    context,
    title: l10n.group_change_practice_title,
    message: l10n.group_change_practice_message,
    confirmLabel: l10n.ai_confirm,
  );
  return confirmed == true;
}

/// Enrolls in a series via [groupId] and updates group join UI optimistically.
Future<bool> enrollSeriesThroughGroup({
  required WidgetRef ref,
  required String seriesId,
  required String groupId,
  required GroupType groupType,
}) async {
  final notifier = ref.read(seriesEnrollmentProvider(seriesId).notifier);
  final ok = await notifier.enroll(groupId: groupId);
  if (!ok) return false;

  final followKey = GroupFollowKey(groupId: groupId, groupType: groupType);
  final profileResult = await ref.read(groupProfileProvider(groupId).future);
  profileResult.fold(
    (_) {},
    (profile) => ref
        .read(groupFollowProvider(followKey).notifier)
        .markAutoJoinedFromPracticeEnrollment(group: profile),
  );
  ref.invalidate(groupProfileProvider(groupId));
  return true;
}

/// Syncs join state after returning from the post-enrollment routine editor.
Future<void> completeGroupPracticeEnrollmentFlow({
  required WidgetRef ref,
  required String groupId,
  required GroupType groupType,
}) async {
  final followKey = GroupFollowKey(groupId: groupId, groupType: groupType);
  final profileResult = await ref.read(groupProfileProvider(groupId).future);
  await profileResult.fold(
    (_) async {},
    (profile) => ref
        .read(groupFollowProvider(followKey).notifier)
        .syncJoinStatusFromServer(connectGroup: profile),
  );
  ref.invalidate(groupProfileProvider(groupId));
}

class GroupMembersState {
  final List<GroupMember> members;
  final int totalMembers;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const GroupMembersState({
    this.members = const [],
    this.totalMembers = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  GroupMembersState copyWith({
    List<GroupMember>? members,
    int? totalMembers,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool clearError = false,
  }) {
    return GroupMembersState(
      members: members ?? this.members,
      totalMembers: totalMembers ?? this.totalMembers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

class GroupMembersNotifier extends StateNotifier<GroupMembersState> {
  GroupMembersNotifier({
    required GroupProfileRepositoryInterface repository,
    required String groupId,
  }) : _repository = repository,
       _groupId = groupId,
       super(const GroupMembersState());

  final GroupProfileRepositoryInterface _repository;
  final String _groupId;
  static const int _limit = 20;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    if (state.isLoading || state.isLoadingMore) return;

    final generation = ++_requestGeneration;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getGroupMembers(
      _groupId,
      skip: 0,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          members: page.members,
          totalMembers: page.totalMembers,
          isLoading: false,
          hasMore: page.hasMore,
          skip: page.members.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final generation = _requestGeneration;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _repository.getGroupMembers(
      _groupId,
      skip: state.skip,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          members: [...state.members, ...page.members],
          totalMembers: page.totalMembers,
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.members.length,
          clearError: true,
        );
      },
    );
  }

  void retry() {
    if (state.members.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }
}

/// True while the group profile members tab is the selected tab.
final groupMembersTabActiveProvider = StateProvider.autoDispose
    .family<bool, String>((ref, groupId) => false);

/// Set when join/unjoin happens while the members tab is not selected.
final groupMembersNeedsRefreshProvider = StateProvider.autoDispose
    .family<bool, String>((ref, groupId) => false);

final groupMembersProvider = StateNotifierProvider.autoDispose
    .family<GroupMembersNotifier, GroupMembersState, String>((ref, groupId) {
  return GroupMembersNotifier(
    repository: ref.watch(groupProfileRepositoryProvider),
    groupId: groupId,
  );
});

final groupEventsProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupEventsPage>, String>((ref, groupId) async {
  final repository = ref.watch(groupProfileRepositoryProvider);
  return repository.getGroupEvents(groupId);
});

final groupEventDetailProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupEvent>, String>((ref, eventId) async {
  final language = ref.watch(contentLanguageProvider);
  final repository = ref.watch(groupProfileRepositoryProvider);
  return repository.getGroupEventDetail(eventId, language: language);
});

final groupEventParticipantsProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupEventParticipantsPage>, String>((
  ref,
  eventId,
) async {
  final repository = ref.watch(groupProfileRepositoryProvider);
  return repository.getGroupEventParticipants(eventId, skip: 0, limit: 20);
});
