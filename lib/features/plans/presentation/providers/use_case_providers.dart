import 'dart:async';

import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plan_days_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_local_datasource.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/datasource/user_plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/repositories/plan_days_repository.dart';
import 'package:flutter_pecha/features/plans/data/repositories/plans_repository_impl.dart';
import 'package:flutter_pecha/features/plans/data/repositories/user_plans_repository.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plan_days_repository.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plans_repository.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/user_plans_repository.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plan_days_usecases.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plans_usecases.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/user_plans_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Datasource Providers ==========

final plansLocalDatasourceProvider = Provider<PlansLocalDatasource>((ref) {
  return PlansLocalDatasource();
});

final plansRemoteDatasourceProvider = Provider<PlansRemoteDatasource>((ref) {
  return PlansRemoteDatasource(dio: ref.watch(dioProvider));
});

final userPlansRemoteDatasourceProvider =
    Provider<UserPlansRemoteDatasource>((ref) {
  return UserPlansRemoteDatasource(dio: ref.watch(dioProvider));
});

final planDaysRemoteDatasourceProvider =
    Provider<PlanDaysRemoteDatasource>((ref) {
  return PlanDaysRemoteDatasource(dio: ref.watch(dioProvider));
});

// ========== Repository Providers ==========

/// Provider for PlansRepository implementation (domain interface).
final plansDomainRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepositoryImpl(
    datasource: ref.watch(plansRemoteDatasourceProvider),
    local: ref.watch(plansLocalDatasourceProvider),
  );
});

/// Provider for UserPlansRepository implementation (domain interface).
final userPlansDomainRepositoryProvider =
    Provider<UserPlansRepositoryInterface>((ref) {
  return UserPlansRepository(
    userPlansRemoteDatasource: ref.watch(userPlansRemoteDatasourceProvider),
    local: ref.watch(plansLocalDatasourceProvider),
  );
});

/// Provider for PlanDaysRepository implementation (domain interface).
final planDaysDomainRepositoryProvider =
    Provider<PlanDaysRepositoryInterface>((ref) {
  return PlanDaysRepository(
    planDaysRemoteDatasource: ref.watch(planDaysRemoteDatasourceProvider),
    local: ref.watch(plansLocalDatasourceProvider),
  );
});

/// Keeps pending local plan writes moving after connectivity returns.
final plansSyncBootstrapProvider = Provider<void>((ref) {
  final subscription = ref
      .watch(connectivityServiceProvider)
      .onConnectivityChanged
      .listen((isOnline) {
        if (isOnline) {
          unawaited(
            ref.read(userPlansDomainRepositoryProvider).flushPendingPlanActions(),
          );
        }
      });
  ref.onDispose(() {
    subscription.cancel();
  });
});

// ========== Plans Use Case Providers ==========

/// Provider for GetPlansUseCase.
final getPlansUseCaseProvider = Provider<GetPlansUseCase>((ref) {
  final repository = ref.watch(plansDomainRepositoryProvider);
  return GetPlansUseCase(repository);
});

/// Provider for GetPlanDetailUseCase.
final getPlanDetailUseCaseProvider = Provider<GetPlanDetailUseCase>((ref) {
  final repository = ref.watch(plansDomainRepositoryProvider);
  return GetPlanDetailUseCase(repository);
});

/// Provider for EnrollInPlanUseCase.
final enrollInPlanUseCaseProvider = Provider<EnrollInPlanUseCase>((ref) {
  final repository = ref.watch(plansDomainRepositoryProvider);
  return EnrollInPlanUseCase(repository);
});

/// Provider for UpdateProgressUseCase.
final updateProgressUseCaseProvider = Provider<UpdateProgressUseCase>((ref) {
  final repository = ref.watch(plansDomainRepositoryProvider);
  return UpdateProgressUseCase(repository);
});

/// Provider for SearchPlansUseCase.
final searchPlansUseCaseProvider = Provider<SearchPlansUseCase>((ref) {
  final repository = ref.watch(plansDomainRepositoryProvider);
  return SearchPlansUseCase(repository);
});

// ========== User Plans Use Case Providers ==========

/// Provider for GetUserPlansUseCase.
final getUserPlansUseCaseProvider = Provider<GetUserPlansUseCase>((ref) {
  return GetUserPlansUseCase(ref.watch(userPlansDomainRepositoryProvider));
});

/// Provider for SubscribeToPlanUseCase.
final subscribeToPlanUseCaseProvider = Provider<SubscribeToPlanUseCase>((ref) {
  return SubscribeToPlanUseCase(ref.watch(userPlansDomainRepositoryProvider));
});

/// Provider for UnsubscribeFromPlanUseCase.
final unsubscribeFromPlanUseCaseProvider =
    Provider<UnsubscribeFromPlanUseCase>((ref) {
  return UnsubscribeFromPlanUseCase(
    ref.watch(userPlansDomainRepositoryProvider),
  );
});

/// Provider for GetUserPlanProgressUseCase.
final getUserPlanProgressUseCaseProvider =
    Provider<GetUserPlanProgressUseCase>((ref) {
  return GetUserPlanProgressUseCase(
    ref.watch(userPlansDomainRepositoryProvider),
  );
});

/// Provider for GetUserPlanDayContentUseCase.
final getUserPlanDayContentUseCaseProvider =
    Provider<GetUserPlanDayContentUseCase>((ref) {
  return GetUserPlanDayContentUseCase(
    ref.watch(userPlansDomainRepositoryProvider),
  );
});

/// Provider for GetPlanDaysCompletionStatusUseCase.
final getPlanDaysCompletionStatusUseCaseProvider =
    Provider<GetPlanDaysCompletionStatusUseCase>((ref) {
  return GetPlanDaysCompletionStatusUseCase(
    ref.watch(userPlansDomainRepositoryProvider),
  );
});

/// Provider for CompleteTaskUseCase.
final completeTaskUseCaseProvider = Provider<CompleteTaskUseCase>((ref) {
  return CompleteTaskUseCase(ref.watch(userPlansDomainRepositoryProvider));
});

/// Provider for CompleteSubTaskUseCase.
final completeSubTaskUseCaseProvider = Provider<CompleteSubTaskUseCase>((ref) {
  return CompleteSubTaskUseCase(ref.watch(userPlansDomainRepositoryProvider));
});

/// Provider for DeleteTaskUseCase.
final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>((ref) {
  return DeleteTaskUseCase(ref.watch(userPlansDomainRepositoryProvider));
});

// ========== Plan Days Use Case Providers ==========

/// Provider for GetPlanDaysUseCase.
final getPlanDaysUseCaseProvider = Provider<GetPlanDaysUseCase>((ref) {
  return GetPlanDaysUseCase(ref.watch(planDaysDomainRepositoryProvider));
});

/// Provider for GetDayContentUseCase.
final getDayContentUseCaseProvider = Provider<GetDayContentUseCase>((ref) {
  return GetDayContentUseCase(ref.watch(planDaysDomainRepositoryProvider));
});
