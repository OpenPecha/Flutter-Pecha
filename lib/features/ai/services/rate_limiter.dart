/// Client-side rate limiter using sliding window algorithm
/// Limits the number of requests within a time window
class RateLimiter {
  final int maxRequests;

  final Duration window;

  /// List of timestamps for recent requests
  final List<DateTime> _requestTimestamps = [];

  /// Creates a rate limiter with the specified limits
  ///
  /// [maxRequests] - Maximum requests allowed in the window (default: 10)
  /// [window] - Time window duration (default: 1 minute)
  RateLimiter({
    this.maxRequests = 10,
    this.window = const Duration(minutes: 1),
  });

  /// Removes expired timestamps from the list
  void _cleanupExpiredTimestamps() {
    final cutoff = DateTime.now().subtract(window);
    _requestTimestamps.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }

  /// Checks if a new request can be made without exceeding the rate limit
  bool canMakeRequest() {
    _cleanupExpiredTimestamps();
    return _requestTimestamps.length < maxRequests;
  }

  /// Records a new request timestamp
  /// Call this after successfully initiating a request
  void recordRequest() {
    _cleanupExpiredTimestamps();
    _requestTimestamps.add(DateTime.now());
  }

  /// Returns the remaining number of requests allowed in the current window
  int getRemainingRequests() {
    _cleanupExpiredTimestamps();
    return (maxRequests - _requestTimestamps.length).clamp(0, maxRequests);
  }

  /// Returns the time to wait before the next request can be made
  /// Returns null if a request can be made immediately
  Duration? getWaitTime() {
    _cleanupExpiredTimestamps();

    if (_requestTimestamps.length < maxRequests) {
      return null; // Can make request immediately
    }

    // Find when the oldest request will expire
    if (_requestTimestamps.isNotEmpty) {
      final oldestTimestamp = _requestTimestamps.first;
      final expiresAt = oldestTimestamp.add(window);
      final waitTime = expiresAt.difference(DateTime.now());

      if (waitTime.isNegative) {
        return null; // Already expired, can make request
      }

      return waitTime;
    }

    return null;
  }

  /// Returns a user-friendly message about the rate limit status
  String? getRateLimitMessage() {
    final waitTime = getWaitTime();
    if (waitTime == null) {
      return null;
    }

    final seconds = waitTime.inSeconds;
    if (seconds < 60) {
      return 'Please wait $seconds second${seconds == 1 ? '' : 's'} before sending another message';
    }

    final minutes = (seconds / 60).ceil();
    return 'Please wait $minutes minute${minutes == 1 ? '' : 's'} before sending another message';
  }

  /// Resets the rate limiter, clearing all recorded requests
  void reset() {
    _requestTimestamps.clear();
  }
}
