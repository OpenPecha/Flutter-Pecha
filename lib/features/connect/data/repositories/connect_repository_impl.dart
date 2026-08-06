import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/connect/data/datasource/connect_remote_datasource.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:flutter_pecha/features/connect/domain/repositories/connect_repository.dart';
import 'package:fpdart/fpdart.dart';

class ConnectRepositoryImpl implements ConnectRepository {
  ConnectRepositoryImpl({required this.remote});

  final ConnectRemoteDatasource remote;

  @override
  Future<Either<Failure, DiscoverGroupsPage>> getDiscoverGroups({
    required String language,
    int skip = 0,
    int limit = 20,
    String? search,
  }) async {
    try {
      final page = await remote.fetchDiscoverGroups(
        language: language,
        skip: skip,
        limit: limit,
        search: search,
      );
      return Right(page);
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
      return Left(UnknownFailure('Failed to load discover groups: $e'));
    }
  }

  @override
  Future<Either<Failure, DiscoverGroupsPage>> getMyGroups({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final page = await remote.fetchMyGroups(
        language: language,
        skip: skip,
        limit: limit,
      );
      return Right(page);
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
      return Left(UnknownFailure('Failed to load my groups: $e'));
    }
  }

  @override
  Future<Either<Failure, ConnectPostsPage>> getConnectPosts({
    required bool includeUnfollowed,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final page = await remote.fetchConnectPosts(
        includeUnfollowed: includeUnfollowed,
        skip: skip,
        limit: limit,
      );
      return Right(page);
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
      return Left(UnknownFailure('Failed to load posts: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> likePost(String postId) async {
    try {
      await remote.likePost(postId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to like post: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unlikePost(String postId) async {
    try {
      await remote.unlikePost(postId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to unlike post: $e'));
    }
  }
}
