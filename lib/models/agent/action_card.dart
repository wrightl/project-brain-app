class ActionCard {
  final String cardType;
  final String? href;
  final String? label;
  final String? title;
  final String? description;
  final String? filename;
  final String? message;
  final String? entryId;
  final String? summary;
  final int? currentStreak;
  final int? longestStreak;
  final String? pendingActionId;
  final String? workflowId;
  final String? toolName;
  final String? preview;
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> coaches;

  const ActionCard({
    required this.cardType,
    this.href,
    this.label,
    this.title,
    this.description,
    this.filename,
    this.message,
    this.entryId,
    this.summary,
    this.currentStreak,
    this.longestStreak,
    this.pendingActionId,
    this.workflowId,
    this.toolName,
    this.preview,
    this.goals = const [],
    this.coaches = const [],
  });

  factory ActionCard.fromJson(Map<String, dynamic> json) {
    return ActionCard(
      cardType: json['cardType'] as String? ?? '',
      href: json['href'] as String?,
      label: json['label'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      filename: json['filename'] as String?,
      message: json['message'] as String?,
      entryId: json['entryId'] as String?,
      summary: json['summary'] as String?,
      currentStreak: json['currentStreak'] as int?,
      longestStreak: json['longestStreak'] as int?,
      pendingActionId: json['pendingActionId'] as String?,
      workflowId: json['workflowId'] as String?,
      toolName: json['toolName'] as String?,
      preview: json['preview'] as String?,
      goals: (json['goals'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      coaches: (json['coaches'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }
}
