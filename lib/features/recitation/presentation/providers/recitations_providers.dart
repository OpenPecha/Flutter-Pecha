import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recitations_repository.dart';
import '../../data/datasource/recitations_remote_datasource.dart';
import '../../data/models/recitation_model.dart';
import '../../data/models/recitation_content_model.dart';

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
  return ref.watch(recitationsRepositoryProvider).getRecitations(
    language: languageCode,
  );
});

// Get saved recitations provider
final savedRecitationsFutureProvider = FutureProvider<List<RecitationModel>>((ref) {
  return ref.watch(recitationsRepositoryProvider).getSavedRecitations();
});

// Get recitation content by ID
final recitationContentProvider = FutureProvider.family<RecitationContentModel, String>((
  ref,
  id,
) {
  return ref.watch(recitationsRepositoryProvider).getRecitationContent(id);
});

// Search recitations provider
final searchRecitationsProvider = FutureProvider.family<List<RecitationModel>, String>((
  ref,
  searchQuery,
) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref.watch(recitationsRepositoryProvider).getRecitations(
    language: languageCode,
    searchQuery: searchQuery,
  );
});



