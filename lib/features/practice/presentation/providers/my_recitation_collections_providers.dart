import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/datasource/my_recitation_collections_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_pecha/features/practice/data/repositories/my_recitation_collections_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final myRecitationCollectionsRemoteDatasourceProvider =
    Provider<MyRecitationCollectionsRemoteDatasource>((ref) {
      return MyRecitationCollectionsRemoteDatasource(
        dio: ref.watch(dioProvider),
      );
    });

final myRecitationCollectionsRepositoryProvider =
    Provider<MyRecitationCollectionsRepository>((ref) {
      return MyRecitationCollectionsRepository(
        remoteDatasource: ref.watch(
          myRecitationCollectionsRemoteDatasourceProvider,
        ),
      );
    });

/// `GET /users/me/recitation-collections/{collectionId}` for the detail screen.
final myRecitationCollectionDetailProvider = FutureProvider.autoDispose
    .family<Either<Failure, MyRecitationCollectionDetailModel>, String>((
      ref,
      collectionId,
    ) {
      return ref
          .watch(myRecitationCollectionsRepositoryProvider)
          .getCollectionDetail(collectionId);
    });
