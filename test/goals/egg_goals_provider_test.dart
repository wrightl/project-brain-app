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
}
