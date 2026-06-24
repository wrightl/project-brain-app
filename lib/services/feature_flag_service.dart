import 'dart:convert';

import 'package:projectbrain/models/user.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/services/http_service.dart';

/// Service for managing feature flags using backend API
/// Fetches feature flags from the backend and caches them in memory
class FeatureFlagService {
  final HttpService _httpService;
  Map<String, dynamic> _flags = {};
  bool _isInitialized = false;
  bool _isLoading = false;

  /// Feature flags API endpoint
  static const String _flagsEndpoint = '/feature-flags';

  FeatureFlagService({required HttpService httpService})
      : _httpService = httpService;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the feature flag service
  /// Fetches feature flags from the backend API
  Future<void> init() async {
    if (_isLoading) {
      logDebug('[FeatureFlagService] Already loading flags, skipping');
      return;
    }

    try {
      logInfo('[FeatureFlagService] Initializing and fetching feature flags');
      _isLoading = true;

      await _fetchFlags();

      _isInitialized = true;
      logInfo(
          '[FeatureFlagService] Initialized successfully with ${_flags.length} flags');
    } catch (e) {
      logError('[FeatureFlagService] Failed to initialize', e);
      _isInitialized = false;
      // Initialize with empty flags to allow app to continue
      _flags = {};
    } finally {
      _isLoading = false;
    }
  }

  /// Refresh feature flags when user is identified
  /// This allows the backend to return user-specific feature flags
  Future<void> identifyUser({
    required User user,
    Auth0User? auth0Profile,
  }) async {
    try {
      logInfo('[FeatureFlagService] Refreshing flags for user: ${user.email}');
      await _fetchFlags();
      _isInitialized = true;
      logInfo('[FeatureFlagService] Flags refreshed successfully');
    } catch (e) {
      logError('[FeatureFlagService] Failed to refresh flags for user', e);
    }
  }

  /// Feature flag key constants
  static const String _coachFeatureKey = 'CoachFeatureEnabled';
  static const String _emailFeatureKey = 'EmailFeatureEnabled';
  static const String _agentFeatureKey = 'AgentFeatureEnabled';

  bool get agentFeatureEnabled =>
      _getBoolFlag(_agentFeatureKey, defaultValue: false);

  /// Get the CoachFeatureEnabled flag value
  /// Returns true if the coach section feature is enabled, false otherwise
  bool get coachFeatureEnabled =>
      _getBoolFlag(_coachFeatureKey, defaultValue: false);

  /// Get the EmailFeatureEnabled flag value
  /// Returns true if email features are enabled, false otherwise
  bool get emailFeatureEnabled =>
      _getBoolFlag(_emailFeatureKey, defaultValue: false);

  /// Internal helper to get a boolean feature flag value
  bool _getBoolFlag(String flagKey, {bool defaultValue = false}) {
    if (!_isInitialized) {
      logWarning(
          '[FeatureFlagService] Getting default value for $flagKey - service not initialized');
      return defaultValue;
    }

    try {
      final value = _flags[flagKey];
      if (value == null) {
        logDebug(
            '[FeatureFlagService] Flag $flagKey not found, using default: $defaultValue');
        return defaultValue;
      }

      // Handle boolean values
      if (value is bool) {
        logDebug('[FeatureFlagService] Flag $flagKey = $value');
        return value;
      }

      // Try to convert string "true"/"false" to boolean
      if (value is String) {
        final boolValue = value.toLowerCase() == 'true';
        logDebug(
            '[FeatureFlagService] Flag $flagKey = $boolValue (converted from string)');
        return boolValue;
      }

      logWarning(
          '[FeatureFlagService] Flag $flagKey has unexpected type, using default: $defaultValue');
      return defaultValue;
    } catch (e) {
      logError('[FeatureFlagService] Failed to get flag $flagKey', e);
      return defaultValue;
    }
  }

  /// Fetch feature flags from the backend API
  Future<void> _fetchFlags() async {
    try {
      logDebug('[FeatureFlagService] Fetching flags from $_flagsEndpoint');
      final response = await _httpService.get(
        _flagsEndpoint,
        cacheDuration: const Duration(minutes: 5),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        _flags = decoded;
        logInfo(
            '[FeatureFlagService] Successfully fetched ${_flags.length} feature flags');
      } else {
        logWarning(
            '[FeatureFlagService] Failed to fetch flags: HTTP ${response.statusCode}');
        // Keep existing flags if fetch fails
        if (_flags.isEmpty) {
          _flags = {};
        }
      }
    } catch (e) {
      logError('[FeatureFlagService] Error fetching flags', e);
      // Keep existing flags if fetch fails
      if (_flags.isEmpty) {
        _flags = {};
      }
      rethrow;
    }
  }

  /// Clear cached flags after logout so the next session refetches for the new user.
  void resetForNewSession() {
    _flags.clear();
    _isInitialized = false;
    _isLoading = false;
    logDebug('[FeatureFlagService] Reset for new session');
  }

  /// Manually refresh feature flags from the backend
  Future<void> refreshFlags() async {
    try {
      logInfo('[FeatureFlagService] Manually refreshing feature flags');
      await _fetchFlags();
      logInfo('[FeatureFlagService] Flags refreshed successfully');
    } catch (e) {
      logError('[FeatureFlagService] Failed to refresh flags', e);
    }
  }

  /// Dispose of the service
  void dispose() {
    _flags.clear();
    _isInitialized = false;
    _isLoading = false;
    logInfo('[FeatureFlagService] Disposed');
  }
}
