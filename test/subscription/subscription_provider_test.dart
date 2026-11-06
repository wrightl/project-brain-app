import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:projectbrain/services/subscription_service.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  late MockSubscriptionService service;
  late SubscriptionProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = MockSubscriptionService();
    when(() => service.getMySubscription()).thenAnswer(
      (_) async => Subscription.fromJson({'tier': 'pro', 'status': 'active'}),
    );
    when(() => service.getUsage())
        .thenAnswer((_) async => UsageStats.fromJson({}));
    when(() => service.getTier())
        .thenAnswer((_) async => TierInfo.fromJson({'tier': 'pro'}));
    provider = SubscriptionProvider(
      subscriptionService: service,
      sharedPreferences: await SharedPreferences.getInstance(),
    );
  });

  test('refresh loads the plan', () async {
    await provider.refresh();

    expect(provider.hasError, isFalse);
    expect(provider.hasTierOrHigher(SubscriptionTier.pro), isTrue);
  });

  test('refreshIfStale skips a second refresh within a minute', () async {
    await provider.refreshIfStale();
    await provider.refreshIfStale();

    verify(() => service.getMySubscription()).called(1);
  });

  test('refreshIfStale refreshes again after logout', () async {
    await provider.refreshIfStale();
    await provider.resetOnLogout();
    await provider.refreshIfStale();

    verify(() => service.getMySubscription()).called(2);
  });

  test('a failed refresh reports an error and allows a retry', () async {
    when(() => service.getMySubscription()).thenThrow(Exception('offline'));

    await provider.refreshIfStale();
    expect(provider.hasError, isTrue);

    await provider.refreshIfStale();
    verify(() => service.getMySubscription()).called(2);
  });
}
