import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_api_mapper.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/routine_api_repository.dart';

/// Concrete implementation of [RoutineApiRepository].
///
/// Bridges the [RoutineRemoteDatasource] (raw Dio calls + DTOs) with the
/// domain layer. Responsible for:
///   - Calling the datasource
///   - Mapping API responses to domain-friendly types ([RoutineData])
///   - Catching datasource exceptions and mapping them to typed [Failure]s
class RoutineApiRepositoryImpl implements RoutineApiRepository {
  final RoutineRemoteDatasource _datasource;
  final _logger = AppLogger('RoutineApiRepositoryImpl');

  RoutineApiRepositoryImpl({required RoutineRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Either<Failure, RoutineData?>> getUserRoutine({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _datasource.getUserRoutine(
        language: language,
        skip: skip,
        limit: limit,
      );
      // null response means the backend reported "no routine yet" — not an error
      return Right(routineDataFromApiResponse(response));
    } catch (e, st) {
      _logger.error('Failed to fetch user routine', e, st);
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, ({String routineId, String timeBlockId})>>
      createRoutineWithTimeBlock(TimeBlockRequest request) async {
    try {
      final response = await _datasource.createRoutineWithTimeBlock(request);
      return Right((
        routineId: response.id,
        timeBlockId: response.timeBlocks.first.id,
      ));
    } catch (e, st) {
      _logger.error('Failed to create routine with time block', e, st);
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> createTimeBlock(
    String routineId,
    TimeBlockRequest request,
  ) async {
    try {
      final dto = await _datasource.createTimeBlock(routineId, request);
      return Right(dto.id);
    } catch (e, st) {
      _logger.error('Failed to create time block', e, st);
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateTimeBlock(
    String routineId,
    String timeBlockId,
    TimeBlockRequest request,
  ) async {
    try {
      await _datasource.updateTimeBlock(routineId, timeBlockId, request);
      return const Right(null);
    } catch (e, st) {
      _logger.error('Failed to update time block', e, st);
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTimeBlock(
    String routineId,
    String timeBlockId,
  ) async {
    try {
      await _datasource.deleteTimeBlock(routineId, timeBlockId);
      return const Right(null);
    } catch (e, st) {
      _logger.error('Failed to delete time block', e, st);
      return Left(_toFailure(e));
    }
  }

  // ─── Exception → Failure mapping ───

  Failure _toFailure(Object e) {
    if (e is RoutineAlreadyExistsException) {
      return ValidationFailure(e.message);
    }
    if (e is RoutineTimeConflictException) {
      return ValidationFailure(e.message);
    }
    if (e is RoutineValidationException) {
      return ValidationFailure(e.message);
    }
    if (e is RoutineNotFoundException) {
      return NotFoundFailure(e.message);
    }
    if (e is RoutineApiException) {
      return ServerFailure(e.message);
    }
    // Everything else is a transport/HTTP error already typed by
    // ErrorInterceptor. Delegate instead of collapsing it into one generic
    // message: a 500, an offline device, and an expired session are different
    // failures and callers (and users) need to tell them apart.
    return ExceptionMapper.map(e);
  }
}
