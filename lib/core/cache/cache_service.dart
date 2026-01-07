import 'dart:async';
import 'dart:convert';

import 'package:flutter_pecha/core/cache/cache_config.dart';
import 'package:flutter_pecha/core/cache/cache_entry.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service for managing application cache using Hive.
///
/// Implements:
/// - TTL-based expiration
/// - Stale-while-revalidate pattern
/// - LRU eviction when cache limit is reached
/// - Multiple cache boxes for different data types
class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._();

  final AppLogger _logger = AppLogger('CacheService');

  CacheService._();

  bool _isInitialized = false;

  late Box<String> _collectionListBox;
  late Box<String> _workListBox;
  late Box<String> _textVersionListBox;
  late Box<String> _textCommentListBox;
  late Box<String> _textContentBox;
  late Box<String> _recitationContentBox;
  late Box<String> _recitationListBox;
  late Box<String> _savedRecitationsBox;
  late Box<String> _cacheMetadataBox;

  /// Initialize Hive and open all cache boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      _collectionListBox = await Hive.openBox<String>(
        CacheConfig.collectionListBox,
      );
      _workListBox = await Hive.openBox<String>(CacheConfig.workListBox);
      _textVersionListBox = await Hive.openBox<String>(
        CacheConfig.textVersionListBox,
      );
      _textCommentListBox = await Hive.openBox<String>(
        CacheConfig.textCommentListBox,
      );
      _textContentBox = await Hive.openBox<String>(CacheConfig.textContentBox);
      _recitationContentBox = await Hive.openBox<String>(
        CacheConfig.recitationContentBox,
      );
      _recitationListBox = await Hive.openBox<String>(
        CacheConfig.recitationListBox,
      );
      _savedRecitationsBox = await Hive.openBox<String>(
        CacheConfig.savedRecitationsBox,
      );
      _cacheMetadataBox = await Hive.openBox<String>(
        CacheConfig.cacheMetadataBox,
      );

      _isInitialized = true;
      _logger.info('CacheService initialized successfully');

      // Perform cleanup on startup
      await _cleanupExpiredEntries();
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize CacheService', e, stackTrace);
      rethrow;
    }
  }

  /// Ensure service is initialized before use
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw const CacheException(
        'CacheService not initialized. Call initialize() first.',
      );
    }
  }

  // ============ Generic Cache Operations ============

  /// Get data from cache with TTL and staleness checking
  ///
  /// Set [ignoreExpiry] to true to return cached data even if expired (for offline mode)
  CacheResult<T> get<T>({
    required String key,
    required Box<String> box,
    required T Function(Map<String, dynamic>) fromJson,
    bool ignoreExpiry = false,
  }) {
    _ensureInitialized();

    try {
      final entryJson = box.get(key);
      if (entryJson == null) {
        _logger.debug('Cache miss for key: $key');
        return CacheResult.miss();
      }

      final entry = CacheEntry.fromJsonString(entryJson);

      // Parse the actual data first
      final dataMap = jsonDecode(entry.data) as Map<String, dynamic>;
      final data = fromJson(dataMap);

      // Check if expired (but allow returning expired data if ignoreExpiry)
      if (entry.isExpired) {
        if (ignoreExpiry) {
          _logger.debug('Returning expired cache for offline mode: $key');
          return CacheResult.expired(data, entry);
        }
        _logger.debug('Cache expired for key: $key');
        return CacheResult.miss();
      }

      // Update last accessed time for LRU (fire-and-forget, not critical for data integrity)
      unawaited(box.put(key, entry.touch().toJsonString()));

      if (entry.isStale) {
        _logger.debug('Cache stale for key: $key (age: ${entry.age})');
        return CacheResult.stale(data, entry);
      }

      _logger.debug('Cache hit for key: $key (age: ${entry.age})');
      return CacheResult.fresh(data, entry);
    } catch (e, stackTrace) {
      _logger.error('Error reading cache for key: $key', e, stackTrace);
      return CacheResult.miss();
    }
  }

  /// Get a list from cache
  ///
  /// Set [ignoreExpiry] to true to return cached data even if expired (for offline mode)
  CacheResult<List<T>> getList<T>({
    required String key,
    required Box<String> box,
    required T Function(Map<String, dynamic>) fromJson,
    bool ignoreExpiry = false,
  }) {
    _ensureInitialized();

    try {
      final entryJson = box.get(key);
      if (entryJson == null) {
        return CacheResult.miss();
      }

      final entry = CacheEntry.fromJsonString(entryJson);

      // Parse the data first
      final dataList = jsonDecode(entry.data) as List<dynamic>;
      final data =
          dataList
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList();

      // Check expiration (but allow returning expired data if ignoreExpiry)
      if (entry.isExpired) {
        if (ignoreExpiry) {
          _logger.debug('Returning expired cache for offline mode: $key');
          return CacheResult.expired(data, entry);
        }
        return CacheResult.miss();
      }

      // Update last accessed time for LRU (fire-and-forget, not critical for data integrity)
      unawaited(box.put(key, entry.touch().toJsonString()));

      if (entry.isStale) {
        return CacheResult.stale(data, entry);
      }

      return CacheResult.fresh(data, entry);
    } catch (e, stackTrace) {
      _logger.error('Error reading list cache for key: $key', e, stackTrace);
      return CacheResult.miss();
    }
  }

  /// Put data into cache with TTL
  Future<void> put<T>({
    required String key,
    required Box<String> box,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
    required Duration ttl,
    required int maxItems,
    String? version,
  }) async {
    _ensureInitialized();

    try {
      final dataJson = jsonEncode(toJson(data));
      final entry = CacheEntry.create(
        data: dataJson,
        ttl: ttl,
        version: version,
      );

      await box.put(key, entry.toJsonString());
      _logger.debug('Cached data for key: $key (ttl: $ttl)');

      // Check if we need to evict old entries
      await _evictIfNeeded(box, maxItems);
    } catch (e, stackTrace) {
      _logger.error('Error caching data for key: $key', e, stackTrace);
    }
  }

  /// Put a list into cache
  Future<void> putList<T>({
    required String key,
    required Box<String> box,
    required List<T> data,
    required Map<String, dynamic> Function(T) toJson,
    required Duration ttl,
    required int maxItems,
    String? version,
  }) async {
    _ensureInitialized();

    try {
      final dataJson = jsonEncode(data.map(toJson).toList());
      final entry = CacheEntry.create(
        data: dataJson,
        ttl: ttl,
        version: version,
      );

      await box.put(key, entry.toJsonString());
      _logger.debug('Cached list for key: $key (items: ${data.length})');

      await _evictIfNeeded(box, maxItems);
    } catch (e, stackTrace) {
      _logger.error('Error caching list for key: $key', e, stackTrace);
    }
  }

  /// Delete a specific cache entry
  Future<void> delete({required String key, required Box<String> box}) async {
    _ensureInitialized();
    await box.delete(key);
    _logger.debug('Deleted cache entry: $key');
  }

  /// Check if a key exists and is valid (not expired)
  bool hasValidCache({required String key, required Box<String> box}) {
    _ensureInitialized();

    try {
      final entryJson = box.get(key);
      if (entryJson == null) return false;

      final entry = CacheEntry.fromJsonString(entryJson);
      return !entry.isExpired;
    } catch (e) {
      return false;
    }
  }

  // ============ Box Accessors ============

  Box<String> get collectionListBox {
    _ensureInitialized();
    return _collectionListBox;
  }

  Box<String> get workListBox {
    _ensureInitialized();
    return _workListBox;
  }

  Box<String> get textVersionListBox {
    _ensureInitialized();
    return _textVersionListBox;
  }

  Box<String> get textCommentListBox {
    _ensureInitialized();
    return _textCommentListBox;
  }

  Box<String> get textContentBox {
    _ensureInitialized();
    return _textContentBox;
  }

  Box<String> get recitationContentBox {
    _ensureInitialized();
    return _recitationContentBox;
  }

  Box<String> get recitationListBox {
    _ensureInitialized();
    return _recitationListBox;
  }

  Box<String> get savedRecitationsBox {
    _ensureInitialized();
    return _savedRecitationsBox;
  }

  // ============ LRU Eviction ============

  /// Evict least recently used entries if cache exceeds max items
  Future<void> _evictIfNeeded(Box<String> box, int maxItems) async {
    if (box.length <= maxItems) return;

    try {
      // Get all entries with their last access times
      final entries = <String, DateTime>{};

      for (final key in box.keys) {
        try {
          final entryJson = box.get(key);
          if (entryJson != null) {
            final entry = CacheEntry.fromJsonString(entryJson);
            entries[key as String] = entry.lastAccessedAt;
          }
        } catch (e) {
          // Invalid entry, mark for deletion
          entries[key as String] = DateTime(1970);
        }
      }

      // Sort by last accessed time (oldest first)
      final sortedKeys =
          entries.keys.toList()
            ..sort((a, b) => entries[a]!.compareTo(entries[b]!));

      // Delete oldest entries until we're under the limit
      final toDelete = box.length - maxItems;
      for (var i = 0; i < toDelete && i < sortedKeys.length; i++) {
        await box.delete(sortedKeys[i]);
        _logger.debug('LRU evicted: ${sortedKeys[i]}');
      }
    } catch (e, stackTrace) {
      _logger.error('Error during LRU eviction', e, stackTrace);
    }
  }

  // ============ Cleanup ============

  /// Remove all expired entries from all boxes
  Future<void> _cleanupExpiredEntries() async {
    await _cleanupBox(_collectionListBox);
    await _cleanupBox(_workListBox);
    await _cleanupBox(_textVersionListBox);
    await _cleanupBox(_textCommentListBox);
    await _cleanupBox(_textContentBox);
    await _cleanupBox(_recitationContentBox);
    await _cleanupBox(_recitationListBox);
    await _cleanupBox(_savedRecitationsBox);
    _logger.info('Cache cleanup completed');
  }

  Future<void> _cleanupBox(Box<String> box) async {
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      try {
        final entryJson = box.get(key);
        if (entryJson != null) {
          final entry = CacheEntry.fromJsonString(entryJson);
          if (entry.isExpired) {
            keysToDelete.add(key);
          }
        }
      } catch (e) {
        // Invalid entry, delete it
        keysToDelete.add(key);
      }
    }

    for (final key in keysToDelete) {
      await box.delete(key);
    }

    if (keysToDelete.isNotEmpty) {
      _logger.debug(
        'Cleaned up ${keysToDelete.length} expired entries from ${box.name}',
      );
    }
  }

  /// Clear all caches (useful for logout or debug)
  Future<void> clearAll() async {
    _ensureInitialized();

    await _collectionListBox.clear();
    await _workListBox.clear();
    await _textVersionListBox.clear();
    await _textCommentListBox.clear();
    await _textContentBox.clear();
    await _recitationContentBox.clear();
    await _recitationListBox.clear();
    await _savedRecitationsBox.clear();
    await _cacheMetadataBox.clear();

    _logger.info('All caches cleared');
  }

  /// Clear user-specific caches (call on logout)
  Future<void> clearUserData() async {
    _ensureInitialized();

    await _savedRecitationsBox.clear();
    _logger.info('User-specific caches cleared');
  }

  /// Clear specific cache box
  Future<void> clearBox(Box<String> box) async {
    await box.clear();
    _logger.info('Cache box ${box.name} cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    _ensureInitialized();

    return {
      'collection_list_items': _collectionListBox.length,
      'work_list_items': _workListBox.length,
      'text_version_list_items': _textVersionListBox.length,
      'text_comment_list_items': _textCommentListBox.length,
      'text_content_items': _textContentBox.length,
      'recitation_content_items': _recitationContentBox.length,
      'recitation_list_items': _recitationListBox.length,
      'saved_recitations_items': _savedRecitationsBox.length,
      'is_initialized': _isInitialized,
    };
  }
}
