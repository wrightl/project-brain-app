import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:projectbrain/services/http_service.dart';

/// Response object for chat streaming
class ChatStreamResponse {
  final Stream<String> stream;
  final String? conversationId;

  ChatStreamResponse({required this.stream, this.conversationId});
}

/// Service for AI chat interactions
class AIService extends HttpService {
  AIService({required super.authService});

  /// Stream chat response from the AI
  Future<ChatStreamResponse> streamChatResponse(
    String text, {
    String? conversationId,
  }) async {
    debugPrint('[AIService] Sending chat message (conversation: $conversationId)');

    final response = await send(
      '/chat/stream',
      jsonEncode({'content': text, 'conversationId': conversationId}),
    );

    debugPrint('[AIService] Received response with status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final convId = response.headers['x-conversation-id'];
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .map((line) {
            if (line.startsWith('data:')) {
              final jsonStr = line.substring(5).trim();
              try {
                final data = jsonDecode(jsonStr);
                return data['value'] ?? '';
              } catch (e) {
                debugPrint('[AIService] Error parsing stream chunk: $e');
                return '';
              }
            }
            return '';
          })
          .where((value) => value.isNotEmpty)
          .cast<String>();

      return ChatStreamResponse(stream: stream, conversationId: convId);
    } else {
      debugPrint(
        '[AIService] Error streaming chat response: ${response.statusCode} ${response.reasonPhrase}',
      );
      throw Exception(
        'Failed to stream chat response: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }
}
