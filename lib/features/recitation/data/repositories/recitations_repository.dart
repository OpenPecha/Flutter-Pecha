import 'package:flutter_pecha/core/cache/cache.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_content_model.dart';
import '../datasource/recitations_remote_datasource.dart';

class RecitationsRepository {
  final RecitationsRemoteDatasource recitationsRemoteDatasource;
  final CacheService _cacheService = CacheService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final AppLogger _logger = AppLogger('RecitationsRepository');

  /// Track in-progress background refreshes to prevent duplicate requests
  final Set<String> _pendingRefreshes = {};

  RecitationsRepository({required this.recitationsRemoteDatasource});

  /// Get recitations with cache-first strategy and offline support.
  ///
  /// 1. Check cache first - return immediately if fresh
  /// 2. If stale, return cached data but refresh in background
  /// 3. If miss/expired, fetch from network
  /// 4. If offline, return cached data even if expired
  ///
  /// Set [forceRefresh] to true to bypass cache (e.g., for pull-to-refresh).
  Future<List<RecitationModel>> getRecitations({
    required String language,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    final cacheKey = CacheKeys.recitationList(language, searchQuery);
    final isOnline = _connectivityService.isOnline;

    try {
      // Skip cache if force refresh requested AND we're online
      if (!forceRefresh || !isOnline) {
        final cacheResult = _cacheService.getList<RecitationModel>(
          key: cacheKey,
          box: _cacheService.recitationListBox,
          fromJson: RecitationModel.fromJson,
          ignoreExpiry: !isOnline, // Return expired data if offline
        );

        if (cacheResult.isHit && cacheResult.data != null) {
          _logger.debug(
            'Recitation list cache hit for: $cacheKey (offline: ${!isOnline})',
          );

          // If stale and online, refresh in background
          if (cacheResult.needsRefresh && isOnline) {
            _refreshRecitationsInBackground(language, searchQuery, cacheKey);
          }

          return cacheResult.data!;
        }
      }

      // If offline and no cache, throw offline exception
      if (!isOnline) {
        throw const OfflineException(
          'No internet connection and no cached recitations available',
        );
      }

      // Cache miss or force refresh - fetch from network
      _logger.debug(
        forceRefresh
            ? 'Force refreshing recitations from network'
            : 'Recitation list cache miss, fetching from network',
      );
      return await _fetchAndCacheRecitations(language, searchQuery, cacheKey);
    } catch (e) {
      // If network fails, try to return cached data (even expired)
      if (e is! OfflineException) {
        final fallbackCache = _cacheService.getList<RecitationModel>(
          key: cacheKey,
          box: _cacheService.recitationListBox,
          fromJson: RecitationModel.fromJson,
          ignoreExpiry: true,
        );

        if (fallbackCache.isHit && fallbackCache.data != null) {
          _logger.debug('Returning fallback cache after network error');
          return fallbackCache.data!;
        }
      }

      _logger.error('Error getting recitations', e);
      if (e is OfflineException) rethrow;
      throw Exception('Unable to load recitations: $e');
    }
  }

  Future<List<RecitationModel>> _fetchAndCacheRecitations(
    String language,
    String? searchQuery,
    String cacheKey,
  ) async {
    final recitations = await recitationsRemoteDatasource.fetchRecitations(
      queryParams: RecitationsQueryParams(
        language: language,
        search: searchQuery,
      ),
    );

    // Cache the result
    await _cacheService.putList<RecitationModel>(
      key: cacheKey,
      box: _cacheService.recitationListBox,
      data: recitations,
      toJson: (r) => r.toJson(),
      ttl: CacheConfig.recitationListTtl,
      maxItems: CacheConfig.maxRecitationCacheItems,
    );

    return recitations;
  }

  void _refreshRecitationsInBackground(
    String language,
    String? searchQuery,
    String cacheKey,
  ) {
    // Prevent duplicate background refreshes for the same key
    if (_pendingRefreshes.contains(cacheKey)) {
      _logger.debug('Background refresh already in progress for: $cacheKey');
      return;
    }

    _pendingRefreshes.add(cacheKey);

    // Fire and forget - refresh cache in background
    Future(() async {
      try {
        await _fetchAndCacheRecitations(language, searchQuery, cacheKey);
        _logger.debug('Background refresh completed for: $cacheKey');
      } catch (e) {
        _logger.error('Background refresh failed for: $cacheKey', e);
      } finally {
        _pendingRefreshes.remove(cacheKey);
      }
    });
  }

  /// Get user's saved recitations with cache-first strategy and offline support.
  ///
  /// This is user-specific data cached separately from the general list.
  /// Cache is invalidated when save/unsave operations occur.
  /// Set [forceRefresh] to true to bypass cache (e.g., for pull-to-refresh).
  Future<List<RecitationModel>> getSavedRecitations({
    bool forceRefresh = false,
  }) async {
    const cacheKey = CacheKeys.savedRecitations;
    final isOnline = _connectivityService.isOnline;

    try {
      // Skip cache if force refresh requested AND we're online
      if (!forceRefresh || !isOnline) {
        final cacheResult = _cacheService.getList<RecitationModel>(
          key: cacheKey,
          box: _cacheService.savedRecitationsBox,
          fromJson: RecitationModel.fromJson,
          ignoreExpiry: !isOnline, // Return expired data if offline
        );

        if (cacheResult.isHit && cacheResult.data != null) {
          _logger.debug('Saved recitations cache hit (offline: ${!isOnline})');

          // If stale and online, refresh in background
          if (cacheResult.needsRefresh && isOnline) {
            _refreshSavedRecitationsInBackground();
          }

          return cacheResult.data!;
        }
      }

      // If offline and no cache, throw offline exception
      if (!isOnline) {
        throw const OfflineException(
          'No internet connection and no cached saved recitations',
        );
      }

      // Cache miss or force refresh - fetch from network
      _logger.debug(
        forceRefresh
            ? 'Force refreshing saved recitations'
            : 'Saved recitations cache miss',
      );
      return await _fetchAndCacheSavedRecitations();
    } catch (e) {
      // If network fails, try to return cached data (even expired)
      if (e is! OfflineException) {
        final fallbackCache = _cacheService.getList<RecitationModel>(
          key: cacheKey,
          box: _cacheService.savedRecitationsBox,
          fromJson: RecitationModel.fromJson,
          ignoreExpiry: true,
        );

        if (fallbackCache.isHit && fallbackCache.data != null) {
          _logger.debug('Returning fallback cache after network error');
          return fallbackCache.data!;
        }
      }

      _logger.error('Error getting saved recitations', e);
      if (e is OfflineException) rethrow;
      throw Exception('Failed to load saved recitations: $e');
    }
  }

  Future<List<RecitationModel>> _fetchAndCacheSavedRecitations() async {
    final recitations =
        await recitationsRemoteDatasource.fetchSavedRecitations();

    // Sort by display_order, treating null as highest value
    recitations.sort((a, b) {
      final orderA = a.displayOrder ?? double.maxFinite.toInt();
      final orderB = b.displayOrder ?? double.maxFinite.toInt();
      return orderA.compareTo(orderB);
    });

    // Cache the sorted result
    await _cacheService.putList<RecitationModel>(
      key: CacheKeys.savedRecitations,
      box: _cacheService.savedRecitationsBox,
      data: recitations,
      toJson: (r) => r.toJson(),
      ttl: CacheConfig.savedRecitationsTtl,
      maxItems: 1, // Only one entry for saved recitations list
    );

    return recitations;
  }

  void _refreshSavedRecitationsInBackground() {
    const cacheKey = CacheKeys.savedRecitations;

    // Prevent duplicate background refreshes
    if (_pendingRefreshes.contains(cacheKey)) {
      _logger.debug('Background refresh already in progress for saved recitations');
      return;
    }

    _pendingRefreshes.add(cacheKey);

    Future(() async {
      try {
        await _fetchAndCacheSavedRecitations();
        _logger.debug('Background refresh completed for saved recitations');
      } catch (e) {
        _logger.error('Background refresh failed for saved recitations', e);
      } finally {
        _pendingRefreshes.remove(cacheKey);
      }
    });
  }

  /// Invalidate saved recitations cache (call after save/unsave operations)
  Future<void> _invalidateSavedRecitationsCache() async {
    await _cacheService.delete(
      key: CacheKeys.savedRecitations,
      box: _cacheService.savedRecitationsBox,
    );
    _logger.debug('Saved recitations cache invalidated');
  }

  /// Get recitation content with cache-first strategy and offline support.
  ///
  /// Content is cached based on textId and requested language variants.
  /// Set [forceRefresh] to true to bypass cache (e.g., for pull-to-refresh).
  Future<RecitationContentModel> getRecitationContent(
    String id,
    String language,
    List<String>? recitations,
    List<String>? translations,
    List<String>? transliterations,
    List<String>? adaptations, {
    bool forceRefresh = false,
  }) async {
    // Build cache key from all language parameters
    final languageVariants = <String>[
      ...?recitations,
      ...?translations,
      ...?transliterations,
      ...?adaptations,
    ];
    final cacheKey = CacheKeys.recitationContent(id, languageVariants);
    final isOnline = _connectivityService.isOnline;

    try {
      // Skip cache if force refresh requested AND we're online
      if (!forceRefresh || !isOnline) {
        final cacheResult = _cacheService.get<RecitationContentModel>(
          key: cacheKey,
          box: _cacheService.recitationContentBox,
          fromJson: RecitationContentModel.fromJson,
          ignoreExpiry: !isOnline, // Return expired data if offline
        );

        if (cacheResult.isHit && cacheResult.data != null) {
          _logger.debug(
            'Recitation content cache hit for: $id (offline: ${!isOnline})',
          );

          // If stale and online, refresh in background
          if (cacheResult.needsRefresh && isOnline) {
            _refreshContentInBackground(
              id,
              language,
              recitations,
              translations,
              transliterations,
              adaptations,
              cacheKey,
            );
          }

          return cacheResult.data!;
        }
      }

      // If offline and no cache, throw offline exception
      if (!isOnline) {
        throw const OfflineException(
          'No internet connection and no cached content available',
        );
      }

      // Cache miss or force refresh - fetch from network
      _logger.debug(
        forceRefresh
            ? 'Force refreshing recitation content from network'
            : 'Recitation content cache miss for: $id',
      );
      return await _fetchAndCacheContent(
        id,
        language,
        recitations,
        translations,
        transliterations,
        adaptations,
        cacheKey,
      );
    } catch (e) {
      // If network fails, try to return cached data (even expired)
      if (e is! OfflineException) {
        final fallbackCache = _cacheService.get<RecitationContentModel>(
          key: cacheKey,
          box: _cacheService.recitationContentBox,
          fromJson: RecitationContentModel.fromJson,
          ignoreExpiry: true,
        );

        if (fallbackCache.isHit && fallbackCache.data != null) {
          _logger.debug('Returning fallback cache after network error');
          return fallbackCache.data!;
        }
      }

      _logger.error('Error getting recitation content', e);
      if (e is OfflineException) rethrow;
      throw Exception('Failed to load recitation content: $e');
    }
  }

  Future<RecitationContentModel> _fetchAndCacheContent(
    String id,
    String language,
    List<String>? recitations,
    List<String>? translations,
    List<String>? transliterations,
    List<String>? adaptations,
    String cacheKey,
  ) async {
    final content = await recitationsRemoteDatasource.fetchRecitationContent(
      id,
      recitation: recitations,
      language: language,
      translations: translations,
      transliterations: transliterations,
      adaptations: adaptations,
    );

    // Cache the result
    await _cacheService.put<RecitationContentModel>(
      key: cacheKey,
      box: _cacheService.recitationContentBox,
      data: content,
      toJson: (c) => c.toJson(),
      ttl: CacheConfig.recitationContentTtl,
      maxItems: CacheConfig.maxRecitationCacheItems,
    );

    return content;
  }

  void _refreshContentInBackground(
    String id,
    String language,
    List<String>? recitations,
    List<String>? translations,
    List<String>? transliterations,
    List<String>? adaptations,
    String cacheKey,
  ) {
    // Prevent duplicate background refreshes for the same key
    if (_pendingRefreshes.contains(cacheKey)) {
      _logger.debug('Background refresh already in progress for content: $id');
      return;
    }

    _pendingRefreshes.add(cacheKey);

    Future(() async {
      try {
        await _fetchAndCacheContent(
          id,
          language,
          recitations,
          translations,
          transliterations,
          adaptations,
          cacheKey,
        );
        _logger.debug('Background content refresh completed for: $id');
      } catch (e) {
        _logger.error('Background content refresh failed for: $id', e);
      } finally {
        _pendingRefreshes.remove(cacheKey);
      }
    });
  }

  Future<bool> saveRecitation(String id) async {
    try {
      final result = await recitationsRemoteDatasource.saveRecitation(id);
      if (result) {
        // Invalidate saved recitations cache so next fetch gets updated list
        await _invalidateSavedRecitationsCache();
      }
      return result;
    } catch (e) {
      throw Exception('Failed to save recitation: $e');
    }
  }

  Future<bool> unsaveRecitation(String id) async {
    try {
      final result = await recitationsRemoteDatasource.unsaveRecitation(id);
      if (result) {
        // Invalidate saved recitations cache so next fetch gets updated list
        await _invalidateSavedRecitationsCache();
      }
      return result;
    } catch (e) {
      throw Exception('Failed to unsave recitation: $e');
    }
  }

  Future<bool> updateRecitationsOrder(
    List<Map<String, dynamic>> recitations,
  ) async {
    try {
      final result = await recitationsRemoteDatasource.updateRecitationsOrder(
        recitations,
      );
      if (result) {
        // Invalidate saved recitations cache since order changed
        await _invalidateSavedRecitationsCache();
      }
      return result;
    } catch (e) {
      throw Exception('Failed to update recitations order: $e');
    }
  }
}
