import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/datasource/recitation_collections_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/recitation_collection_models.dart';

class RecitationCollectionsRepository {
  final RecitationCollectionsRemoteDatasource remoteDatasource;

  RecitationCollectionsRepository({required this.remoteDatasource});

  Future<Either<Failure, RecitationCollectionImageUploadResponse>>
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

  Future<Either<Failure, RecitationCollectionModel>> createCollection({
    required String name,
    required String imgUrl,
  }) async {
    try {
      final result = await remoteDatasource.createCollection(
        CreateRecitationCollectionRequest(name: name, imgUrl: imgUrl),
      );
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to create collection'),
      );
    }
  }

  Future<Either<Failure, AddRecitationCollectionItemsResponse>>
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
  Future<Either<Failure, RecitationCollectionModel>> createCollectionWithItems({
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
