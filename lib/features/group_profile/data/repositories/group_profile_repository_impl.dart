import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';

class GroupProfileRepositoryImpl implements GroupProfileRepositoryInterface {
  final GroupProfileRemoteDatasource remote;

  GroupProfileRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, GroupProfile>> getGroupProfile(
    String groupId, {
    required String language,
  }) async {
    try {
      final model = await remote.fetchGroupProfile(groupId, language: language);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load group profile: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkFollowStatus(
    String groupId,
    GroupType groupType,
  ) async {
    try {
      final isFollowing = await remote.checkFollowStatus(groupId, groupType);
      return Right(isFollowing);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure(
          groupType.isPage
              ? 'Failed to check follow status: $e'
              : 'Failed to check join status: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> followGroup(
    String groupId,
    GroupType groupType,
  ) async {
    try {
      await remote.followGroup(groupId, groupType);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure(
          groupType.isPage
              ? 'Failed to follow group: $e'
              : 'Failed to join group: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, GroupMembersPage>> getGroupMembers(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    try {
      final model = await remote.fetchGroupMembers(
        groupId,
        skip: skip,
        limit: limit,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load group members: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEventsPage>> getConnectEvents({
    required bool includeUnfollowed,
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final model = await remote.fetchConnectEvents(
        includeUnfollowed: includeUnfollowed,
        language: language,
        skip: skip,
        limit: limit,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load events: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEventsPage>> getGroupEvents(
    String groupId,
  ) async {
    try {
      final model = await remote.fetchGroupEvents(groupId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load group events: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEvent>> getGroupEventDetail(
    String eventId, {
    required String language,
  }) async {
    try {
      final model = await remote.fetchGroupEventDetail(
        eventId,
        language: language,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load group event: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEventParticipantsPage>> getGroupEventParticipants(
    String eventId, {
    required int skip,
    required int limit,
  }) async {
    try {
      final model = await remote.fetchGroupEventParticipants(
        eventId,
        skip: skip,
        limit: limit,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Failed to load group event participants: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> joinGroupEvent(String eventId) async {
    try {
      await remote.joinGroupEvent(eventId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to attend event: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveGroupEvent(String eventId) async {
    try {
      await remote.leaveGroupEvent(eventId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to leave event: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unfollowGroup(
    String groupId,
    GroupType groupType,
  ) async {
    try {
      await remote.unfollowGroup(groupId, groupType);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure(
          groupType.isPage
              ? 'Failed to unfollow group: $e'
              : 'Failed to leave group: $e',
        ),
      );
    }
  }
}
