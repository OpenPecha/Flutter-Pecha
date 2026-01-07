import 'dart:convert';

import 'package:flutter_pecha/core/cache/cache_config.dart';

/// Wrapper for cached data with metadata for TTL and LRU tracking.
///
/// This class stores:
/// - The actual cached data (as JSON string)
/// - Timestamp when the data was cached
/// - Last access time for LRU eviction
/// - TTL duration for expiration checking
class CacheEntry {
  /// The cached data serialized as JSON string
  final String data;

  /// When the data was originally cached
  final DateTime cachedAt;

  /// Last time this entry was accessed (for LRU eviction)
  final DateTime lastAccessedAt;

  /// Time-to-live duration for this entry
  final Duration ttl;

  /// Optional server-provided version/etag for future use
  final String? version;

  CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.lastAccessedAt,
    required this.ttl,
    this.version,
  });

  /// Create a new cache entry with current timestamp
  factory CacheEntry.create({
    required String data,
    required Duration ttl,
    String? version,
  }) {
    final now = DateTime.now();
    return CacheEntry(
      data: data,
      cachedAt: now,
      lastAccessedAt: now,
      ttl: ttl,
      version: version,
    );
  }

  /// Check if the cache entry has expired based on TTL
  bool get isExpired {
    final expirationTime = cachedAt.add(ttl);
    return DateTime.now().isAfter(expirationTime);
  }

  /// Check if the cache entry is stale (past threshold but not expired)
  /// Stale entries should be refreshed in background while still being usable.
  /// Stale threshold is calculated as a fraction of this entry's TTL.
  bool get isStale {
    final staleThreshold = CacheConfig.getStaleThreshold(ttl);
    final staleTime = cachedAt.add(staleThreshold);
    return DateTime.now().isAfter(staleTime) && !isExpired;
  }

  /// Check if the cache entry is fresh (not stale, not expired)
  bool get isFresh => !isStale && !isExpired;

  /// Age of the cache entry
  Duration get age => DateTime.now().difference(cachedAt);

  /// Time remaining until expiration
  Duration get timeUntilExpiration {
    final expirationTime = cachedAt.add(ttl);
    final remaining = expirationTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Create a copy with updated last access time
  CacheEntry touch() {
    return CacheEntry(
      data: data,
      cachedAt: cachedAt,
      lastAccessedAt: DateTime.now(),
      ttl: ttl,
      version: version,
    );
  }

  /// Serialize to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'cached_at': cachedAt.toIso8601String(),
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'ttl_seconds': ttl.inSeconds,
      'version': version,
    };
  }

  /// Deserialize from JSON
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'] as String,
      cachedAt: DateTime.parse(json['cached_at'] as String),
      lastAccessedAt: DateTime.parse(json['last_accessed_at'] as String),
      ttl: Duration(seconds: json['ttl_seconds'] as int),
      version: json['version'] as String?,
    );
  }

  /// Serialize the entire entry to a JSON string for Hive storage
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from a JSON string
  factory CacheEntry.fromJsonString(String jsonString) {
    return CacheEntry.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  @override
  String toString() {
    return 'CacheEntry(cachedAt: $cachedAt, age: $age, isExpired: $isExpired, isStale: $isStale)';
  }
}

/// Result of a cache lookup operation
class CacheResult<T> {
  /// The cached data (null if cache miss)
  final T? data;

  /// The cache entry metadata (null if cache miss)
  final CacheEntry? entry;

  /// Whether this was a cache hit
  final bool isHit;

  /// Whether the cached data is stale and should be refreshed
  final bool needsRefresh;

  CacheResult._({
    this.data,
    this.entry,
    required this.isHit,
    required this.needsRefresh,
  });

  /// Cache miss - data not found or expired
  factory CacheResult.miss() {
    return CacheResult._(
      data: null,
      entry: null,
      isHit: false,
      needsRefresh: true,
    );
  }

  /// Cache hit with fresh data
  factory CacheResult.fresh(T data, CacheEntry entry) {
    return CacheResult._(
      data: data,
      entry: entry,
      isHit: true,
      needsRefresh: false,
    );
  }

  /// Cache hit with stale data (use but refresh in background)
  factory CacheResult.stale(T data, CacheEntry entry) {
    return CacheResult._(
      data: data,
      entry: entry,
      isHit: true,
      needsRefresh: true,
    );
  }

  /// Cache hit with expired data (used in offline mode)
  factory CacheResult.expired(T data, CacheEntry entry) {
    return CacheResult._(
      data: data,
      entry: entry,
      isHit: true,
      needsRefresh: true,
    );
  }
}

/// Exception thrown when device is offline and no cached data is available
class OfflineException implements Exception {
  final String message;

  const OfflineException([this.message = 'No internet connection']);

  @override
  String toString() => 'OfflineException: $message';
}

/// Exception thrown when cached data is not available
class NoCachedDataException implements Exception {
  final String message;

  const NoCachedDataException([this.message = 'No cached data available']);

  @override
  String toString() => 'NoCachedDataException: $message';
}

/// Exception thrown when cache operations fail
class CacheException implements Exception {
  final String message;
  final Object? cause;

  const CacheException(this.message, [this.cause]);

  @override
  String toString() =>
      cause != null
          ? 'CacheException: $message ($cause)'
          : 'CacheException: $message';
}
