/// A learned episode (past experience) stored for the user.
class UserEpisodeMemory {
  final String id;
  final String summary;
  final String topic;
  final String outcome;
  final String status;
  final DateTime createdAt;

  UserEpisodeMemory({
    required this.id,
    required this.summary,
    required this.topic,
    required this.outcome,
    required this.status,
    required this.createdAt,
  });

  factory UserEpisodeMemory.fromJson(Map<String, dynamic> json) {
    return UserEpisodeMemory(
      id: json['id'] as String,
      summary: json['summary'] as String,
      topic: json['topic'] as String? ?? 'general',
      outcome: json['outcome'] as String? ?? 'unknown',
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
