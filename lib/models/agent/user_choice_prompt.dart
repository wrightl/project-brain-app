class UserChoiceOption {
  final String id;
  final String label;

  const UserChoiceOption({
    required this.id,
    required this.label,
  });

  factory UserChoiceOption.fromJson(Map<String, dynamic> json) {
    return UserChoiceOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
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
