import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/models/user.dart';
import 'package:projectbrain/services/user_service.dart';
import 'package:projectbrain/services/feature_flag_service.dart';
import 'package:projectbrain/services/push_notification_service.dart';
import 'package:projectbrain/services/error_reporting_service.dart';
import 'package:projectbrain/services/goals_realtime_service.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/services/api_http_cache_coordinator.dart';
import 'package:projectbrain/core/session/session_cleanup_service.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;
  final FeatureFlagService? featureFlagService;
  final UserService userService;

  bool _isLoading = false;
  bool _onboardingComplete = false;
  User? _user;
  String? _errorMessage;

  AuthProvider({
    required this.authService,
    this.featureFlagService,
    required this.userService,
  });

  bool get isLoading => _isLoading;
  bool get isLoggedIn => authService.isLoggedIn;
  Auth0User? get profile => authService.profile;
  User? get user => _user;
  bool get onboardingComplete => _onboardingComplete;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.init();
      if (!isLoggedIn) {
        _errorMessage = authService.consumeLaunchAuthMessage();
      }
      if (isLoggedIn) {
        await _fetchUserData();
      }
    } catch (e) {
      logError('[AuthProvider] Error during init', e);
      _errorMessage = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.login();
      if (sl.isRegistered<ApiHttpCacheCoordinator>()) {
        sl<ApiHttpCacheCoordinator>().clearAllCaches();
      }
      await _fetchUserData();

      // Set user ID in analytics after successful login
      try {
        final userId = profile?.sub ?? _user?.id;
        if (userId != null) {
          await sl<ErrorReportingService>().setUserId(userId);
        }
        await sl<ErrorReportingService>().logEvent('login');
      } catch (e) {
        logError('[AuthProvider] Error setting analytics user ID', e);
        // Don't fail login if analytics user ID setting fails
      }

      // Register push notification token after successful login (non-blocking).
      unawaited(_registerPushTokenAfterLogin());

      // Open the realtime goals stream for the freshly logged-in session (non-blocking).
      unawaited(
        sl<GoalsRealtimeService>()
            .start(() => sl<EggGoalsProvider>().syncFromAPI()),
      );
    } catch (e) {
      logError('[AuthProvider] Error during login', e);
      _errorMessage = e.toString().replaceAll('AuthException: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _errorMessage = null;
    try {
      // Unregister push notification token before logout
      try {
        await sl<PushNotificationService>().unregisterToken();
      } catch (e) {
        logError(
            '[AuthProvider] Error unregistering push token during logout', e);
        // Continue with logout even if unregister fails
      }

      if (sl.isRegistered<SessionCleanupService>()) {
        try {
          await sl<SessionCleanupService>().clearAfterLogout();
        } catch (e, st) {
          logError('[AuthProvider] Session cleanup failed', e, st);
        }
      }

      await authService.logout();
      _user = null;
      _onboardingComplete = false;

      // Clear user ID in analytics after logout
      try {
        await sl<ErrorReportingService>().logEvent('logout');
        await sl<ErrorReportingService>().setUserId(null);
      } catch (e) {
        logError('[AuthProvider] Error clearing analytics user ID', e);
        // Don't fail logout if analytics user ID clearing fails
      }

      // // Reset feature flags to anonymous context
      // if (featureFlagService != null) {
      //   await featureFlagService!.logout();
      // }
    } catch (e) {
      logError('[AuthProvider] Error during logout', e);
      _errorMessage = 'Failed to logout';
    } finally {
      notifyListeners();
    }
  }

  Future<void> completeOnboarding(Map<String, dynamic> formData) async {
    _errorMessage = null;
    try {
      await userService.completeOnboarding(formData);
      await _fetchUserData();
      try {
        await sl<ErrorReportingService>().logEvent('onboarding_complete');
      } catch (_) {
        // Analytics failure must not affect onboarding.
      }
    } catch (e) {
      logError('[AuthProvider] Error during onboarding', e);
      _errorMessage = 'Failed to complete onboarding';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await userService.getCurrentUser();
      _user = User.fromJson(data);
      _onboardingComplete = _user?.isOnboarded ?? false;

      // Set user ID in analytics if not already set
      try {
        final userId = profile?.sub ?? _user?.id;
        if (userId != null) {
          await sl<ErrorReportingService>().setUserId(userId);
        }
      } catch (e) {
        logError('[AuthProvider] Error setting analytics user ID', e);
        // Don't fail user data fetch if analytics user ID setting fails
      }

      // Update feature flags with user context
      if (_user != null && featureFlagService != null) {
        await featureFlagService!.identifyUser(
          user: _user!,
          auth0Profile: profile,
        );
      }
    } catch (e) {
      logError('[AuthProvider] Error fetching user data', e);
      _user = null;
      _onboardingComplete = false;
      _errorMessage = 'Failed to fetch user data';
    }
  }

  /// Manually refresh user data from the server
  Future<void> refreshUserData() async {
    _errorMessage = null;
    try {
      await _fetchUserData();
    } catch (e) {
      logError('[AuthProvider] Error refreshing user data', e);
      _errorMessage = 'Failed to refresh user data';
    } finally {
      notifyListeners();
    }
  }

  /// Update user profile
  Future<void> updateUser(Map<String, dynamic> userData) async {
    if (_user == null) {
      throw Exception('No user logged in');
    }

    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await userService.updateUser(_user!.id, userData);
    } catch (e) {
      logError('[AuthProvider] Error updating user', e);
      _errorMessage = 'Failed to update user profile';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear the current error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _registerPushTokenAfterLogin() async {
    try {
      await sl<PushNotificationService>().ensurePermissionsAndConfigure();
      await sl<PushNotificationService>().registerToken();
    } catch (e) {
      logError('[AuthProvider] Error registering push token after login', e);
    }
  }
}
