import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../repositories/author_repository.dart';
import '../datasource/author_remote_datasource.dart';
import '../../models/author_model.dart';

// Repository provider
final authorRepositoryProvider = Provider<AuthorRepository>((ref) {
  return AuthorRepository(
    authorRemoteDatasource: AuthorRemoteDatasource(client: http.Client()),
  );
});

// Get author by ID provider
final authorByIdFutureProvider = FutureProvider.family<AuthorModel, String>((
  ref,
  id,
) {
  return ref.watch(authorRepositoryProvider).getAuthorById(id);
});

// Author state notifier for managing local state
class AuthorState {
  final List<AuthorModel> authors;
  final bool isLoading;
  final String? errorMessage;

  const AuthorState({
    this.authors = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AuthorState copyWith({
    List<AuthorModel>? authors,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthorState(
      authors: authors ?? this.authors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthorNotifier extends StateNotifier<AuthorState> {
  final AuthorRepository _repository;

  AuthorNotifier(this._repository) : super(const AuthorState());

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authorNotifierProvider =
    StateNotifierProvider<AuthorNotifier, AuthorState>((ref) {
      final repository = ref.watch(authorRepositoryProvider);
      return AuthorNotifier(repository);
    });
