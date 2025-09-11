import '../datasource/author_remote_datasource.dart';
import '../../models/author_model.dart';

class AuthorRepository {
  final AuthorRemoteDatasource authorRemoteDatasource;

  AuthorRepository({required this.authorRemoteDatasource});

  Future<AuthorModel> getAuthorById(String id) async {
    try {
      return await authorRemoteDatasource.getAuthorById(id);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }
}
