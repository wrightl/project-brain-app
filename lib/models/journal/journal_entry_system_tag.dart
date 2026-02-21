/// System tag as stored on a journal entry (with optional responses).
class JournalEntrySystemTag {
  final String id;
  final String key;
  final String name;
  final Map<String, dynamic>? responses;

  JournalEntrySystemTag({
    required this.id,
    required this.key,
    required this.name,
    this.responses,
  });

  factory JournalEntrySystemTag.fromJson(Map<String, dynamic> json) {
    return JournalEntrySystemTag(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
      responses: json['responses'] != null
          ? Map<String, dynamic>.from(json['responses'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'name': name,
      if (responses != null) 'responses': responses,
    };
  }
}
