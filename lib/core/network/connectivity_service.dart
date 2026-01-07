import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for monitoring network connectivity.
///
/// Provides:
/// - Current connectivity status
/// - Stream of connectivity changes
/// - Actual internet reachability check (not just connection type)
class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance =>
      _instance ??= ConnectivityService._();

  final AppLogger _logger = AppLogger('ConnectivityService');
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _connectivityController = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool _isInitialized = false;

  ConnectivityService._();

  /// Whether the device currently has internet connectivity
  bool get isOnline => _isOnline;

  /// Stream of connectivity changes (true = online, false = offline)
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Initialize the connectivity service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check initial connectivity
      final results = await _connectivity.checkConnectivity();
      _isOnline = await _checkActualConnectivity(results);
      _logger.info('Initial connectivity: ${_isOnline ? 'online' : 'offline'}');

      // Listen for changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
      );

      _isInitialized = true;
    } catch (e) {
      _logger.error('Failed to initialize ConnectivityService', e);
      // Assume online if we can't check
      _isOnline = true;
    }
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    final wasOnline = _isOnline;
    _isOnline = await _checkActualConnectivity(results);

    if (wasOnline != _isOnline) {
      _logger.info('Connectivity changed: ${_isOnline ? 'online' : 'offline'}');
      _connectivityController.add(_isOnline);
    }
  }

  /// Check if we actually have internet access, not just a connection type
  Future<bool> _checkActualConnectivity(List<ConnectivityResult> results) async {
    // If no connection at all, we're offline
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }

    // We have a connection type, but verify we can actually reach the internet
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      _logger.error('Error checking internet connectivity', e);
      // If we can't check, assume we're online if we have a connection type
      return true;
    }
  }

  /// Manually check current connectivity (useful before important operations)
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = await _checkActualConnectivity(results);
    return _isOnline;
  }

  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}

// ============ Riverpod Providers ============

/// Provider for the ConnectivityService singleton
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Provider for current online status
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).isOnline;
});

/// StreamProvider for connectivity changes
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  // Emit current status first, then listen for changes
  return Stream.value(service.isOnline)
      .asyncExpand((_) => service.onConnectivityChanged);
});

/// Notifier for managing connectivity state with UI integration
class ConnectivityNotifier extends Notifier<bool> {
  late StreamSubscription<bool> _subscription;

  @override
  bool build() {
    final service = ref.read(connectivityServiceProvider);

    // Listen to connectivity changes
    _subscription = service.onConnectivityChanged.listen((isOnline) {
      state = isOnline;
    });

    // Clean up on dispose
    ref.onDispose(() {
      _subscription.cancel();
    });

    return service.isOnline;
  }

  /// Force check connectivity
  Future<void> refresh() async {
    final service = ref.read(connectivityServiceProvider);
    state = await service.checkConnectivity();
  }
}

final connectivityNotifierProvider =
    NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);
