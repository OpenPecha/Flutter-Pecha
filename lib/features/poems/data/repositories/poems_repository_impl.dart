import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/poems/data/datasource/poems_remote_datasource.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poems_page.dart';
import 'package:flutter_pecha/features/poems/domain/repositories/poems_repository.dart';

class PoemsRepositoryImpl implements PoemsRepositoryInterface {
  PoemsRepositoryImpl({required this.remote});

  final PoemsRemoteDatasource remote;

  @override
  Future<Either<Failure, PoemsPage>> getPoems({
    required String language,
    int skip = 0,
    int limit = 20,
    String? chapterName,
    String? authorName,
  }) async {
    try {
      final result = await remote.fetchPoems(
        language: language,
        skip: skip,
        limit: limit,
        chapterName: chapterName,
        authorName: authorName,
      );
      return Right(
        PoemsPage(
          poems: result.poems.map((m) => m.toEntity()).toList(),
          skip: skip,
          limit: limit,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      return Left(_toFailure(e, 'Failed to get poems'));
    }
  }

  @override
  Future<Either<Failure, Poem>> getPoem(String poemId) async {
    try {
      final model = await remote.fetchPoem(poemId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to get poem'));
    }
  }

  Failure _toFailure(Object error, String fallback) {
    if (error is ServerException) return ServerFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is ValidationException) return ValidationFailure(error.message);
    if (error is RateLimitException) return RateLimitFailure(error.message);
    return UnknownFailure('$fallback: $error');
  }
}
