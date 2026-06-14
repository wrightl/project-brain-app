import 'package:flutter/services.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Bridges the Dart-loaded Google Maps API key to native SDK initialization.
class GoogleMapsNativeService {
  GoogleMapsNativeService._();

  static const _channel = MethodChannel('com.dotdash.projectbrain/google_maps');

  static String _sanitizeApiKey(String apiKey) {
    var trimmed = apiKey.trim();
    if ((trimmed.startsWith("'") && trimmed.endsWith("'")) ||
        (trimmed.startsWith('"') && trimmed.endsWith('"'))) {
      trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    }
    return trimmed;
  }

  /// Passes [apiKey] to the native Maps SDK (iOS: GMSServices.provideAPIKey).
  static Future<void> configureApiKey(String apiKey) async {
    final sanitized = _sanitizeApiKey(apiKey);
    if (sanitized.isEmpty) return;

    try {
      final alreadyConfigured =
          await _channel.invokeMethod<bool>('isApiKeyConfigured');
      if (alreadyConfigured == true) {
        logInfo(
            '[GoogleMapsNativeService] Native Maps API key already configured');
        return;
      }
    } catch (_) {
      // Fall through and attempt configureApiKey.
    }

    try {
      await _channel.invokeMethod<void>(
        'configureApiKey',
        {'apiKey': sanitized},
      );
      logInfo(
        '[GoogleMapsNativeService] Configured native Maps API key (length=${sanitized.length})',
      );
    } catch (e, st) {
      logWarning('[GoogleMapsNativeService] configureApiKey failed', e, st);
    }
  }
}
