import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/presentation/providers/poems_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const homePoemsPreviewLimit = 3;

/// Poems are fully public, so — unlike [homeGroupEventsPreviewProvider] —
/// this fetches for guests too.
final homePoemsPreviewProvider = FutureProvider.autoDispose<List<Poem>>((
  ref,
) async {
  final language = ref.watch(contentLanguageProvider);
  final result = await ref
      .read(poemsRepositoryProvider)
      .getPoems(
        language: poemsApiLanguageCode(language),
        skip: 0,
        limit: homePoemsPreviewLimit,
      );
  return result.fold((_) => const [], (page) => page.poems);
});
