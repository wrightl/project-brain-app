import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/core/session/session_cleanup_service.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/services/api_http_cache_coordinator.dart';
import 'package:projectbrain/services/coach_message_signalr_service.dart';
import 'package:projectbrain/services/feature_flag_service.dart';
import 'package:projectbrain/services/goals_realtime_service.dart';
import 'package:projectbrain/strategies/strategies_chat_provider.dart';
import 'package:projectbrain/strategies/strategies_provider.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/user_memory/user_memory_provider.dart';

class _Cache extends Mock implements ApiHttpCacheCoordinator {}

class _Flags extends Mock implements FeatureFlagService {}

class _Subscription extends Mock implements SubscriptionProvider {}

class _Goals extends Mock implements EggGoalsProvider {}

class _Strategies extends Mock implements StrategiesProvider {}

class _StrategiesChat extends Mock implements StrategiesChatProvider {}

class _Memory extends Mock implements UserMemoryProvider {}

class _GoalsRealtime extends Mock implements GoalsRealtimeService {}

class _SignalR extends Mock implements CoachMessageSignalRService {}

class _Chat extends Mock implements ChatProvider {}

class _Journal extends Mock implements JournalProvider {}

void main() {
  late _Cache cache;
  late _Flags flags;
  late _Subscription subscription;
  late _Goals goals;
  late _Strategies strategies;
  late _StrategiesChat strategiesChat;
  late _Memory memory;
  late _GoalsRealtime goalsRealtime;
  late _SignalR signalR;
  late _Chat chat;
  late _Journal journal;
  late SessionCleanupService service;

  setUp(() {
    cache = _Cache();
    flags = _Flags();
    subscription = _Subscription();
    goals = _Goals();
    strategies = _Strategies();
    strategiesChat = _StrategiesChat();
    memory = _Memory();
    goalsRealtime = _GoalsRealtime();
    signalR = _SignalR();
    chat = _Chat();
    journal = _Journal();

    when(() => goalsRealtime.stop()).thenAnswer((_) async {});
    when(() => signalR.stop()).thenAnswer((_) async {});
    when(() => subscription.resetOnLogout()).thenAnswer((_) async {});
    when(() => goals.resetOnLogout()).thenAnswer((_) async {});

    service = SessionCleanupService(
      httpCacheCoordinator: cache,
      featureFlagService: flags,
      subscriptionProvider: subscription,
      eggGoalsProvider: goals,
      strategiesProvider: strategies,
      strategiesChatProvider: strategiesChat,
      userMemoryProvider: memory,
      goalsRealtimeService: goalsRealtime,
      coachMessageSignalRService: signalR,
      chatProvider: chat,
      journalProvider: journal,
    );
  });

  test('logout clears every cache and per-user state holder', () async {
    await service.clearAfterLogout();

    verify(() => goalsRealtime.stop()).called(1);
    verify(() => signalR.stop()).called(1);
    verify(() => cache.clearAllCaches()).called(1);
    verify(() => flags.resetForNewSession()).called(1);
    verify(() => subscription.resetOnLogout()).called(1);
    verify(() => goals.resetOnLogout()).called(1);
    verify(() => strategies.resetOnLogout()).called(1);
    verify(() => strategiesChat.resetOnLogout()).called(1);
    verify(() => memory.resetOnLogout()).called(1);
    verify(() => chat.resetOnLogout()).called(1);
    verify(() => journal.resetOnLogout()).called(1);
  });

  test('a failing realtime stop does not skip the rest of the cleanup',
      () async {
    when(() => goalsRealtime.stop()).thenThrow(Exception('socket'));
    when(() => signalR.stop()).thenThrow(Exception('socket'));

    await service.clearAfterLogout();

    verify(() => cache.clearAllCaches()).called(1);
    verify(() => chat.resetOnLogout()).called(1);
    verify(() => journal.resetOnLogout()).called(1);
  });
}
