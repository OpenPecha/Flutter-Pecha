import 'package:flutter_pecha/core/cache/cache.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/texts/data/datasource/collections_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections_response.dart';

class CollectionsRepository {
  final CollectionsRemoteDatasource remoteDatasource;
  final CacheService _cacheService = CacheService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final AppLogger _logger = AppLogger('CollectionsRepository');

  /// Track in-progress background refreshes to prevent duplicate requests
  final Set<String> _pendingRefreshes = {};

  CollectionsRepository({required this.remoteDatasource});

  /// Get collections with cache-first strategy and offline support.
  ///
  /// 1. Check cache first - return immediately if fresh
  /// 2. If stale, return cached data but refresh in background
  /// 3. If miss/expired, fetch from network
  /// 4. If offline, return cached data even if expired
  ///
  /// Set [forceRefresh] to true to bypass cache (e.g., for pull-to-refresh).
  Future<CollectionsResponse> getCollections({
    String? parentId,
    String? language,
    bool forceRefresh = false,
  }) async {
    final cacheKey = CacheKeys.collectionList(language ?? 'en');
    final isOnline = _connectivityService.isOnline;

    try {
      // Skip cache if force refresh requested AND we're online
      if (!forceRefresh || !isOnline) {
        final cacheResult = _cacheService.get<CollectionsResponse>(
          key: cacheKey,
          box: _cacheService.collectionListBox,
          fromJson: CollectionsResponse.fromJson,
          ignoreExpiry: !isOnline,
        );

        if (cacheResult.isHit && cacheResult.data != null) {
          _logger.debug(
            'Collections cache hit (offline: ${!isOnline})',
          );

          // If stale and online, refresh in background
          if (cacheResult.needsRefresh && isOnline) {
            _refreshInBackground(parentId, language, cacheKey);
          }

          return cacheResult.data!;
        }
      }

      // If offline and no cache, throw offline exception
      if (!isOnline) {
        throw const OfflineException(
          'No internet connection and no cached collections available',
        );
      }

      // Cache miss or force refresh - fetch from network
      _logger.debug(
        forceRefresh
            ? 'Force refreshing collections from network'
            : 'Collections cache miss',
      );
      return await _fetchAndCache(parentId, language, cacheKey);
    } catch (e) {
      // If network fails, try to return cached data (even expired)
      if (e is! OfflineException) {
        final fallbackCache = _cacheService.get<CollectionsResponse>(
          key: cacheKey,
          box: _cacheService.collectionListBox,
          fromJson: CollectionsResponse.fromJson,
          ignoreExpiry: true,
        );

        if (fallbackCache.isHit && fallbackCache.data != null) {
          _logger.debug('Returning fallback cache after network error');
          return fallbackCache.data!;
        }
      }

      _logger.error('Error fetching collections', e);
      if (e is OfflineException) rethrow;
      throw Exception('Failed to load collections: $e');
    }
  }

  Future<CollectionsResponse> _fetchAndCache(
    String? parentId,
    String? language,
    String cacheKey,
  ) async {
    final result = await remoteDatasource.fetchCollections(
      parentId: parentId,
      language: language,
    );

    await _cacheService.put<CollectionsResponse>(
      key: cacheKey,
      box: _cacheService.collectionListBox,
      data: result,
      toJson: (r) => r.toJson(),
      ttl: CacheConfig.collectionListTtl,
      maxItems: CacheConfig.maxTextCacheItems,
    );

    return result;
  }

  void _refreshInBackground(
    String? parentId,
    String? language,
    String cacheKey,
  ) {
    if (_pendingRefreshes.contains(cacheKey)) {
      _logger.debug('Background refresh already in progress for collections');
      return;
    }

    _pendingRefreshes.add(cacheKey);

    Future(() async {
      try {
        await _fetchAndCache(parentId, language, cacheKey);
        _logger.debug('Background collections refresh completed');
      } catch (e) {
        _logger.error('Background collections refresh failed', e);
      } finally {
        _pendingRefreshes.remove(cacheKey);
      }
    });
  }
}
