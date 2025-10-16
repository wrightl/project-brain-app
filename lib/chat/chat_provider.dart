import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:projectbrain/models/chatmessage.dart';
import 'package:projectbrain/models/conversation.dart';
import 'package:projectbrain/services/ai_service.dart';
import 'package:projectbrain/services/conversation_service.dart';

/// Provider for managing chat state and interactions
class ChatProvider extends ChangeNotifier {
  final AIService aiService;
  final ConversationService conversationService;
  final List<ChatMessage> _messages = [];
  Conversation? _conversation;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  Conversation? get activeConversation => _conversation;

  ChatProvider({
    required this.aiService,
    required this.conversationService,
  });

  /// Send a message and stream the response
  Future<void> sendMessage(String text) async {
    _messages.add(ChatMessage(role: 'user', content: text));
    notifyListeners();

    final newMessage = ChatMessage(role: 'assistant', content: '');
    _messages.add(newMessage);
    notifyListeners();

    try {
      final response = await aiService.streamChatResponse(
        text,
        conversationId: _conversation?.id,
      );
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
          updatedAt: DateTime.now(),
        );
        debugPrint('[ChatProvider] Created new conversation: $conversationId');
      }

      await for (final chunk in stream) {
        newMessage.content += chunk;
        notifyListeners();
      }

      debugPrint('[ChatProvider] Message streaming completed');
    } catch (e, stackTrace) {
      debugPrint('[ChatProvider] Error streaming: $e');
      debugPrint('[ChatProvider] Stack trace: $stackTrace');

      // Update the message to show error
      newMessage.content = 'Error: Failed to get response. Please try again.';
      notifyListeners();
    }
  }

  /// Fetch all conversations for the current user
  Future<List<Conversation>> fetchConversations() async {
    debugPrint('[ChatProvider] Fetching conversations...');
    return await conversationService.getConversations();
  }

  /// Load a specific conversation by ID
  Future<Conversation> loadConversation(String id) async {
    debugPrint('[ChatProvider] Loading conversation: $id');
    final conversation =
        await conversationService.getConversationWithMessagesById(id);
    _messages.clear();
    _messages.addAll(conversation.messages);
    _conversation = conversation;
    notifyListeners();
    return conversation;
  }

  /// Clear the current conversation and start fresh
  void clearConversation() {
    _messages.clear();
    _conversation = null;
    notifyListeners();
    debugPrint('[ChatProvider] Conversation cleared');
  }
}
