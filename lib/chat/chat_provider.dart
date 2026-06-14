import 'dart:async';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:projectbrain/models/citation.dart';
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
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  Conversation? get activeConversation => _conversation;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  ChatProvider({
    required this.aiService,
    required this.conversationService,
  });

  /// Send a message and stream the response
  Future<void> sendMessage(String text) async {
    // Guard against concurrent sends (double-tap / fire-without-await callers).
    if (_isSending) {
      logDebug('[ChatProvider] Send ignored; a message is already in flight');
      return;
    }
    _isSending = true;
    _errorMessage = null;
    _messages.add(
        const ChatMessage(role: 'user', content: '').copyWith(content: text));
    notifyListeners();

    // Add placeholder assistant message
    _messages.add(const ChatMessage(role: 'assistant', content: ''));
    final assistantMessageIndex = _messages.length - 1;
    notifyListeners();

    StreamSubscription<List<Citation>>? citationsSubscription;
    try {
      final response = await aiService.streamChatResponse(
        text,
        conversationId: _conversation?.id,
      );
      final stream = response.stream;
      final citationsStream = response.citationsStream;
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
        logDebug('[ChatProvider] Created new conversation: $conversationId');
      }

      // Collect citations from stream
      final List<Citation> collectedCitations = [];
      citationsSubscription = citationsStream.listen((citations) {
        collectedCitations.clear();
        collectedCitations.addAll(citations);
        // Update message with current citations
        final currentMessage = _messages[assistantMessageIndex];
        _messages[assistantMessageIndex] = currentMessage.copyWith(
          citations: List.from(collectedCitations),
        );
        notifyListeners();
      });

      // Throttle per-token notifications: rebuilding the whole list on every
      // token is expensive. Coalesce updates to ~16fps; the final state is
      // always flushed by the notifyListeners() after the loop.
      var lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
      const notifyInterval = Duration(milliseconds: 60);
      await for (final chunk in stream) {
        final currentMessage = _messages[assistantMessageIndex];
        _messages[assistantMessageIndex] = currentMessage.copyWith(
          content: currentMessage.content + chunk,
        );
        final now = DateTime.now();
        if (now.difference(lastNotify) >= notifyInterval) {
          lastNotify = now;
          notifyListeners();
        }
      }

      // Final update: ensure citations are set on the message
      final finalMessage = _messages[assistantMessageIndex];
      _messages[assistantMessageIndex] = finalMessage.copyWith(
        citations: List.from(collectedCitations),
      );
      notifyListeners();

      logDebug('[ChatProvider] Message streaming completed');
    } catch (e, stackTrace) {
      logDebug('[ChatProvider] Error streaming: $e');
      logDebug('[ChatProvider] Stack trace: $stackTrace');

      _errorMessage = 'Failed to get response. Please try again.';
      // Update the message to show error
      final currentMessage = _messages[assistantMessageIndex];
      _messages[assistantMessageIndex] = currentMessage.copyWith(
        content: 'Error: $_errorMessage',
      );
      notifyListeners();
    } finally {
      // Always release the citation subscription, even on error/cancel, so it
      // does not leak across sends.
      await citationsSubscription?.cancel();
      _isSending = false;
    }
  }

  /// Fetch all conversations for the current user
  ///
  /// Note: This method returns a Future and should not be called during build.
  /// Use FutureBuilder or call it in initState/didChangeDependencies.
  Future<List<Conversation>> fetchConversations() async {
    try {
      logDebug('[ChatProvider] Fetching conversations...');
      final conversations = await conversationService.getConversations();
      return conversations;
    } catch (e) {
      logDebug('[ChatProvider] Error fetching conversations: $e');
      _errorMessage = 'Failed to load conversations';
      rethrow;
    }
  }

  /// Load a specific conversation by ID
  Future<Conversation> loadConversation(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      logDebug('[ChatProvider] Loading conversation: $id');
      final conversation =
          await conversationService.getConversationWithMessagesById(id);
      _messages.clear();
      _messages.addAll(conversation.messages);
      _conversation = conversation;
      return conversation;
    } catch (e) {
      logDebug('[ChatProvider] Error loading conversation: $e');
      _errorMessage = 'Failed to load conversation';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear the current conversation and start fresh
  void clearConversation() {
    _messages.clear();
    _conversation = null;
    _errorMessage = null;
    notifyListeners();
    logDebug('[ChatProvider] Conversation cleared');
  }

  /// Clear the current error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset all chat state so it does not leak into the next logged-in session.
  void resetOnLogout() {
    _messages.clear();
    _conversation = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
    logDebug('[ChatProvider] Reset on logout');
  }
}
