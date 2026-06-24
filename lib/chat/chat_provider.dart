import 'dart:async';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:projectbrain/models/citation.dart';
import 'package:projectbrain/models/agent/action_card.dart';
import 'package:projectbrain/models/agent/agent_stream_event.dart';
import 'package:projectbrain/models/agent/tool_execution.dart';
import 'package:projectbrain/models/agent/user_choice_prompt.dart';
import 'package:projectbrain/models/chatmessage.dart';
import 'package:projectbrain/models/conversation.dart';
import 'package:projectbrain/services/ai_service.dart';
import 'package:projectbrain/services/conversation_service.dart';
import 'package:projectbrain/services/feature_flag_service.dart';

/// Provider for managing chat state and interactions
class ChatProvider extends ChangeNotifier {
  final AIService aiService;
  final ConversationService conversationService;
  final FeatureFlagService featureFlagService;
  final List<ChatMessage> _messages = [];
  final Map<int, AgentMessageExtras> _messageExtras = {};
  final Set<int> _answeredChoiceMessageIndexes = {};
  Conversation? _conversation;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  AgentMessageExtras messageExtrasFor(int index) =>
      _messageExtras[index] ?? const AgentMessageExtras();
  Conversation? get activeConversation => _conversation;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool isChoiceAnswered(int messageIndex) =>
      _answeredChoiceMessageIndexes.contains(messageIndex);

  ChatProvider({
    required this.aiService,
    required this.conversationService,
    required this.featureFlagService,
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
      if (featureFlagService.agentFeatureEnabled) {
        await _sendViaAgent(text, assistantMessageIndex);
        return;
      }

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

  Future<void> _sendViaAgent(String text, int assistantMessageIndex) async {
    final response = await aiService.streamAgentResponse(
      text,
      conversationId: _conversation?.id,
    );

    if (_conversation == null && response.conversationId != null) {
      _conversation = Conversation(
        id: response.conversationId!,
        title: text,
        userId: '',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final citations = <Citation>[];
    final tools = <ToolExecution>[];
    final cards = <ActionCard>[];
    UserChoicePrompt? userChoices;

    var lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
    const notifyInterval = Duration(milliseconds: 60);

    await for (final event in response.stream) {
      switch (event.type) {
        case 'text':
          final chunk = event.value?.toString() ?? '';
          if (chunk.isEmpty) continue;
          final current = _messages[assistantMessageIndex];
          _messages[assistantMessageIndex] =
              current.copyWith(content: current.content + chunk);
          break;
        case 'citations':
          citations
            ..clear()
            ..addAll(AIService.parseAgentCitations(event.value));
          break;
        case 'tools_executed':
          tools.addAll(AIService.parseToolExecutions(event.value));
          break;
        case 'action_card':
          cards.addAll(AIService.parseActionCards(event.value));
          break;
        case 'pending_action':
          cards.addAll(AIService.parseActionCards(event.value));
          break;
        case 'user_choices':
          userChoices = AIService.parseUserChoices(event.value);
          break;
      }

      final now = DateTime.now();
      if (now.difference(lastNotify) >= notifyInterval) {
        lastNotify = now;
        notifyListeners();
      }
    }

    final current = _messages[assistantMessageIndex];
    var finalContent = current.content;
    if (finalContent.isEmpty) {
      final prompt = userChoices?.prompt?.trim();
      if (prompt != null && prompt.isNotEmpty) {
        finalContent = prompt;
      } else if (userChoices != null) {
        finalContent = 'Please choose an option:';
      } else {
        finalContent = 'Action completed.';
      }
    }

    _messages[assistantMessageIndex] = current.copyWith(
      citations: List.from(citations),
      content: finalContent,
    );
    _messageExtras[assistantMessageIndex] = AgentMessageExtras(
      toolExecutions: List.from(tools),
      actionCards: List.from(cards),
      userChoices: userChoices,
    );
    notifyListeners();
  }

  Future<void> selectUserChoice(int messageIndex, String label) async {
    if (_isSending) return;
    _answeredChoiceMessageIndexes.add(messageIndex);
    notifyListeners();
    await sendMessage(label);
  }

  Future<void> confirmPendingAction(ActionCard card, int messageIndex) async {
    if (card.workflowId == null || card.pendingActionId == null) return;

    final result = await aiService.confirmPendingAgentAction(
      workflowId: card.workflowId!,
      actionId: card.pendingActionId!,
    );

    final extras = _messageExtras[messageIndex] ?? const AgentMessageExtras();
    final remainingCards = extras.actionCards
        .where((c) =>
            !(c.cardType == 'pending_confirmation' &&
                c.pendingActionId == card.pendingActionId))
        .toList();

    final newCards = <ActionCard>[...remainingCards];
    final actionCardsJson = result['actionCards'];
    if (actionCardsJson is List) {
      for (final item in actionCardsJson) {
        if (item is Map) {
          newCards.add(ActionCard.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final tools = List<ToolExecution>.from(extras.toolExecutions);
    final toolJson = result['toolExecution'];
    if (toolJson is Map) {
      tools.add(ToolExecution.fromJson(Map<String, dynamic>.from(toolJson)));
    }

    _messageExtras[messageIndex] = AgentMessageExtras(
      toolExecutions: tools,
      actionCards: newCards,
    );
    notifyListeners();
  }

  Future<void> cancelPendingAction(ActionCard card, int messageIndex) async {
    if (card.workflowId == null || card.pendingActionId == null) return;

    await aiService.cancelPendingAgentAction(
      workflowId: card.workflowId!,
      actionId: card.pendingActionId!,
    );

    final extras = _messageExtras[messageIndex] ?? const AgentMessageExtras();
    _messageExtras[messageIndex] = AgentMessageExtras(
      toolExecutions: extras.toolExecutions,
      actionCards: extras.actionCards
          .where((c) =>
              !(c.cardType == 'pending_confirmation' &&
                  c.pendingActionId == card.pendingActionId))
          .toList(),
    );
    notifyListeners();
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
      _messageExtras.clear();
      _answeredChoiceMessageIndexes.clear();
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
    _messageExtras.clear();
    _answeredChoiceMessageIndexes.clear();
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
    _messageExtras.clear();
    _answeredChoiceMessageIndexes.clear();
    _conversation = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
    logDebug('[ChatProvider] Reset on logout');
  }
}
