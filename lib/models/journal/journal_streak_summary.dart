/// Response from GET /journal/streak-summary.
class JournalStreakSummary {
  final int currentStreak;
  final int longestStreak;

  JournalStreakSummary({
    required this.currentStreak,
    required this.longestStreak,
  });

  factory JournalStreakSummary.fromJson(Map<String, dynamic> json) {
    return JournalStreakSummary(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }
}
