import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// A centralized, environment-aware logging utility for the app.
///
/// This logger:
/// - Only outputs logs in debug mode (not in release builds)
/// - Provides consistent log formatting
/// - Supports multiple log levels (debug, info, warning, error)
/// - Uses the `logging` package under the hood
///
/// Usage:
/// ```dart
/// final _logger = AppLogger('MyClass');
/// _logger.debug('Debug message');
/// _logger.info('Info message');
/// _logger.warning('Warning message');
/// _logger.error('Error message', error, stackTrace);
/// ```
class AppLogger {
  final Logger _logger;

  AppLogger(String name) : _logger = Logger(name);

  /// Initializes the root logger configuration.
  /// Call this once in main() before using any loggers.
  static void init() {
    if (kDebugMode) {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen(_logHandler);
    } else {
      // In release mode, only log severe errors (or disable completely)
      Logger.root.level = Level.OFF;
    }
  }

  static void _logHandler(LogRecord record) {
    // Only log in debug mode
    if (!kDebugMode) return;

    final emoji = _getLogEmoji(record.level);
    final time = _formatTime(record.time);
    final message = '$emoji [${record.level.name}] $time ${record.loggerName}: ${record.message}';

    // Use debugPrint in debug mode - it's throttled and won't overflow
    debugPrint(message);

    if (record.error != null) {
      debugPrint('  Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('  StackTrace: ${record.stackTrace}');
    }
  }

  static String _getLogEmoji(Level level) {
    if (level == Level.SEVERE) return '🔴';
    if (level == Level.WARNING) return '🟡';
    if (level == Level.INFO) return '🔵';
    if (level == Level.CONFIG) return '⚙️';
    if (level == Level.FINE || level == Level.FINER || level == Level.FINEST) {
      return '🟢';
    }
    return '⚪';
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }

  /// Log a debug message (for development only).
  void debug(String message) {
    if (kDebugMode) {
      _logger.fine(message);
    }
  }

  /// Log an info message.
  void info(String message) {
    if (kDebugMode) {
      _logger.info(message);
    }
  }

  /// Log a warning message.
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.warning(message, error, stackTrace);
    }
  }

  /// Log an error message.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.severe(message, error, stackTrace);
    }
  }
}
