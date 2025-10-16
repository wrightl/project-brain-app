import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration and environment management
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  /// Initialize configuration by loading environment variables
  static Future<void> init() async {
    // Load environment-specific config
    final envFile = kReleaseMode ? '.env.production' : '.env.dev';
    try {
      await dotenv.load(fileName: envFile);
    } catch (e) {
      debugPrint('[AppConfig] Failed to load $envFile: $e');
      // Fallback to .env.dev for development
      if (!kReleaseMode) {
        await dotenv.load(fileName: '.env.dev');
      } else {
        throw Exception('Failed to load production environment configuration');
      }
    }
  }

  // Auth0 Configuration
  static String get authDomain => _getEnv('AUTH_DOMAIN');
  static String get authClientId => _getEnv('AUTH_CLIENT_ID');
  static String get authAudience => _getEnv('AUTH_AUDIENCE');
  static String get authIssuer => 'https://$authDomain';

  // App Configuration
  static const String bundleIdentifier = 'com.dotdash.projectbrain';
  static const String authRedirectUri = '$bundleIdentifier://login-callback';
  static const String refreshTokenKey = 'refresh_token';

  // Environment Detection
  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;
  static bool get isProfile => kProfileMode;

  /// Check if running in local development mode
  /// Only allow SSL bypass in this mode
  static bool get isLocalDevelopment {
    final audience = dotenv.env['AUTH_AUDIENCE'] ?? '';
    return kDebugMode && audience.contains('localhost');
  }

  // API Configuration
  static String get apiBaseUrl => authAudience;

  /// Helper to get required environment variable
  static String _getEnv(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Missing required environment variable: $key');
    }
    return value;
  }

  /// Helper to get optional environment variable with default
  static String getEnvOrDefault(String key, String defaultValue) {
    return dotenv.env[key] ?? defaultValue;
  }
}
