import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/datasource/my_recitation_collections_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';

class MyRecitationCollectionsRepository {
  final MyRecitationCollectionsRemoteDatasource remoteDatasource;

  MyRecitationCollectionsRepository({required this.remoteDatasource});

  Future<Either<Failure, MyRecitationCollectionImageUploadResponse>>
  uploadImage(File file) async {
    try {
      final result = await remoteDatasource.uploadImage(file);
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to upload collection image'),
      );
    }
  }

  Future<Either<Failure, MyRecitationCollectionModel>> createCollection({
    required String name,
    required String imgUrl,
  }) async {
    try {
      final result = await remoteDatasource.createCollection(
        CreateMyRecitationCollectionRequest(name: name, imgUrl: imgUrl),
      );
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to create collection'),
      );
    }
  }

  Future<Either<Failure, MyRecitationCollectionDetailModel>> getCollectionDetail(
    String collectionId,
  ) async {
    try {
      final result = await remoteDatasource.getCollectionDetail(collectionId);
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to load collection'),
      );
    }
  }

  Future<Either<Failure, AddMyRecitationCollectionItemsResponse>>
  addItemsToCollection({
    required String collectionId,
    required List<String> textIds,
  }) async {
    try {
      final result = await remoteDatasource.addItemsToCollection(
        collectionId: collectionId,
        textIds: textIds,
      );
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to add chants to collection'),
      );
    }
  }

  /// Creates a collection, then adds [textIds] when non-empty.
  Future<Either<Failure, MyRecitationCollectionModel>> createCollectionWithItems({
    required String name,
    required String imgUrl,
    required List<String> textIds,
  }) async {
    final createResult = await createCollection(name: name, imgUrl: imgUrl);

    return createResult.fold(
      (failure) async => Left(failure),
      (collection) async {
        if (textIds.isEmpty) return Right(collection);
        if (collection.id.isEmpty) {
          return const Left(
            ServerFailure('Failed to create collection: missing collection id'),
          );
        }

        final addResult = await addItemsToCollection(
          collectionId: collection.id,
          textIds: textIds,
        );
        return addResult.fold(
          (failure) => Left(
            ServerFailure(
              'Collection was created but chants could not be added: '
              '${failure.message}',
            ),
          ),
          (_) => Right(collection),
        );
      },
    );
  }
}
