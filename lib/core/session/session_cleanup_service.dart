import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/services/api_http_cache_coordinator.dart';
import 'package:projectbrain/services/feature_flag_service.dart';
import 'package:projectbrain/services/goals_realtime_service.dart';
import 'package:projectbrain/strategies/strategies_chat_provider.dart';
import 'package:projectbrain/strategies/strategies_provider.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';

/// Runs user-session teardown so cached API data and in-memory UI state do not
/// leak to the next logged-in account.
class SessionCleanupService {
  SessionCleanupService({
    required ApiHttpCacheCoordinator httpCacheCoordinator,
    required FeatureFlagService featureFlagService,
    required SubscriptionProvider subscriptionProvider,
    required EggGoalsProvider eggGoalsProvider,
    required StrategiesProvider strategiesProvider,
    required StrategiesChatProvider strategiesChatProvider,
    required GoalsRealtimeService goalsRealtimeService,
  })  : _httpCacheCoordinator = httpCacheCoordinator,
        _featureFlagService = featureFlagService,
        _subscriptionProvider = subscriptionProvider,
        _eggGoalsProvider = eggGoalsProvider,
        _strategiesProvider = strategiesProvider,
        _strategiesChatProvider = strategiesChatProvider,
        _goalsRealtimeService = goalsRealtimeService;

  final ApiHttpCacheCoordinator _httpCacheCoordinator;
  final FeatureFlagService _featureFlagService;
  final SubscriptionProvider _subscriptionProvider;
  final EggGoalsProvider _eggGoalsProvider;
  final StrategiesProvider _strategiesProvider;
  final StrategiesChatProvider _strategiesChatProvider;
  final GoalsRealtimeService _goalsRealtimeService;

  Future<void> clearAfterLogout() async {
    try {
      await _goalsRealtimeService.stop();
    } catch (e, st) {
      logError('[SessionCleanupService] Error stopping goals realtime', e, st);
    }

    _httpCacheCoordinator.clearAllCaches();
    _featureFlagService.resetForNewSession();
    await _subscriptionProvider.resetOnLogout();
    await _eggGoalsProvider.resetOnLogout();
    _strategiesProvider.resetOnLogout();
    _strategiesChatProvider.resetOnLogout();
    logDebug('[SessionCleanupService] Logout cleanup complete');
  }
}
