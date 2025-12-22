import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/cache/cache_service.dart';

/// Provider for accessing the CacheService singleton
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService.instance;
});

/// Provider for cache statistics (useful for debugging)
final cacheStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  return cacheService.getStats();
});

/// Notifier for managing cache operations
class CacheNotifier extends Notifier<void> {
  @override
  void build() {}

  CacheService get _cacheService => ref.read(cacheServiceProvider);

  /// Clear all cached data
  Future<void> clearAllCaches() async {
    await _cacheService.clearAll();
  }

  /// Clear only text content cache
  Future<void> clearTextCache() async {
    await _cacheService.clearBox(_cacheService.textContentBox);
    await _cacheService.clearBox(_cacheService.collectionListBox);
    await _cacheService.clearBox(_cacheService.workListBox);
    await _cacheService.clearBox(_cacheService.textVersionListBox);
    await _cacheService.clearBox(_cacheService.textCommentListBox);
  }

  /// Clear only recitation cache
  Future<void> clearRecitationCache() async {
    await _cacheService.clearBox(_cacheService.recitationContentBox);
    await _cacheService.clearBox(_cacheService.recitationListBox);
    await _cacheService.clearBox(_cacheService.savedRecitationsBox);
  }

  /// Force refresh a specific text (invalidate cache and refetch)
  Future<void> invalidateText(String textId) async {
    final box = _cacheService.textContentBox;
    final keysToDelete = <String>[];

    for (final key in box.keys) {
      if (key.toString().contains(textId)) {
        keysToDelete.add(key.toString());
      }
    }

    for (final key in keysToDelete) {
      await _cacheService.delete(key: key, box: box);
    }
  }

  /// Force refresh a specific recitation content
  Future<void> invalidateRecitationContent(String textId) async {
    final box = _cacheService.recitationContentBox;
    final keysToDelete = <String>[];

    for (final key in box.keys) {
      if (key.toString().contains(textId)) {
        keysToDelete.add(key.toString());
      }
    }

    for (final key in keysToDelete) {
      await _cacheService.delete(key: key, box: box);
    }
  }

  /// Invalidate all recitation lists (useful after save/unsave)
  Future<void> invalidateRecitationLists() async {
    await _cacheService.clearBox(_cacheService.recitationListBox);
  }
}

final cacheNotifierProvider = NotifierProvider<CacheNotifier, void>(
  CacheNotifier.new,
);
