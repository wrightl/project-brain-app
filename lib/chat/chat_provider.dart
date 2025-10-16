// lib/providers/chat_provider.dart
import 'package:flutter/material.dart';
import 'package:projectbrain/models/chatmessage.dart';
import 'package:projectbrain/models/conversation.dart';
import 'package:projectbrain/services/ai_service.dart';
import 'package:projectbrain/services/conversation_service.dart';

class ChatProvider extends ChangeNotifier {
  final AIService aiService;
  final ConversationService conversationService;
  final List<ChatMessage> _messages = [];
  Conversation? _conversation;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  Conversation? get activeConversation => _conversation;

  ChatProvider({required this.aiService, required this.conversationService});

  Future<void> sendMessage(String text) async {
    _messages.add(ChatMessage(role: 'user', content: text));
    notifyListeners();

    final newMessage = ChatMessage(role: 'assistant', content: '');
    _messages.add(newMessage);
    notifyListeners();

    try {
      // Expecting streamChatResponse to return a tuple: (Stream<String> stream, String? conversationId)
      final response = await aiService.streamChatResponse(text,
          conversationId: _conversation?.id);
      final stream = response.stream;
      final conversationId = response.conversationId;

      // If this is a new conversation, create and store it locally
      if (_conversation == null && conversationId != null) {
        _conversation = Conversation(
            id: conversationId,
            title: text,
            userId: '',
            messages: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now());
      }

      await for (final chunk in stream) {
        print('Received chunk: $chunk');
        newMessage.content += chunk;
        notifyListeners();
      }
    } catch (e) {
      print('Error streaming: $e');
    }
  }

  Future<List<Conversation>> fetchConversations() async {
    print('Fetching conversations...');
    return await conversationService.getConversations();
  }

  Future<Conversation> loadConversation(String id) async {
    print('Loading conversation...');
    var conversation =
        await conversationService.getConversationWithMessagesById(id);
    _messages.clear();
    _messages.addAll(conversation.messages);
    _conversation = conversation;
    notifyListeners();
    return conversation;
  }
}
