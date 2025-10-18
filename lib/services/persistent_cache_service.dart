import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persistent cache service using Hive for offline support
class PersistentCacheService {
  static const String _cacheBoxName = 'http_cache';
  static const String _metadataBoxName = 'cache_metadata';

  Box<String>? _cacheBox;
  Box<Map>? _metadataBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox<String>(_cacheBoxName);
    _metadataBox = await Hive.openBox<Map>(_metadataBoxName);
    debugPrint('[PersistentCache] Initialized with ${_cacheBox!.length} cached items');
  }

  /// Save response to persistent cache
  Future<void> save(
    String key,
    String response,
    Duration cacheDuration,
  ) async {
    if (_cacheBox == null) {
      debugPrint('[PersistentCache] Not initialized, skipping save');
      return;
    }

    try {
      final expiresAt = DateTime.now().add(cacheDuration);

      await _cacheBox!.put(key, response);
      await _metadataBox!.put(key, {
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('[PersistentCache] Saved $key, expires at $expiresAt');
    } catch (e) {
      debugPrint('[PersistentCache] Error saving $key: $e');
    }
  }

  /// Get cached response if not expired
  Future<String?> get(String key) async {
    if (_cacheBox == null) return null;

    try {
      // Check if key exists
      if (!_cacheBox!.containsKey(key)) return null;

      // Check expiry
      final metadata = _metadataBox!.get(key);
      if (metadata == null) {
        await delete(key);
        return null;
      }

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        metadata['expiresAt'] as int,
      );

      if (DateTime.now().isAfter(expiresAt)) {
        debugPrint('[PersistentCache] Cache expired for $key');
        await delete(key);
        return null;
      }

      debugPrint('[PersistentCache] Cache hit for $key');
      return _cacheBox!.get(key);
    } catch (e) {
      debugPrint('[PersistentCache] Error getting $key: $e');
      return null;
    }
  }

  /// Delete a cached item
  Future<void> delete(String key) async {
    if (_cacheBox == null) return;

    try {
      await _cacheBox!.delete(key);
      await _metadataBox!.delete(key);
      debugPrint('[PersistentCache] Deleted $key');
    } catch (e) {
      debugPrint('[PersistentCache] Error deleting $key: $e');
    }
  }

  /// Clear all cached items
  Future<void> clear() async {
    if (_cacheBox == null) return;

    try {
      await _cacheBox!.clear();
      await _metadataBox!.clear();
      debugPrint('[PersistentCache] Cleared all cache');
    } catch (e) {
      debugPrint('[PersistentCache] Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    if (_cacheBox == null) {
      return {
        'initialized': false,
        'totalItems': 0,
      };
    }

    int validItems = 0;
    int expiredItems = 0;

    for (final key in _cacheBox!.keys) {
      final metadata = _metadataBox!.get(key);
      if (metadata != null) {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(
          metadata['expiresAt'] as int,
        );
        if (DateTime.now().isBefore(expiresAt)) {
          validItems++;
        } else {
          expiredItems++;
        }
      }
    }

    return {
      'initialized': true,
      'totalItems': _cacheBox!.length,
      'validItems': validItems,
      'expiredItems': expiredItems,
    };
  }

  /// Clean up expired items
  Future<void> cleanExpired() async {
    if (_cacheBox == null) return;

    try {
      final keysToDelete = <String>[];

      for (final key in _cacheBox!.keys) {
        final metadata = _metadataBox!.get(key);
        if (metadata != null) {
          final expiresAt = DateTime.fromMillisecondsSinceEpoch(
            metadata['expiresAt'] as int,
          );
          if (DateTime.now().isAfter(expiresAt)) {
            keysToDelete.add(key as String);
          }
        }
      }

      for (final key in keysToDelete) {
        await delete(key);
      }

      debugPrint('[PersistentCache] Cleaned ${keysToDelete.length} expired items');
    } catch (e) {
      debugPrint('[PersistentCache] Error cleaning expired items: $e');
    }
  }
}
