import 'package:flutter/material.dart';
import 'package:projectbrain/app_bootstrap.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

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
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.init();

  logInfo('[App] Running in ${AppConfig.environmentName} environment');

  runApp(const AppBootstrap());
}
