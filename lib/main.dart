import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:projectbrain/app_bootstrap.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/services/google_maps_native_service.dart';

/// Main entry point for the application
///
/// Environment can be configured using --dart-define:
/// - Development: flutter run --dart-define=ENVIRONMENT=dev
/// - Staging: flutter run --dart-define=ENVIRONMENT=staging
/// - Production: flutter run --dart-define=ENVIRONMENT=production
///
/// Without --dart-define, defaults are:
/// - Debug mode -> dev
/// - Profile mode -> staging
/// - Release mode -> production
Future<void> main() async {
  // Wrap the whole app in a guarded zone so bootstrap and early-frame errors
  // (before the widget tree is up) are still captured by Crashlytics.
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await AppConfig.init();
    await GoogleMapsNativeService.configureApiKey(AppConfig.googleMapsApiKey);

    logInfo('[App] Running in ${AppConfig.environmentName} environment');

    // Initialize Firebase + crash handlers synchronously, before the first
    // frame. Bootstrap detects the already-initialized app and skips re-init.
    await _initializeCrashReporting();

    runApp(const AppBootstrap());
  }, (error, stack) {
    logError('[App] Uncaught zone error', error, stack);
    _recordToCrashlytics(error, stack, fatal: true);
  });
}

/// Initialize Firebase and wire framework/platform error handlers immediately.
Future<void> _initializeCrashReporting() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Framework errors -> Crashlytics (non-fatal so fatals match real crashes).
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      crashlytics.recordFlutterError(details);
    };

    // Unhandled async/platform errors.
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: false);
      return true;
    };

    // Forward every logError/logFatal call to Crashlytics as a non-fatal/fatal.
    AppLogger.crashReporter =
        (message, error, stackTrace, {bool fatal = false}) {
      try {
        crashlytics.recordError(
          error ?? message,
          stackTrace,
          reason: message,
          fatal: fatal,
        );
      } catch (_) {
        // Never let crash reporting throw into the caller.
      }
    };
  } catch (e, st) {
    logError('[App] Crash reporting init failed', e, st);
  }
}

void _recordToCrashlytics(Object error, StackTrace stack,
    {bool fatal = false}) {
  try {
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
    }
  } catch (_) {
    // Ignore: crash reporting must not crash the error handler.
  }
}
