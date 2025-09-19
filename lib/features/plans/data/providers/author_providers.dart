import 'package:flutter_pecha/core/network/http_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/author_repository.dart';
import '../datasource/author_remote_datasource.dart';
import '../../models/author_model.dart';

// Repository provider
final authorRepositoryProvider = Provider<AuthorRepository>((ref) {
  return AuthorRepository(
    authorRemoteDatasource: AuthorRemoteDatasource(
      client: ref.watch(httpClientProvider),
    ),
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
  final AuthorRepository repository;
  AuthorNotifier(this.repository) : super(const AuthorState());

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authorNotifierProvider =
    StateNotifierProvider<AuthorNotifier, AuthorState>((ref) {
      final repository = ref.watch(authorRepositoryProvider);
      return AuthorNotifier(repository);
    });
