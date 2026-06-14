import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/services/error_reporting_service.dart';
import 'package:projectbrain/services/goals_realtime_service.dart';
import 'package:projectbrain/services/push_notification_service.dart';

class MockErrorReportingServiceForTests extends Mock
    implements ErrorReportingService {}

class MockPushNotificationServiceForTests extends Mock
    implements PushNotificationService {}

class MockGoalsRealtimeServiceForTests extends Mock
    implements GoalsRealtimeService {}

class MockEggGoalsProviderForTests extends Mock implements EggGoalsProvider {}

/// Initialize test environment with mock configuration
///
/// [authAudience] overrides `AUTH_AUDIENCE` (e.g. loopback URL for tests that
/// hit a local [HttpServer]).
Future<void> initializeTestEnvironment({String? authAudience}) async {
  // flutter_dotenv 6: `load` reads an asset file first; tests have no .env asset.
  // `loadFromString` initializes the singleton without rootBundle.
  final audience = authAudience ?? 'https://test.example.com';
  dotenv.loadFromString(
    envString: '''
AUTH_DOMAIN=test.auth0.com
AUTH_CLIENT_ID=test_client_id
AUTH_CLIENT_SECRET=test_client_secret
AUTH_AUDIENCE=$audience
AUTH_REDIRECT=http://localhost:6099
LAUNCHDARKLY_CLIENT_SIDE_ID=test_ld_client
LAUNCHDARKLY_MOBILE_KEY=test_ld_mobile
SUBSCRIPTION_BILLING_WEB_URL=https://example.com/billing
''',
    mergeWith: const {},
  );
}

/// Registers minimal GetIt singletons used by [AuthProvider] in tests.
Future<void> registerTestGetItServices() async {
  await GetIt.instance.reset();
  registerFallbackValue('');
  registerFallbackValue(<String, Object>{});
  final err = MockErrorReportingServiceForTests();
  final push = MockPushNotificationServiceForTests();
  final goalsRealtime = MockGoalsRealtimeServiceForTests();
  final eggGoals = MockEggGoalsProviderForTests();
  when(() => err.setUserId(any())).thenAnswer((_) async {});
  when(() => err.logEvent(any(), parameters: any(named: 'parameters')))
      .thenAnswer((_) async {});
  when(() => push.registerToken()).thenAnswer((_) async => true);
  when(() => push.unregisterToken()).thenAnswer((_) async => true);
  when(() => push.ensurePermissionsAndConfigure())
      .thenAnswer((_) async => true);
  when(() => goalsRealtime.start(any())).thenAnswer((_) async {});
  when(() => eggGoals.syncFromAPI()).thenAnswer((_) async {});
  GetIt.instance.registerSingleton<ErrorReportingService>(err);
  GetIt.instance.registerSingleton<PushNotificationService>(push);
  GetIt.instance.registerSingleton<GoalsRealtimeService>(goalsRealtime);
  GetIt.instance.registerSingleton<EggGoalsProvider>(eggGoals);
}

Future<void> resetTestGetIt() => GetIt.instance.reset();

/// Reset test environment (useful for tearDown)
void resetTestEnvironment() {
  // No-op for now - clearing might affect other tests
  // dotenv persists across tests which is actually what we want
}
