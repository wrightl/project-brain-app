import 'dart:convert';
// import 'package:projectbrain/authentication/auth_service.dart';
import 'package:projectbrain/services/http_service.dart';

class ChatStreamResponse {
  final Stream<String> stream;
  final String? conversationId;
  ChatStreamResponse({required this.stream, this.conversationId});
}

class AIService extends HttpService {
  AIService({required super.authService});

  Future<ChatStreamResponse> streamChatResponse(String text,
      {String? conversationId}) async {
    print('Sending chat message: $text');
    final response = await send(
      '/chat/stream',
      jsonEncode({'content': text, 'conversationId': conversationId}),
    );

    print('Received response with status: ${response.statusCode}');
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
              } catch (_) {
                return '';
              }
            }
            return '';
          })
          .where((value) => value.isNotEmpty)
          .cast<String>();
      return ChatStreamResponse(stream: stream, conversationId: convId);
    } else {
      print(
          'Error streaming chat response: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
          'Failed to stream chat response: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}
