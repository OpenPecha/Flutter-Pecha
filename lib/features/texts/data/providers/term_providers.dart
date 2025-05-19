// lib/features/texts/data/providers/term_providers.dart
import 'package:flutter_pecha/features/texts/data/datasource/term_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../repositories/term_repository.dart';

final termRepositoryProvider = Provider(
  (ref) => TermRepository(
    remoteDatasource: TermRemoteDatasource(client: http.Client()),
  ),
);

final termListFutureProvider = FutureProvider((ref) {
  return ref.watch(termRepositoryProvider).getTerms();
});
