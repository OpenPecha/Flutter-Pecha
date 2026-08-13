import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cached onboarding tradition paths for the current content language.
///
/// Prefetched on edit profile so the picker sheet opens without a loading flash.
final traditionOnboardingPathsProvider =
    FutureProvider.autoDispose<List<TraditionPath>>((ref) async {
      final language = ref.watch(contentLanguageProvider);
      return ref
          .read(onboardingRemoteDatasourceProvider)
          .fetchTraditionOnboardingPaths(language: language);
    });
