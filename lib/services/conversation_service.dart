import 'dart:convert';
import 'package:projectbrain/models/chatmessage.dart';
import 'package:projectbrain/services/http_service.dart';
import 'package:projectbrain/models/conversation.dart';

class ConversationService extends HttpService {
  ConversationService({required super.authService});

  Future<List<Conversation>> getConversations() async {
    final response = await get(
      '/conversation',
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);
      final List<dynamic> items = data is Map && data.containsKey('items')
          ? (data['items'] as List<dynamic>)
          : (data is List ? data : <dynamic>[]);
      return items
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to fetch conversations: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  Future<List<ChatMessage>> getMessagesByConversationId(String id) async {
    final response = await get(
      '/conversation/$id/messages',
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final List<dynamic> data = jsonDecode(body);
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to fetch conversations: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  Future<Conversation> getConversationWithMessagesById(String id) async {
    final conversationResponse = await get(
      '/conversation/$id',
    );

    final messagesResponse = await get(
      '/conversation/$id/messages',
    );

    if (conversationResponse.statusCode == 200 &&
        messagesResponse.statusCode == 200) {
      final body = conversationResponse.body;
      final dynamic data = jsonDecode(body);
      final conv = Conversation.fromJson(data);
      if (conv.messages.isEmpty) {
        final List<dynamic> messagesData = jsonDecode(messagesResponse.body);
        conv.messages.addAll(
            messagesData.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList());
      }
      return conv;
    } else {
      throw Exception(
          'Failed to fetch conversations: ${conversationResponse.statusCode} ${conversationResponse.reasonPhrase}');
    }
  }
}
