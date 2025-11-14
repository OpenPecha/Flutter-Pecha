import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_content_model.dart';
import '../datasource/recitations_remote_datasource.dart';

class RecitationsRepository {
  final RecitationsRemoteDatasource recitationsRemoteDatasource;

  RecitationsRepository({required this.recitationsRemoteDatasource});

  Future<List<RecitationModel>> getRecitations({
    required String language,
    String? searchQuery,
  }) async {
    try {
      return await recitationsRemoteDatasource.fetchRecitations(
        queryParams: RecitationsQueryParams(
          language: language,
          search: searchQuery,
        ),
      );
    } catch (e) {
      throw Exception('Unable to load recitations: $e');
    }
  }

  Future<List<RecitationModel>> getSavedRecitations() async {
    try {
      return await recitationsRemoteDatasource.fetchSavedRecitations();
    } catch (e) {
      throw Exception('Failed to load saved recitations: $e');
    }
  }

  Future<RecitationContentModel> getRecitationContent(
    String id,
    String language,
    List<String>? recitations,
    List<String>? translations,
    List<String>? transliterations,
    List<String>? adaptations,
  ) async {
    try {
      return await recitationsRemoteDatasource.fetchRecitationContent(
        id,
        recitation: recitations,
        language: language,
        translations: translations,
        transliterations: transliterations,
        adaptations: adaptations,
      );
    } catch (e) {
      throw Exception('Failed to load recitation content: $e');
    }
  }

  Future<bool> saveRecitation(String id) async {
    try {
      return await recitationsRemoteDatasource.saveRecitation(id);
    } catch (e) {
      throw Exception('Failed to save recitation: $e');
    }
  }

  Future<bool> unsaveRecitation(String id) async {
    try {
      return await recitationsRemoteDatasource.unsaveRecitation(id);
    } catch (e) {
      throw Exception('Failed to unsave recitation: $e');
    }
  }
}
