import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:projectbrain/core/config/app_config.dart';

/// Centralized logging service for the application
///
/// Provides environment-aware logging that works across all build modes.
/// - Development: Verbose logging with pretty formatting
/// - Staging: Info level logging with simple formatting
/// - Production: Warning/Error only with simple formatting
class AppLogger {
  static Logger? _instance;

  /// Optional sink for error-level logs (wired to Crashlytics in `main`).
  ///
  /// Kept as a hook so the logger has no hard dependency on Firebase and stays
  /// testable. Every [logError]/[logFatal] call is forwarded here, turning
  /// existing service catch blocks into crash-reporter non-fatals.
  static void Function(
    String message,
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal,
  })? crashReporter;

  /// Get the singleton logger instance
  static Logger get instance {
    _instance ??= _createLogger();
    return _instance!;
  }

  /// Reset the logger instance (useful for testing or environment changes)
  static void reset() {
    _instance?.close();
    _instance = null;
  }

  /// Create logger with environment-specific configuration
  static Logger _createLogger() {
    return Logger(
      filter: _LogFilter(),
      printer: _getLogPrinter(),
      level: _getLogLevel(),
    );
  }

  /// Get log level based on environment
  static Level _getLogLevel() {
    if (AppConfig.isDev) {
      return Level.trace; // Show everything in dev
    } else if (AppConfig.isStaging) {
      return Level.debug; // Debug and above in staging
    } else {
      return Level.warning; // Only warnings and errors in production
    }
  }

  /// Get log printer based on environment
  static LogPrinter _getLogPrinter() {
    if (AppConfig.isDev) {
      // Pretty printer for development
      return PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      );
    } else {
      // Simple printer for staging and production
      return SimplePrinter(
        printTime: true,
      );
    }
  }
}

/// Custom log filter that respects environment settings
class _LogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In release mode, only log warnings and errors
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
    // In debug/profile mode, respect the configured log level
    return event.level.index >= level!.index;
  }
}

/// Extension to make logging more convenient throughout the app
extension LoggerExtension on Object {
  /// Get logger instance for this object's type
  Logger get log => AppLogger.instance;
}

/// Convenient global logger functions
void logTrace(String message, [dynamic error, StackTrace? stackTrace]) {
  AppLogger.instance.t(message, error: error, stackTrace: stackTrace);
}

void logDebug(String message, [dynamic error, StackTrace? stackTrace]) {
  AppLogger.instance.d(message, error: error, stackTrace: stackTrace);
}

void logInfo(String message, [dynamic error, StackTrace? stackTrace]) {
  AppLogger.instance.i(message, error: error, stackTrace: stackTrace);
}

void logWarning(String message, [dynamic error, StackTrace? stackTrace]) {
  AppLogger.instance.w(message, error: error, stackTrace: stackTrace);
}

void logError(String message, [dynamic error, StackTrace? stackTrace]) {
  AppLogger.instance.e(message, error: error, stackTrace: stackTrace);
  AppLogger.crashReporter?.call(message, error, stackTrace, fatal: false);
}

void logFatal(String message, [dynamic error, StackTrace? stackTrace]) {
  AppLogger.instance.f(message, error: error, stackTrace: stackTrace);
  AppLogger.crashReporter?.call(message, error, stackTrace, fatal: true);
}
