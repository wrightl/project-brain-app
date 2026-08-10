class UserChoiceOption {
  final String id;
  final String label;
  final UserChoiceAction? action;

  const UserChoiceOption({
    required this.id,
    required this.label,
    this.action,
  });

  factory UserChoiceOption.fromJson(Map<String, dynamic> json) {
    UserChoiceAction? action;
    final rawAction = json['action'];
    if (rawAction is Map) {
      action = UserChoiceAction.fromJson(Map<String, dynamic>.from(rawAction));
    }

    return UserChoiceOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      action: action,
    );
  }
}

class UserChoiceAction {
  final String type;
  final String coachProfileId;
  final String? connectionId;

  const UserChoiceAction({
    required this.type,
    required this.coachProfileId,
    this.connectionId,
  });

  factory UserChoiceAction.fromJson(Map<String, dynamic> json) {
    return UserChoiceAction(
      type: json['type'] as String? ?? '',
      coachProfileId: json['coachProfileId'] as String? ?? '',
      connectionId: json['connectionId'] as String?,
    );
  }
}

class UserChoicePrompt {
  final String? prompt;
  final bool allowMultiple;
  final List<UserChoiceOption> options;

  const UserChoicePrompt({
    this.prompt,
    this.allowMultiple = false,
    this.options = const [],
  });

  factory UserChoicePrompt.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions
            .whereType<Map>()
            .map((item) => UserChoiceOption.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .where((option) => option.id.isNotEmpty && option.label.isNotEmpty)
            .toList()
        : <UserChoiceOption>[];

    return UserChoicePrompt(
      prompt: json['prompt'] as String?,
      allowMultiple: json['allowMultiple'] as bool? ?? false,
      options: options,
    );
  }
}
