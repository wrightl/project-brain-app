import 'package:flutter/material.dart';
import 'package:projectbrain/services/egg_goals_service.dart';
import 'package:projectbrain/ios_widget/shared_preferences_storage.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/core/storage/preferences_service.dart';
import 'package:projectbrain/models/goal_streak_summary.dart';

/// Model for an egg goal
class EggGoal {
  final String message;
  final bool completed;

  EggGoal({required this.message, required this.completed});
}

/// Provider for managing egg goals state
class EggGoalsProvider extends ChangeNotifier {
  final EggGoalsService? eggGoalsService;
  final PreferencesService preferencesService;

  List<EggGoal> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;
  GoalStreakSummary? _goalStreakSummary;

  List<EggGoal> get goals => List.unmodifiable(_goals);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Goal completion streak (populated when backend provides GET /eggs/streak-summary).
  GoalStreakSummary? get goalStreakSummary => _goalStreakSummary;

  EggGoalsProvider({
    this.eggGoalsService,
    required this.preferencesService,
  });

  /// Check if user has ever set goals before
  Future<bool> hasEverSetGoals() async {
    // Use API to check if user has ever created goals
    if (eggGoalsService != null) {
      try {
        final hasCreated = await eggGoalsService!.hasEverCreatedGoals();
        // Cache the result locally for offline support
        if (hasCreated) {
          await preferencesService.setBool('has_ever_set_goals', true);
        }
        return hasCreated;
      } catch (e) {
        logError(
            '[EggGoalsProvider] Error checking has ever set goals from API', e);
        // Fallback to local preference if API fails
        return preferencesService.getBool('has_ever_set_goals') ?? false;
      }
    }
    // Fallback to local preference if service not available
    return preferencesService.getBool('has_ever_set_goals') ?? false;
  }

  /// Check if goals exist for today
  Future<bool> hasGoalsForToday() async {
    await _loadGoalsFromStorage();
    logDebug('[EggGoalsProvider] Goals for today: $_goals');
    return _goals.any(
        (goal) => goal.message.isNotEmpty && goal.message != 'No Egg Goal Set');
  }

  /// Get today's goals
  Future<List<EggGoal>> getTodaysGoals() async {
    await _loadGoalsFromStorage();
    return List.unmodifiable(_goals);
  }

  /// Get completion progress (X/3)
  Map<String, int> getCompletionProgress() {
    final completed = _goals.where((g) => g.completed).length;
    return {'completed': completed, 'total': _goals.length};
  }

  /// Set goals for today
  Future<void> setGoals(List<String> goalMessages) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Save to API if service is available
      if (eggGoalsService != null) {
        final success = await eggGoalsService!.saveEggGoals(goalMessages);
        if (!success) {
          logWarning(
              '[EggGoalsProvider] Failed to save goals to API, saving locally only');
        }
      }

      // Save to App Group shared storage (iOS native channel)
      for (int i = 0; i < 3; i++) {
        if (i < goalMessages.length && goalMessages[i].isNotEmpty) {
          await SharedPreferencesStorage.setValue('egg_$i', goalMessages[i]);
          await SharedPreferencesStorage.setBool('egg_${i}_completed', false);
        } else {
          await SharedPreferencesStorage.setValue('egg_$i', 'No Egg Goal Set');
          await SharedPreferencesStorage.setBool('egg_${i}_completed', false);
        }
      }

      // Mark that user has set goals (local cache for offline support)
      // The API now tracks this, but we cache locally as a fallback
      await preferencesService.setBool('has_ever_set_goals', true);

      await _loadGoalsFromStorage();
    } catch (e) {
      logError('[EggGoalsProvider] Error setting goals', e);
      _errorMessage = 'Failed to save goals';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle goal completion status
  Future<void> toggleGoalCompletion(int index) async {
    if (index < 0 || index >= _goals.length) return;

    final wasCompleted = _goals[index].completed;
    final newCompleted = !wasCompleted;

    _isLoading = true;
    notifyListeners();

    try {
      // Update local state immediately
      _goals[index] = EggGoal(
        message: _goals[index].message,
        completed: newCompleted,
      );

      // Save to App Group shared storage (iOS)
      await SharedPreferencesStorage.setBool(
          'egg_${index}_completed', newCompleted);

      // Save to API if service is available
      if (eggGoalsService != null) {
        await eggGoalsService!.completeEggGoal(index, newCompleted);
      }

      await _loadGoalsFromStorage();
      await loadGoalStreakSummary();
    } catch (e) {
      logError('[EggGoalsProvider] Error toggling goal completion', e);
      // Revert on error
      _goals[index] = EggGoal(
        message: _goals[index].message,
        completed: wasCompleted,
      );
      _errorMessage = 'Failed to update goal';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sync goals from API
  Future<void> syncFromAPI() async {
    logDebug('[EggGoalsProvider] Syncing goals from API');
    if (eggGoalsService == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      logDebug('[EggGoalsProvider] Syncing goals from API');
      final apiGoals = await eggGoalsService!.syncEggGoals();
      logDebug('[EggGoalsProvider] Synced goals from API: $apiGoals');
      // Always update all 3 slots from API so empty response clears stale local data
      for (int i = 0; i < 3; i++) {
        if (i < apiGoals.length) {
          final goal = apiGoals[i];
          await SharedPreferencesStorage.setValue(
            'egg_$i',
            goal['message'] ?? goal['text'] ?? 'No Egg Goal Set',
          );
          await SharedPreferencesStorage.setBool(
            'egg_${i}_completed',
            goal['completed'] ?? false,
          );
        } else {
          await SharedPreferencesStorage.setValue('egg_$i', 'No Egg Goal Set');
          await SharedPreferencesStorage.setBool('egg_${i}_completed', false);
        }
      }

      await _loadGoalsFromStorage();
    } catch (e) {
      logError('[EggGoalsProvider] Error syncing from API', e);
      _errorMessage = 'Failed to sync goals';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load goals from shared storage
  Future<void> _loadGoalsFromStorage() async {
    _goals.clear();
    for (int i = 0; i < 3; i++) {
      final message = await SharedPreferencesStorage.getString('egg_$i');
      final messageStr = message ?? 'No Egg Goal Set';
      final completed =
          await SharedPreferencesStorage.getBool('egg_${i}_completed');
      final completedBool = completed ?? false;

      _goals.add(EggGoal(
        message: messageStr,
        completed: completedBool,
      ));
    }
  }

  /// Load goal streak summary from backend.
  Future<void> loadGoalStreakSummary() async {
    if (eggGoalsService == null) return;
    try {
      _goalStreakSummary = await eggGoalsService!.getStreakSummary();
      notifyListeners();
    } catch (e) {
      logError('[EggGoalsProvider] loadGoalStreakSummary failed', e);
    }
  }

  /// Initialize - load from storage
  Future<void> init() async {
    await _loadGoalsFromStorage();
    notifyListeners();
  }

  /// Clear goals and prefs for the previous user so the next login starts clean.
  Future<void> resetOnLogout() async {
    _goals.clear();
    _goalStreakSummary = null;
    _errorMessage = null;
    _isLoading = false;
    await preferencesService.remove('has_ever_set_goals');
    for (int i = 0; i < 3; i++) {
      await SharedPreferencesStorage.setValue('egg_$i', 'No Egg Goal Set');
      await SharedPreferencesStorage.setBool('egg_${i}_completed', false);
    }
    notifyListeners();
    logDebug('[EggGoalsProvider] Reset on logout');
  }
}
