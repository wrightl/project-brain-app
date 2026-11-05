import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/services/egg_goals_service.dart';
import 'package:projectbrain/core/storage/preferences_service.dart';
import 'package:projectbrain/models/goal_streak_summary.dart';

class MockEggGoalsService extends Mock implements EggGoalsService {}

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late EggGoalsProvider provider;
  late MockEggGoalsService mockEggGoalsService;
  late MockPreferencesService mockPreferencesService;

  setUp(() {
    mockEggGoalsService = MockEggGoalsService();
    mockPreferencesService = MockPreferencesService();
    provider = EggGoalsProvider(
      eggGoalsService: mockEggGoalsService,
      preferencesService: mockPreferencesService,
    );
  });

  group('EggGoalsProvider', () {
    test('initial goalStreakSummary is null', () {
      expect(provider.goalStreakSummary, isNull);
    });

    test('loadGoalStreakSummary populates goalStreakSummary', () async {
      when(() => mockEggGoalsService.getStreakSummary()).thenAnswer(
        (_) async => const GoalStreakSummary(
          currentStreak: 3,
          longestStreak: 7,
        ),
      );

      await provider.loadGoalStreakSummary();

      expect(provider.goalStreakSummary?.currentStreak, 3);
      expect(provider.goalStreakSummary?.longestStreak, 7);
    });

    test('loadGoalStreakSummary leaves summary null when service unavailable',
        () async {
      final offlineProvider = EggGoalsProvider(
        preferencesService: mockPreferencesService,
      );

      await offlineProvider.loadGoalStreakSummary();

      expect(offlineProvider.goalStreakSummary, isNull);
    });
  });

  group('EggGoalsProvider.setGoals', () {
    const channel = MethodChannel('com.dotdash.projectbrain/storage');
    late Map<String, Object?> stored;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      stored = {};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        final args = Map<String, Object?>.from(call.arguments as Map);
        final key = args['key'] as String;
        if (call.method == 'savePreferences') {
          stored[key] = args['value'];
          return null;
        }
        return stored[key];
      });
      when(() => mockPreferencesService.setBool(any(), any()))
          .thenAnswer((_) async => true);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('keeps completion for goals whose text did not change', () async {
      stored.addAll({
        'egg_0': 'Walk',
        'egg_0_completed': true,
        'egg_1': 'Read',
        'egg_1_completed': false,
      });
      when(() => mockEggGoalsService.saveEggGoals(any()))
          .thenAnswer((_) async => true);
      when(() => mockEggGoalsService.completeEggGoal(any(), any()))
          .thenAnswer((_) async => true);

      final ok = await provider.setGoals(['Walk', 'Read', 'Call mum']);

      expect(ok, isTrue);
      expect(provider.goals.map((g) => g.completed), [true, false, false]);
      verify(() => mockEggGoalsService.completeEggGoal(0, true)).called(1);
      verifyNever(() => mockEggGoalsService.completeEggGoal(1, any()));
    });

    test('reports failure and leaves stored goals alone when the API fails',
        () async {
      stored.addAll({'egg_0': 'Walk', 'egg_0_completed': true});
      when(() => mockEggGoalsService.saveEggGoals(any()))
          .thenAnswer((_) async => false);

      final ok = await provider.setGoals(['Something else', '', '']);

      expect(ok, isFalse);
      expect(provider.hasError, isTrue);
      expect(stored['egg_0'], 'Walk');
      expect(stored['egg_0_completed'], true);
    });
  });
}
