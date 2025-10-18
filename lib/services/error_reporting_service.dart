import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Centralized error reporting and analytics service
class ErrorReportingService {
  final FirebaseCrashlytics? _crashlytics;
  final FirebaseAnalytics? _analytics;
  bool _initialized = false;

  ErrorReportingService({
    FirebaseCrashlytics? crashlytics,
    FirebaseAnalytics? analytics,
  })  : _crashlytics = crashlytics,
        _analytics = analytics;

  /// Initialize error reporting
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize Crashlytics
      if (_crashlytics != null) {
        // Pass all uncaught errors to Crashlytics
        FlutterError.onError = (details) {
          _crashlytics.recordFlutterFatalError(details);
        };

        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics.recordError(error, stack, fatal: true);
          return true;
        };

        _initialized = true;
        logDebug('[ErrorReporting] Crashlytics initialized');
      }

      // Initialize Analytics
      if (_analytics != null) {
        await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
        logDebug('[ErrorReporting] Analytics initialized');
      }
    } catch (e) {
      logDebug('[ErrorReporting] Initialization error: $e');
    }
  }

  /// Report a non-fatal error
  Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) async {
    if (!_initialized || _crashlytics == null) {
      logDebug('[ErrorReporting] Not initialized, logging error: $error');
      return;
    }

    try {
      // Add context information
      if (context != null) {
        for (final entry in context.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value);
        }
      }

      // Record the error
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );

      logDebug('[ErrorReporting] Reported error: $error');
    } catch (e) {
      logDebug('[ErrorReporting] Failed to report error: $e');
    }
  }

  /// Log a message to Crashlytics
  void log(String message) {
    if (!_initialized || _crashlytics == null) return;

    try {
      _crashlytics.log(message);
    } catch (e) {
      logDebug('[ErrorReporting] Failed to log message: $e');
    }
  }

  /// Set user identifier
  Future<void> setUserId(String? userId) async {
    if (!_initialized) return;

    try {
      if (_crashlytics != null) {
        await _crashlytics.setUserIdentifier(userId ?? '');
      }
      if (_analytics != null) {
        await _analytics.setUserId(id: userId);
      }
      logDebug('[ErrorReporting] Set user ID: $userId');
    } catch (e) {
      logDebug('[ErrorReporting] Failed to set user ID: $e');
    }
  }

  /// Set custom key-value pair
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_initialized || _crashlytics == null) return;

    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      logDebug('[ErrorReporting] Failed to set custom key: $e');
    }
  }

  /// Log analytics event
  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!_initialized || _analytics == null) return;

    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      logDebug('[ErrorReporting] Logged event: $name');
    } catch (e) {
      logDebug('[ErrorReporting] Failed to log event: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    if (!_initialized || _analytics == null) return;

    try {
      await _analytics.logScreenView(screenName: screenName);
      logDebug('[ErrorReporting] Logged screen: $screenName');
    } catch (e) {
      logDebug('[ErrorReporting] Failed to log screen view: $e');
    }
  }

  /// Check if Crashlytics is collecting reports
  Future<bool> isCrashlyticsCollectionEnabled() async {
    if (!_initialized || _crashlytics == null) return false;

    try {
      return await _crashlytics.isCrashlyticsCollectionEnabled;
    } catch (e) {
      logDebug('[ErrorReporting] Failed to check collection status: $e');
      return false;
    }
  }

  /// Enable/disable Crashlytics collection
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    if (!_initialized || _crashlytics == null) return;

    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
      logDebug('[ErrorReporting] Crashlytics collection: $enabled');
    } catch (e) {
      logDebug('[ErrorReporting] Failed to set collection status: $e');
    }
  }

  /// Test crash (for testing purposes only)
  void testCrash() {
    if (!_initialized || _crashlytics == null) return;

    logDebug('[ErrorReporting] Triggering test crash');
    // Trigger a test crash
    throw Exception('Test crash from ErrorReportingService');
  }
}
