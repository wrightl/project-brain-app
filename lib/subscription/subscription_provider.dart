import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projectbrain/services/subscription_service.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing subscription state
class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService subscriptionService;
  final SharedPreferences sharedPreferences;

  bool _isLoading = false;
  String? _errorMessage;
  Subscription? _subscription;
  UsageStats? _usage;
  TierInfo? _tierInfo;

  // Cache keys
  static const String _cacheTimestampKey = 'subscription_cache_timestamp';
  static const Duration _cacheExpiration = Duration(minutes: 5);

  SubscriptionProvider({
    required this.subscriptionService,
    required this.sharedPreferences,
  });

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  Subscription? get subscription => _subscription;
  UsageStats? get usage => _usage;
  TierInfo? get tierInfo => _tierInfo;

  /// Get current tier (cached or from API)
  SubscriptionTier get currentTier => _tierInfo?.tier ?? SubscriptionTier.free;

  /// Check if user has a specific tier or higher
  bool hasTierOrHigher(SubscriptionTier tier) {
    final current = currentTier;
    switch (tier) {
      case SubscriptionTier.free:
        return true; // Everyone has free tier
      case SubscriptionTier.pro:
        return current == SubscriptionTier.pro ||
            current == SubscriptionTier.ultimate;
      case SubscriptionTier.ultimate:
        return current == SubscriptionTier.ultimate;
    }
  }

  /// Check if feature is available for current tier
  bool canUseSpeechInput() => hasTierOrHigher(SubscriptionTier.pro);
  bool canUseExternalIntegrations() => currentTier == SubscriptionTier.ultimate;
  bool canUseResearchReports() => hasTierOrHigher(SubscriptionTier.pro);

  /// Get AI query limits based on tier
  int? getDailyAIQueryLimit() {
    switch (currentTier) {
      case SubscriptionTier.free:
        return 50;
      case SubscriptionTier.pro:
      case SubscriptionTier.ultimate:
        return null; // Unlimited
    }
  }

  int? getMonthlyAIQueryLimit() {
    switch (currentTier) {
      case SubscriptionTier.free:
        return 200;
      case SubscriptionTier.pro:
      case SubscriptionTier.ultimate:
        return null; // Unlimited
    }
  }

  /// Get coach connection limit
  int? getCoachConnectionLimit() {
    switch (currentTier) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.pro:
      case SubscriptionTier.ultimate:
        return null; // Unlimited
    }
  }

  /// Get coach message limit
  int? getMonthlyCoachMessageLimit() {
    switch (currentTier) {
      case SubscriptionTier.free:
        return 200;
      case SubscriptionTier.pro:
      case SubscriptionTier.ultimate:
        return null; // Unlimited
    }
  }

  /// Get file count limit
  int? getFileCountLimit() {
    switch (currentTier) {
      case SubscriptionTier.free:
        return 20;
      case SubscriptionTier.pro:
      case SubscriptionTier.ultimate:
        return null; // Unlimited
    }
  }

  /// Get file storage limit in MB
  double? getFileStorageLimitMB() {
    switch (currentTier) {
      case SubscriptionTier.free:
        return 100.0;
      case SubscriptionTier.pro:
        return 500.0;
      case SubscriptionTier.ultimate:
        return null; // Unlimited
    }
  }

  /// Get research report limit
  int? getMonthlyResearchReportLimit() {
    switch (currentTier) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.pro:
        return 1;
      case SubscriptionTier.ultimate:
        return null; // Unlimited
    }
  }

  /// Initialize subscription state.
  ///
  /// By default, refreshes from API before returning. When
  /// [refreshInBackground] is true, the API refresh is kicked off without
  /// blocking the caller.
  Future<void> init({bool refreshInBackground = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try to load from cache first
      await _loadFromCache();

      // Then refresh from API
      if (refreshInBackground) {
        _isLoading = false;
        notifyListeners();
        unawaited(refresh());
      } else {
        await refresh();
      }
    } catch (e) {
      logError('[SubscriptionProvider] Error during init', e);
      _errorMessage = 'Failed to initialize subscription data';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh subscription data from API
  Future<void> refresh() async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      logDebug('[SubscriptionProvider] Refreshing subscription data');
      // Fetch all data in parallel
      final results = await Future.wait([
        subscriptionService.getMySubscription(),
        subscriptionService.getUsage(),
        subscriptionService.getTier(),
      ]);

      logDebug('[SubscriptionProvider] Results: $results');

      _subscription = results[0] as Subscription;
      _usage = results[1] as UsageStats;
      _tierInfo = results[2] as TierInfo;

      // Save to cache
      await _saveToCache();

      logDebug('[SubscriptionProvider] Subscription data refreshed');
    } catch (e) {
      logError('[SubscriptionProvider] Error refreshing subscription data', e);
      _errorMessage = 'Failed to refresh subscription data';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create checkout session
  Future<String> createCheckout(String tier, bool isAnnual) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final url = await subscriptionService.createCheckout(tier, isAnnual);
      return url;
    } catch (e) {
      logError('[SubscriptionProvider] Error creating checkout', e);
      _errorMessage = 'Failed to create checkout session';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await subscriptionService.cancelSubscription();
      // Refresh subscription data after cancellation
      await refresh();
    } catch (e) {
      logError('[SubscriptionProvider] Error canceling subscription', e);
      _errorMessage = 'Failed to cancel subscription';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start trial
  Future<void> startTrial(String tier) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await subscriptionService.startTrial(tier);
      // Refresh subscription data after starting trial
      await refresh();
    } catch (e) {
      logError('[SubscriptionProvider] Error starting trial', e);
      _errorMessage = 'Failed to start trial';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load subscription data from cache
  Future<void> _loadFromCache() async {
    try {
      final timestamp = sharedPreferences.getInt(_cacheTimestampKey);
      if (timestamp == null) return;

      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );

      if (cacheAge > _cacheExpiration) {
        logDebug('[SubscriptionProvider] Cache expired, skipping load');
        return;
      }

      // Load cached data (simplified - in production, you'd want to store JSON)
      logDebug('[SubscriptionProvider] Loading from cache');
    } catch (e) {
      logError('[SubscriptionProvider] Error loading from cache', e);
    }
  }

  /// Save subscription data to cache
  Future<void> _saveToCache() async {
    try {
      await sharedPreferences.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      logDebug('[SubscriptionProvider] Saved to cache');
    } catch (e) {
      logError('[SubscriptionProvider] Error saving to cache', e);
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Drop subscription UI state and prefs so the next user does not see prior tier data.
  Future<void> resetOnLogout() async {
    _subscription = null;
    _usage = null;
    _tierInfo = null;
    _errorMessage = null;
    _isLoading = false;
    await sharedPreferences.remove(_cacheTimestampKey);
    notifyListeners();
    logDebug('[SubscriptionProvider] Reset on logout');
  }
}
