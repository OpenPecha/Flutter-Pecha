import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_local_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider for local datasource
final onboardingLocalDatasourceProvider = Provider<OnboardingLocalDatasource>((
  ref,
) {
  final preferencesService = ref.watch(preferencesServiceProvider);
  return OnboardingLocalDatasource(preferencesService: preferencesService);
});

/// Provider for remote datasource
final onboardingRemoteDatasourceProvider = Provider<OnboardingRemoteDatasource>(
  (ref) {
    final client = ref.watch(apiClientProvider);
    return OnboardingRemoteDatasource(client: client);
  },
);

/// Provider for repository
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final localDatasource = ref.watch(onboardingLocalDatasourceProvider);
  final remoteDatasource = ref.watch(onboardingRemoteDatasourceProvider);
  return OnboardingRepository(
    localDatasource: localDatasource,
    remoteDatasource: remoteDatasource,
  );
});
