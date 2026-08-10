import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

bool isUserInGroup(WidgetRef ref, String groupId) {
  if (groupId.isEmpty) return true;

  if (ref.read(pendingUnjoinedGroupIdsProvider).contains(groupId)) {
    return false;
  }

  final pendingJoined = ref.read(pendingJoinedGroupsProvider);
  if (pendingJoined.any((group) => group.id == groupId)) {
    return true;
  }

  final myGroups = ref.read(myGroupsProvider).valueOrNull?.groups ?? const [];
  if (myGroups.any((group) => group.id == groupId)) {
    return true;
  }

  final profileEither = ref.read(groupProfileProvider(groupId)).valueOrNull;
  return profileEither?.fold((_) => false, (profile) => profile.isFollowing) ??
      false;
}

Future<Either<Failure, void>> joinGroupEventEnsuringGroupMembership({
  required WidgetRef ref,
  required GroupEvent event,
}) async {
  final repository = ref.read(groupProfileRepositoryProvider);

  if (event.groupId.isNotEmpty && !isUserInGroup(ref, event.groupId)) {
    final profileResult =
        await ref.read(groupProfileProvider(event.groupId).future);
    final groupProfile = profileResult.fold<GroupProfile?>(
      (_) => null,
      (profile) => profile,
    );

    if (groupProfile == null) {
      return const Left(UnknownFailure('Unable to load group'));
    }

    if (!groupProfile.isFollowing) {
      final joinResult = await repository.followGroup(
        event.groupId,
        groupProfile.groupType,
      );

      final joinFailure = joinResult.fold<Failure?>(
        (failure) => failure,
        (_) => null,
      );
      if (joinFailure != null) {
        return Left(joinFailure);
      }

      final followKey = GroupFollowKey(
        groupId: event.groupId,
        groupType: groupProfile.groupType,
        loadInitialStatus: false,
      );
      ref
          .read(groupFollowProvider(followKey).notifier)
          .markAutoJoinedFromPracticeEnrollment(group: groupProfile);
    }
  }

  return repository.joinGroupEvent(event.id);
}
