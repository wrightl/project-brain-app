import 'package:projectbrain/models/journal/journal_tag.dart';
import 'package:projectbrain/models/journal/journal_entry_system_tag.dart';

/// A journal entry (list item or full detail).
class JournalEntry {
  final String id;
  final String userId;
  final String content;
  final String? summary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<JournalTag>? tags;
  final List<JournalEntrySystemTag>? systemTags;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.content,
    this.summary,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
    this.systemTags,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: json['tags'] != null
          ? (json['tags'] as List<dynamic>)
              .map((e) => JournalTag.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      systemTags: json['systemTags'] != null
          ? (json['systemTags'] as List<dynamic>)
              .map((e) =>
                  JournalEntrySystemTag.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      if (summary != null) 'summary': summary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (tags != null) 'tags': tags!.map((e) => e.toJson()).toList(),
      if (systemTags != null)
        'systemTags': systemTags!.map((e) => e.toJson()).toList(),
    };
  }
}
