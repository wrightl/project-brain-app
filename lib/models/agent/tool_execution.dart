class ToolExecution {
  final String toolName;
  final Map<String, dynamic> parameters;
  final dynamic result;
  final bool success;
  final String? errorMessage;
  final String? executedAt;

  const ToolExecution({
    required this.toolName,
    this.parameters = const {},
    this.result,
    required this.success,
    this.errorMessage,
    this.executedAt,
  });

  factory ToolExecution.fromJson(Map<String, dynamic> json) {
    return ToolExecution(
      toolName: json['toolName'] as String? ?? '',
      parameters: Map<String, dynamic>.from(
        json['parameters'] as Map? ?? const {},
      ),
      result: json['result'],
      success: json['success'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      executedAt: json['executedAt'] as String?,
    );
  }

  String get displayName {
    const names = {
      'create_daily_goals': 'Created daily goals',
      'create_goals_for_days': 'Planned goals for multiple days',
      'get_todays_goals': "Retrieved today's goals",
      'complete_goal': 'Updated goal',
      'suggest_coping_strategies': 'Suggested coping strategies',
      'save_coping_strategy': 'Saved coping strategy',
      'get_coping_strategies': 'Retrieved coping strategies',
      'rate_coping_strategy': 'Rated coping strategy',
      'upload_knowledge_document': 'Uploaded knowledge document',
      'list_knowledge_resources': 'Listed knowledge resources',
      'delete_knowledge_resource': 'Deleted knowledge resource',
      'search_coaches': 'Searched coaches',
      'get_connected_coaches': 'Retrieved connected coaches',
    };
    return names[toolName] ?? toolName;
  }
}
