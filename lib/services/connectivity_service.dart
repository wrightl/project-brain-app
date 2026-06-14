import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Tracks device connectivity and exposes a simple online/offline flag.
///
/// connectivity_plus reports the available transport(s); it does not guarantee
/// reachability, but it is enough to surface an offline banner and avoid
/// pointless requests.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;

  /// Whether the device currently has any network transport available.
  bool get isOnline => _isOnline;

  Future<void> init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      logWarning('[ConnectivityService] Initial check failed', e);
    }

    _subscription =
        _connectivity.onConnectivityChanged.listen(_updateStatus, onError: (e) {
      logWarning('[ConnectivityService] Connectivity stream error: $e');
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      logDebug('[ConnectivityService] Online: $_isOnline');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
