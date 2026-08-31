import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/poems/data/datasource/poems_remote_datasource.dart';
import 'package:flutter_pecha/features/poems/data/repositories/poems_repository_impl.dart';
import 'package:flutter_pecha/features/poems/domain/repositories/poems_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final poemsRemoteDatasourceProvider = Provider<PoemsRemoteDatasource>((ref) {
  return PoemsRemoteDatasource(dio: ref.watch(dioProvider));
});

final poemsRepositoryProvider = Provider<PoemsRepositoryInterface>((ref) {
  return PoemsRepositoryImpl(remote: ref.watch(poemsRemoteDatasourceProvider));
});

/// The Poems API's `language` query param is an uppercase enum
/// (`EN`, `BO`, `ZH`, `HI`, `NE`, `MN`, `LA`) while [contentLanguageProvider]
/// stores the app's lowercase content code (`en`, `bo`, ...).
String poemsApiLanguageCode(String contentLanguage) =>
    contentLanguage.trim().toUpperCase();

/// True when a poem's in-content title has scrolled out of view and should
/// appear in the viewer top bar instead.
final poemViewerAppBarTitleVisibleProvider = StateProvider.autoDispose
    .family<bool, String>((ref, poemId) => false);
