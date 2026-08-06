import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:fpdart/fpdart.dart';

abstract class ConnectRepository {
  Future<Either<Failure, DiscoverGroupsPage>> getDiscoverGroups({
    required String language,
    int skip = 0,
    int limit = 20,
    String? search,
  });

  Future<Either<Failure, DiscoverGroupsPage>> getMyGroups({
    required String language,
    int skip = 0,
    int limit = 20,
  });

  Future<Either<Failure, ConnectPostsPage>> getConnectPosts({
    required bool includeUnfollowed,
    int skip = 0,
    int limit = 20,
  });

  Future<Either<Failure, void>> likePost(String postId);

  Future<Either<Failure, void>> unlikePost(String postId);
}
