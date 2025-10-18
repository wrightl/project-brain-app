import 'package:freezed_annotation/freezed_annotation.dart';

part 'chatmessage.freezed.dart';
part 'chatmessage.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String role, // "user" or "assistant"
    required String content,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
