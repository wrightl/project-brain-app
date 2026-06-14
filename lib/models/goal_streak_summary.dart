/// Response from GET /eggs/streak-summary.
class GoalStreakSummary {
  final int currentStreak;
  final int longestStreak;

  const GoalStreakSummary({
    required this.currentStreak,
    required this.longestStreak,
  });

  factory GoalStreakSummary.fromJson(Map<String, dynamic> json) {
    return GoalStreakSummary(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
    );
  }
}
