import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recitations_repository.dart';
import '../../data/datasource/recitations_remote_datasource.dart';
import '../../data/models/recitation_model.dart';
import '../../data/models/recitation_content_model.dart';

// Params class for recitation content
class RecitationContentParams {
  final String textId;
  final List<String>? recitations;
  final List<String>? translations;
  final List<String>? transliterations;
  final List<String>? adaptations;

  const RecitationContentParams({
    required this.textId,
    this.recitations,
    this.translations,
    this.transliterations,
    this.adaptations,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecitationContentParams &&
          runtimeType == other.runtimeType &&
          textId == other.textId;

  @override
  int get hashCode => textId.hashCode;
}

// Repository provider
final recitationsRepositoryProvider = Provider<RecitationsRepository>((ref) {
  return RecitationsRepository(
    recitationsRemoteDatasource: RecitationsRemoteDatasource(
      client: ref.watch(apiClientProvider),
    ),
  );
});

// Get all recitations provider
final recitationsFutureProvider = FutureProvider<List<RecitationModel>>((ref) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref
      .watch(recitationsRepositoryProvider)
      .getRecitations(language: languageCode);
});

// Get saved recitations provider
final savedRecitationsFutureProvider = FutureProvider<List<RecitationModel>>((
  ref,
) {
  return ref.watch(recitationsRepositoryProvider).getSavedRecitations();
});

// Get recitation content by ID
final recitationContentProvider =
    FutureProvider.family<RecitationContentModel, RecitationContentParams>((
      ref,
      params,
    ) {
      final locale = ref.watch(localeProvider);
      final languageCode = locale.languageCode;
      return ref
          .watch(recitationsRepositoryProvider)
          .getRecitationContent(
            params.textId,
            languageCode,
            params.recitations,
            params.translations,
            params.transliterations,
            params.adaptations,
          );
    });

// Search recitations provider
final searchRecitationsProvider =
    FutureProvider.family<List<RecitationModel>, String>((ref, searchQuery) {
      final locale = ref.watch(localeProvider);
      final languageCode = locale.languageCode;
      return ref
          .watch(recitationsRepositoryProvider)
          .getRecitations(language: languageCode, searchQuery: searchQuery);
    });
