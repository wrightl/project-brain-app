import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectbrain/models/citation.dart';

part 'chatmessage.freezed.dart';
part 'chatmessage.g.dart';

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String role, // "user" or "assistant"
    required String content,
    @Default([]) List<Citation> citations,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
