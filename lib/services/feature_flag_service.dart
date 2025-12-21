import 'dart:async';

import 'package:launchdarkly_flutter_client_sdk/launchdarkly_flutter_client_sdk.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/models/user.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Service for managing feature flags using LaunchDarkly
/// Integrates with user authentication to provide user-specific feature flags
class FeatureFlagService {
  LDClient? _client;
  bool _isInitialized = false;
  StreamSubscription<List<String>>? _flagChangesSubscription;

  /// Get the LaunchDarkly client instance
  LDClient? get client => _client;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the feature flag service with an anonymous user context
  Future<void> init() async {
    try {
      logInfo('[FeatureFlagService] Initializing with anonymous context');

      final config = LDConfig(
        AppConfig.launchDarklyMobileKey,
        AutoEnvAttributes.enabled,
      );
      final context = _buildAnonymousContext();

      _client = LDClient(config, context);
      await _client?.start();
      _isInitialized = true;

      logInfo('[FeatureFlagService] Initialized successfully');
    } catch (e) {
      logError('[FeatureFlagService] Failed to initialize', e);
      _isInitialized = false;
    }
  }

  /// Update the context with authenticated user details
  Future<void> identifyUser({
    required User user,
    Auth0User? auth0Profile,
  }) async {
    if (!_isInitialized || _client == null) {
      logWarning(
          '[FeatureFlagService] Cannot identify user - service not initialized');
      return;
    }

    try {
      logInfo('[FeatureFlagService] Identifying user: ${user.email}');

      final context = _buildUserContext(user: user, auth0Profile: auth0Profile);
      await _client?.identify(context);

      logInfo('[FeatureFlagService] User identified successfully');
    } catch (e) {
      logError('[FeatureFlagService] Failed to identify user', e);
    }
  }

  /// Update the context to anonymous when user logs out
  Future<void> logout() async {
    if (!_isInitialized || _client == null) {
      logWarning(
          '[FeatureFlagService] Cannot logout - service not initialized');
      return;
    }

    try {
      logInfo('[FeatureFlagService] Switching to anonymous context');

      final context = _buildAnonymousContext();
      await _client?.identify(context);

      logInfo(
          '[FeatureFlagService] Switched to anonymous context successfully');
    } catch (e) {
      logError('[FeatureFlagService] Failed to switch to anonymous context', e);
    }
  }

  /// Get a boolean feature flag value
  Future<bool> getBoolFlag(String flagKey, {bool defaultValue = false}) async {
    if (!_isInitialized || _client == null) {
      logWarning(
          '[FeatureFlagService] Getting default value for $flagKey - service not initialized');
      return defaultValue;
    }

    try {
      final value =
          _client?.boolVariation(flagKey, defaultValue) ?? defaultValue;
      logDebug('[FeatureFlagService] Flag $flagKey = $value');
      return value;
    } catch (e) {
      logError('[FeatureFlagService] Failed to get flag $flagKey', e);
      return defaultValue;
    }
  }

  /// Get a string feature flag value
  Future<String> getStringFlag(String flagKey,
      {String defaultValue = ''}) async {
    if (!_isInitialized || _client == null) {
      logWarning(
          '[FeatureFlagService] Getting default value for $flagKey - service not initialized');
      return defaultValue;
    }

    try {
      final value =
          _client?.stringVariation(flagKey, defaultValue) ?? defaultValue;
      logDebug('[FeatureFlagService] Flag $flagKey = $value');
      return value;
    } catch (e) {
      logError('[FeatureFlagService] Failed to get flag $flagKey', e);
      return defaultValue;
    }
  }

  /// Get an integer feature flag value
  Future<int> getIntFlag(String flagKey, {int defaultValue = 0}) async {
    if (!_isInitialized || _client == null) {
      logWarning(
          '[FeatureFlagService] Getting default value for $flagKey - service not initialized');
      return defaultValue;
    }

    try {
      final value =
          _client?.intVariation(flagKey, defaultValue) ?? defaultValue;
      logDebug('[FeatureFlagService] Flag $flagKey = $value');
      return value;
    } catch (e) {
      logError('[FeatureFlagService] Failed to get flag $flagKey', e);
      return defaultValue;
    }
  }

  /// Get a double feature flag value
  Future<double> getDoubleFlag(String flagKey,
      {double defaultValue = 0.0}) async {
    if (!_isInitialized || _client == null) {
      logWarning(
          '[FeatureFlagService] Getting default value for $flagKey - service not initialized');
      return defaultValue;
    }

    try {
      final value =
          _client?.doubleVariation(flagKey, defaultValue) ?? defaultValue;
      logDebug('[FeatureFlagService] Flag $flagKey = $value');
      return value;
    } catch (e) {
      logError('[FeatureFlagService] Failed to get flag $flagKey', e);
      return defaultValue;
    }
  }

  /// Get a JSON feature flag value
  Future<LDValue> getJsonFlag(String flagKey,
      {required LDValue defaultValue}) async {
    if (!_isInitialized || _client == null) {
      logWarning(
          '[FeatureFlagService] Getting default value for $flagKey - service not initialized');
      return defaultValue;
    }

    try {
      final value =
          _client?.jsonVariation(flagKey, defaultValue) ?? defaultValue;
      logDebug('[FeatureFlagService] Flag $flagKey = $value');
      return value;
    } catch (e) {
      logError('[FeatureFlagService] Failed to get flag $flagKey', e);
      return defaultValue;
    }
  }

  /// Listen to flag changes
  /// Returns a stream that emits the flag key whenever it changes
  Stream<String> listenToFlag(String flagKey) {
    if (!_isInitialized || _client == null) {
      logWarning(
          '[FeatureFlagService] Cannot listen to flag - service not initialized');
      return Stream.empty();
    }

    return _client!.flagChanges.where((changedFlags) {
      return changedFlags.keys.contains(flagKey);
    }).map((_) => flagKey);
  }

  /// Listen to all flag changes
  Stream<FlagsChangedEvent> get allFlagChanges {
    if (!_isInitialized || _client == null) {
      return Stream.empty();
    }
    return _client!.flagChanges;
  }

  // /// Register a listener for flag changes
  // void registerFlagListener(String flagKey, void Function(String) listener) {
  //   if (!_isInitialized || _client == null) {
  //     logWarning('[FeatureFlagService] Cannot register listener - service not initialized');
  //     return;
  //   }
  //   try {
  //     _client?.flagChanges(flagKey, listener);
  //     logDebug('[FeatureFlagService] Registered listener for $flagKey');
  //   } catch (e) {
  //     logError('[FeatureFlagService] Failed to register listener for $flagKey', e);
  //   }
  // }

  // /// Unregister a listener for flag changes
  // void unregisterFlagListener(String flagKey, void Function(String) listener) {
  //   if (!_isInitialized || _client == null) {
  //     logWarning('[FeatureFlagService] Cannot unregister listener - service not initialized');
  //     return;
  //   }

  //   try {
  //     _client?.unregisterFeatureFlagListener(flagKey, listener);
  //     logDebug('[FeatureFlagService] Unregistered listener for $flagKey');
  //   } catch (e) {
  //     logError('[FeatureFlagService] Failed to unregister listener for $flagKey', e);
  //   }
  // }

  /// Build an anonymous context for unauthenticated users
  LDContext _buildAnonymousContext() {
    return LDContextBuilder().kind('user', 'anonymous').anonymous(true).build();
  }

  /// Build a user context with all available user details
  LDContext _buildUserContext({
    required User user,
    Auth0User? auth0Profile,
  }) {
    final builder = LDContextBuilder()
        .kind('user', user.id)
        .setString('email', user.email)
        .setString('name', user.name);

    // Add optional attributes
    if (user.nickname != null && user.nickname!.isNotEmpty) {
      builder.setString('nickname', user.nickname!);
    }

    if (user.bio != null && user.bio!.isNotEmpty) {
      builder.setString('bio', user.bio!);
    }

    // Add onboarding status
    builder.setBool('isOnboarded', user.isOnboarded);

    // Add timestamps
    if (user.createdAt != null) {
      builder.setString('createdAt', user.createdAt!.toIso8601String());
    }

    if (user.updatedAt != null) {
      builder.setString('updatedAt', user.updatedAt!.toIso8601String());
    }

    // Add Auth0 profile details if available
    if (auth0Profile != null) {
      builder.setString('auth0Sub', auth0Profile.sub);

      if (auth0Profile.picture.isNotEmpty) {
        builder.setString('avatar', auth0Profile.picture);
      }
    }

    // Add environment
    builder.setString('environment', AppConfig.environmentName);

    return builder.build();
  }

  /// Dispose of the service
  void dispose() {
    _flagChangesSubscription?.cancel();
    _client = null;
    _isInitialized = false;
    logInfo('[FeatureFlagService] Disposed');
  }
}
