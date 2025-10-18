import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Available environment modes
enum Environment {
  /// Local development environment
  dev,

  /// Staging environment
  staging,

  /// Production environment
  production,
}

/// Application configuration and environment management
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  /// Current environment mode
  static Environment _environment = Environment.dev;

  /// Get current environment
  static Environment get environment => _environment;

  /// Get environment name as string
  static String get environmentName => _environment.name;

  /// Initialize configuration by loading environment variables
  ///
  /// The environment can be set in three ways (in order of precedence):
  /// 1. Passing [env] parameter directly
  /// 2. Setting --dart-define=ENVIRONMENT=dev|staging|production
  /// 3. Defaulting based on build mode (dev for debug, production for release)
  static Future<void> init({Environment? env}) async {
    // Determine environment
    _environment = env ?? _getEnvironmentFromDefine() ?? _getDefaultEnvironment();

    // Load environment-specific config
    final envFile = '.env.${_environment.name}';
    try {
      await dotenv.load(fileName: envFile);
      debugPrint('[AppConfig] Loaded $envFile successfully');
    } catch (e) {
      debugPrint('[AppConfig] Failed to load $envFile: $e');
      // Fallback to .env.dev for development
      if (_environment == Environment.dev) {
        await dotenv.load(fileName: '.env.dev');
      } else {
        throw Exception('Failed to load $_environment environment configuration');
      }
    }
  }

  /// Get environment from dart-define
  static Environment? _getEnvironmentFromDefine() {
    const envString = String.fromEnvironment('ENVIRONMENT');
    if (envString.isEmpty) return null;

    switch (envString.toLowerCase()) {
      case 'dev':
      case 'development':
        return Environment.dev;
      case 'staging':
        return Environment.staging;
      case 'production':
      case 'prod':
        return Environment.production;
      default:
        debugPrint('[AppConfig] Unknown ENVIRONMENT value: $envString, using default');
        return null;
    }
  }

  /// Get default environment based on build mode
  static Environment _getDefaultEnvironment() {
    if (kReleaseMode) {
      return Environment.production;
    } else if (kProfileMode) {
      return Environment.staging;
    } else {
      return Environment.dev;
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
    return _environment == Environment.dev && audience.contains('localhost');
  }

  /// Check if running in development environment
  static bool get isDev => _environment == Environment.dev;

  /// Check if running in staging environment
  static bool get isStaging => _environment == Environment.staging;

  /// Check if running in production environment
  static bool get isProduction => _environment == Environment.production;

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
