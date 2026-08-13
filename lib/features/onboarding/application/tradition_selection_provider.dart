import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_selection_notifier.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_selection_state.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final traditionSelectionProvider =
    StateNotifierProvider.autoDispose<
      TraditionSelectionNotifier,
      TraditionSelectionState
    >((ref) {
      final language = ref.watch(contentLanguageProvider);
      return TraditionSelectionNotifier(
        remoteDatasource: ref.watch(onboardingRemoteDatasourceProvider),
        language: language,
      );
    });
