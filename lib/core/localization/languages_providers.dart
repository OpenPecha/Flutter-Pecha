import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/localization/data/languages_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Datasource for the backend content-language list.
final languagesRemoteDatasourceProvider = Provider<LanguagesRemoteDatasource>((
  ref,
) {
  return LanguagesRemoteDatasource(dio: ref.watch(dioProvider));
});

/// Content languages the backend can serve, used to build the language picker.
///
/// Falls back to [AppLanguage.bundledFallback] on any error (offline, first
/// launch, malformed response) so the picker always has something to show. When
/// the backend returns an empty list, the bundled set is used too.
final availableContentLanguagesProvider = FutureProvider<List<AppLanguage>>((
  ref,
) async {
  try {
    final languages =
        await ref.watch(languagesRemoteDatasourceProvider).fetchLanguages();

    // Reaching here means the fetch succeeded, so this is an authoritative
    // answer (an empty list included) — offline/parse errors throw into the
    // catch below. Enforce the server-side kill switch here, before the empty
    // list is ever swapped for the bundled fallback, and keep the UI locale
    // paired with the content language exactly like a normal selection.
    final switched = await ref
        .read(contentLanguageProvider.notifier)
        .reconcileToAvailable(languages.map((l) => l.code).toList());
    if (switched != null) {
      await ref.read(localeProvider.notifier).applyUiLocaleForContent(switched);
    }

    // Show the bundled list only so the picker is never blank; reconciliation
    // above already ran authoritatively regardless of what we display.
    return languages.isNotEmpty ? languages : AppLanguage.bundledFallback;
  } catch (_) {
    // Offline / parse error: keep the stored selection untouched and show the
    // bundled list. Reconciliation deliberately does not run on this path.
    return AppLanguage.bundledFallback;
  }
});

/// Synchronous view of [availableContentLanguagesProvider] for UI that needs a
/// list immediately. Uses the fetched value when ready; otherwise
/// [AppLanguage.bundledFallback] (loading / no value yet).
final resolvedContentLanguagesProvider = Provider<List<AppLanguage>>((ref) {
  return ref.watch(availableContentLanguagesProvider).valueOrNull ??
      AppLanguage.bundledFallback;
});

final recitationContentLanguagesProvider = FutureProvider<List<AppLanguage>>((
  ref,
) async {
  try {
    final languages = await ref
        .watch(languagesRemoteDatasourceProvider)
        .fetchLanguages(recitationOnly: true);

    return languages.isNotEmpty ? languages : AppLanguage.bundledFallback;
  } catch (_) {
    return AppLanguage.bundledFallback;
  }
});

final resolvedRecitationLanguagesProvider = Provider<List<AppLanguage>>((ref) {
  return ref.watch(recitationContentLanguagesProvider).valueOrNull ??
      AppLanguage.bundledFallback;
});
