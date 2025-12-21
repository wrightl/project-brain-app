import 'dart:convert';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:projectbrain/services/http_service.dart';

/// Service for managing subscriptions
class SubscriptionService extends HttpService {
  SubscriptionService({required super.authService});

  /// Get current subscription details
  Future<Subscription> getMySubscription() async {
    logDebug('[SubscriptionService] Fetching subscription details');

    final response = await get(
      '/subscriptions/me',
      useCache: false,
    );

    logDebug('[SubscriptionService] Response: ${response.body}');

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);
      final subscription = Subscription.fromJson(data);
      logDebug(
          '[SubscriptionService] Fetched subscription: ${subscription.tier.displayName}');
      return subscription;
    } else {
      logError(
          '[SubscriptionService] Failed to fetch subscription: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch subscription: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Get current tier information
  Future<TierInfo> getTier() async {
    logDebug('[SubscriptionService] Fetching tier information');

    final response = await get(
      '/subscriptions/tier',
      useCache: false,
    );

    logDebug('[SubscriptionService] Response: ${response.body}');

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);
      final tierInfo = TierInfo.fromJson(data);
      logDebug(
          '[SubscriptionService] Current tier: ${tierInfo.tier.displayName}');
      return tierInfo;
    } else {
      logError(
          '[SubscriptionService] Failed to fetch tier: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch tier: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Get current usage statistics
  Future<UsageStats> getUsage() async {
    logDebug('[SubscriptionService] Fetching usage statistics');

    final response = await get(
      '/subscriptions/usage',
      useCache: false,
    );

    logDebug('[SubscriptionService] Response: ${response.body}');

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);
      final usage = UsageStats.fromJson(data);
      logDebug('[SubscriptionService] Fetched usage statistics');
      return usage;
    } else {
      logError(
          '[SubscriptionService] Failed to fetch usage: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch usage: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Create Stripe checkout session
  /// Returns the checkout URL
  Future<String> createCheckout(String tier, bool isAnnual) async {
    logDebug(
        '[SubscriptionService] Creating checkout session for tier: $tier, annual: $isAnnual');

    final response = await post(
      '/subscriptions/checkout',
      body: jsonEncode({
        'tier': tier,
        'isAnnual': isAnnual,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.body;
      final data = jsonDecode(body);
      final url = data['url'] ?? data['Url'] ?? '';
      logDebug('[SubscriptionService] Checkout URL created');
      return url;
    } else {
      logError(
          '[SubscriptionService] Failed to create checkout: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to create checkout: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Cancel current subscription
  Future<void> cancelSubscription() async {
    logDebug('[SubscriptionService] Canceling subscription');

    final response = await post(
      '/subscriptions/cancel',
      body: jsonEncode({}),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      logDebug('[SubscriptionService] Subscription canceled successfully');
      // Clear cache for subscription data
      clearCacheForPath('/subscriptions/me');
      clearCacheForPath('/subscriptions/tier');
    } else {
      logError(
          '[SubscriptionService] Failed to cancel subscription: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to cancel subscription: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Start 7-day free trial
  Future<void> startTrial(String tier) async {
    logDebug('[SubscriptionService] Starting trial for tier: $tier');

    final response = await post(
      '/subscriptions/trial',
      body: jsonEncode({
        'tier': tier,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      logDebug('[SubscriptionService] Trial started successfully');
      // Clear cache for subscription data
      clearCacheForPath('/subscriptions/me');
      clearCacheForPath('/subscriptions/tier');
    } else {
      logError(
          '[SubscriptionService] Failed to start trial: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to start trial: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }
}
