import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/practice/data/datasource/recitation_collections_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/repositories/recitation_collections_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recitationCollectionsRemoteDatasourceProvider =
    Provider<RecitationCollectionsRemoteDatasource>((ref) {
      return RecitationCollectionsRemoteDatasource(
        dio: ref.watch(dioProvider),
      );
    });

final recitationCollectionsRepositoryProvider =
    Provider<RecitationCollectionsRepository>((ref) {
      return RecitationCollectionsRepository(
        remoteDatasource: ref.watch(
          recitationCollectionsRemoteDatasourceProvider,
        ),
      );
    });
