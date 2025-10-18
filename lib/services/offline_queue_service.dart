import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Request that failed and needs to be retried
class QueuedRequest {
  final String id;
  final String method;
  final String path;
  final String? body;
  final DateTime queuedAt;
  final int retryCount;

  QueuedRequest({
    required this.id,
    required this.method,
    required this.path,
    this.body,
    required this.queuedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'body': body,
        'queuedAt': queuedAt.millisecondsSinceEpoch,
        'retryCount': retryCount,
      };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
        id: json['id'] as String,
        method: json['method'] as String,
        path: json['path'] as String,
        body: json['body'] as String?,
        queuedAt: DateTime.fromMillisecondsSinceEpoch(json['queuedAt'] as int),
        retryCount: json['retryCount'] as int? ?? 0,
      );

  QueuedRequest copyWith({int? retryCount}) => QueuedRequest(
        id: id,
        method: method,
        path: path,
        body: body,
        queuedAt: queuedAt,
        retryCount: retryCount ?? this.retryCount,
      );
}

/// Offline queue service for handling failed requests
class OfflineQueueService {
  static const String _queueBoxName = 'offline_queue';
  static const int maxRetries = 3;
  static const Duration maxQueueAge = Duration(days: 7);

  Box<String>? _queueBox;
  final Connectivity _connectivity = Connectivity();
  bool _isProcessing = false;

  /// Callback for processing queued requests
  Future<bool> Function(QueuedRequest request)? onProcessRequest;

  /// Initialize the offline queue
  Future<void> init() async {
    _queueBox = await Hive.openBox<String>(_queueBoxName);
    logDebug('[OfflineQueue] Initialized with ${_queueBox!.length} queued items');

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      if (result.isNotEmpty && result.first != ConnectivityResult.none) {
        logDebug('[OfflineQueue] Connectivity restored, processing queue');
        processQueue();
      }
    });

    // Clean old items on init
    await _cleanOldItems();
  }

  /// Add a failed request to the queue
  Future<void> enqueue(QueuedRequest request) async {
    if (_queueBox == null) {
      logDebug('[OfflineQueue] Not initialized, skipping enqueue');
      return;
    }

    try {
      await _queueBox!.put(request.id, jsonEncode(request.toJson()));
      logDebug('[OfflineQueue] Queued ${request.method} ${request.path}');
    } catch (e) {
      logDebug('[OfflineQueue] Error enqueuing request: $e');
    }
  }

  /// Process all queued requests
  Future<void> processQueue() async {
    if (_queueBox == null || _isProcessing || onProcessRequest == null) {
      return;
    }

    _isProcessing = true;
    logDebug('[OfflineQueue] Processing queue with ${_queueBox!.length} items');

    try {
      // Check connectivity
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity.isEmpty || connectivity.first == ConnectivityResult.none) {
        logDebug('[OfflineQueue] No connectivity, skipping process');
        _isProcessing = false;
        return;
      }

      final keysToRemove = <String>[];
      final keysToRetry = <String, QueuedRequest>{};

      for (final key in _queueBox!.keys) {
        try {
          final jsonStr = _queueBox!.get(key);
          if (jsonStr == null) continue;

          final request = QueuedRequest.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          );

          // Check if too old
          if (DateTime.now().difference(request.queuedAt) > maxQueueAge) {
            logDebug('[OfflineQueue] Request too old, removing: ${request.id}');
            keysToRemove.add(key as String);
            continue;
          }

          // Check if max retries reached
          if (request.retryCount >= maxRetries) {
            logDebug('[OfflineQueue] Max retries reached, removing: ${request.id}');
            keysToRemove.add(key as String);
            continue;
          }

          // Try to process
          final success = await onProcessRequest!(request);

          if (success) {
            logDebug('[OfflineQueue] Successfully processed: ${request.id}');
            keysToRemove.add(key as String);
          } else {
            logDebug('[OfflineQueue] Failed to process: ${request.id}');
            keysToRetry[key as String] = request.copyWith(
              retryCount: request.retryCount + 1,
            );
          }
        } catch (e) {
          logDebug('[OfflineQueue] Error processing $key: $e');
        }
      }

      // Remove successful requests
      for (final key in keysToRemove) {
        await _queueBox!.delete(key);
      }

      // Update retry counts
      for (final entry in keysToRetry.entries) {
        await _queueBox!.put(
          entry.key,
          jsonEncode(entry.value.toJson()),
        );
      }

      logDebug('[OfflineQueue] Processed queue: ${keysToRemove.length} succeeded, ${keysToRetry.length} retried');
    } catch (e) {
      logDebug('[OfflineQueue] Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Get queue statistics
  Map<String, dynamic> getStats() {
    if (_queueBox == null) {
      return {
        'initialized': false,
        'queuedItems': 0,
      };
    }

    final now = DateTime.now();
    int recentItems = 0;
    int oldItems = 0;

    for (final key in _queueBox!.keys) {
      try {
        final jsonStr = _queueBox!.get(key);
        if (jsonStr == null) continue;

        final request = QueuedRequest.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>,
        );

        if (now.difference(request.queuedAt) < const Duration(hours: 24)) {
          recentItems++;
        } else {
          oldItems++;
        }
      } catch (e) {
        // Skip invalid items
      }
    }

    return {
      'initialized': true,
      'queuedItems': _queueBox!.length,
      'recentItems': recentItems,
      'oldItems': oldItems,
      'isProcessing': _isProcessing,
    };
  }

  /// Clear the queue
  Future<void> clear() async {
    if (_queueBox == null) return;

    try {
      await _queueBox!.clear();
      logDebug('[OfflineQueue] Cleared queue');
    } catch (e) {
      logDebug('[OfflineQueue] Error clearing queue: $e');
    }
  }

  /// Clean old items from the queue
  Future<void> _cleanOldItems() async {
    if (_queueBox == null) return;

    try {
      final keysToRemove = <String>[];
      final now = DateTime.now();

      for (final key in _queueBox!.keys) {
        try {
          final jsonStr = _queueBox!.get(key);
          if (jsonStr == null) continue;

          final request = QueuedRequest.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          );

          if (now.difference(request.queuedAt) > maxQueueAge) {
            keysToRemove.add(key as String);
          }
        } catch (e) {
          // Remove invalid items
          keysToRemove.add(key as String);
        }
      }

      for (final key in keysToRemove) {
        await _queueBox!.delete(key);
      }

      if (keysToRemove.isNotEmpty) {
        logDebug('[OfflineQueue] Cleaned ${keysToRemove.length} old items');
      }
    } catch (e) {
      logDebug('[OfflineQueue] Error cleaning old items: $e');
    }
  }
}
