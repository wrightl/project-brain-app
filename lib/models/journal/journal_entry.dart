import 'package:projectbrain/core/util/json_parsing.dart';
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
      id: JsonParse.asString(json['id']),
      userId: JsonParse.asString(json['userId']),
      content: JsonParse.asString(json['content']),
      summary: JsonParse.asStringOrNull(json['summary']),
      createdAt: JsonParse.asDateTime(json['createdAt']),
      updatedAt: JsonParse.asDateTime(json['updatedAt']),
      tags: json['tags'] is List
          ? (json['tags'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((e) => JournalTag.fromJson(e))
              .toList()
          : null,
      systemTags: json['systemTags'] is List
          ? (json['systemTags'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((e) => JournalEntrySystemTag.fromJson(e))
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
