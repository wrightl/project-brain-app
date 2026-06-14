import 'dart:convert';
import 'package:projectbrain/services/http_service.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/goal_streak_summary.dart';

/// Service for managing egg goals (daily goals) via API
class EggGoalsService extends HttpService {
  EggGoalsService({required super.authService});

  /// Fetch egg goals from the API
  Future<List<Map<String, dynamic>>> fetchEggGoals() async {
    try {
      final res = await get('/eggs', useCache: false);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('goals')) {
          return List<Map<String, dynamic>>.from(data['goals']);
        }
        return [];
      } else {
        logWarning(
            '[EggGoalsService] Failed to fetch goals: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      logError('[EggGoalsService] Error fetching goals', e);
      return [];
    }
  }

  /// Sync egg goals - fetch from API and return formatted data
  Future<List<Map<String, dynamic>>> syncEggGoals() async {
    return await fetchEggGoals();
  }

  /// Mark a goal as completed via API
  Future<bool> completeEggGoal(int index, bool completed) async {
    try {
      final res = await post(
        '/eggs/$index/complete',
        body: jsonEncode({'completed': completed}),
      );
      return res.statusCode == 200;
    } catch (e) {
      logError('[EggGoalsService] Error completing goal', e);
      return false;
    }
  }

  /// Save/update egg goals via API
  Future<bool> saveEggGoals(List<String> goals) async {
    try {
      logDebug('[EggGoalsService] Saving ${goals.length} goals');
      final res = await post(
        '/eggs',
        body: jsonEncode({
          'goals': goals,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logError('[EggGoalsService] Error saving goals', e);
      return false;
    }
  }

  /// AI-suggested goals for today (GET /eggs/suggestions).
  Future<List<String>> fetchGoalSuggestions() async {
    try {
      final res = await get('/eggs/suggestions', useCache: false);
      if (res.statusCode != 200) {
        logDebug(
            '[EggGoalsService] Failed to fetch suggestions: ${res.statusCode}');
        return [];
      }
      final data = jsonDecode(res.body);
      if (data is Map && data['goals'] is List) {
        return (data['goals'] as List)
            .map((e) => e?.toString().trim() ?? '')
            .where((s) => s.isNotEmpty)
            .take(3)
            .toList();
      }
      return [];
    } catch (e) {
      logError('[EggGoalsService] Error fetching goal suggestions', e);
      return [];
    }
  }

  /// Goal completion streak summary (GET /eggs/streak-summary).
  Future<GoalStreakSummary> getStreakSummary() async {
    final res = await get('/eggs/streak-summary', useCache: false);
    if (res.statusCode == 200) {
      return GoalStreakSummary.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    logWarning(
        '[EggGoalsService] Failed to fetch streak summary: ${res.statusCode}');
    throw Exception('Failed to load goal streak summary');
  }

  /// Check if user has ever created goals via API
  Future<bool> hasEverCreatedGoals() async {
    try {
      logDebug('[EggGoalsService] Checking if user has ever created goals');
      final res = await get('/eggs/has-ever-created');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Handle different response formats
        if (data is bool) {
          return data;
        } else if (data is Map && data.containsKey('hasEverCreated')) {
          return data['hasEverCreated'] as bool? ?? false;
        } else if (data is Map && data.containsKey('has_ever_created')) {
          return data['has_ever_created'] as bool? ?? false;
        }
        return false;
      } else {
        logDebug(
            '[EggGoalsService] Failed to check has ever created: ${res.statusCode}');
        return false;
      }
    } catch (e) {
      logError('[EggGoalsService] Error checking has ever created', e);
      return false;
    }
  }
}
