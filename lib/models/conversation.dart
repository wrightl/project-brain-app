import 'package:projectbrain/core/util/json_parsing.dart';
import 'package:projectbrain/models/chatmessage.dart';

class Conversation {
  final String id;
  final String userId;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: JsonParse.asString(json['id']),
      userId: JsonParse.asString(json['userId']),
      title: JsonParse.asString(json['title']),
      messages: json['messages'] is List
          ? (json['messages'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((m) => ChatMessage.fromJson(m))
              .toList()
          : [],
      createdAt: JsonParse.asDateTime(json['createdAt']),
      updatedAt: JsonParse.asDateTime(json['updatedAt']),
    );
  }
}
