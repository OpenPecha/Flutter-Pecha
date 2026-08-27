import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poems_page.dart';

abstract class PoemsRepositoryInterface {
  /// `GET /poems` — published poems, newest first.
  Future<Either<Failure, PoemsPage>> getPoems({
    required String language,
    int skip = 0,
    int limit = 20,
    String? chapterName,
    String? authorName,
  });

  /// `GET /poems/{poem_id}` — a single published poem.
  Future<Either<Failure, Poem>> getPoem(String poemId);
}
