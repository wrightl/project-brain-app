import 'package:flutter/material.dart';
import 'package:projectbrain/models/strategies/suggested_strategy.dart';
import 'package:projectbrain/services/ai_service.dart';
import 'package:projectbrain/services/strategy_service.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// One turn in the strategies chat: user message + assistant text + optional strategies.
class StrategyChatTurn {
  final String userMessage;
  final String assistantText;
  final List<SuggestedStrategy>? strategies;

  StrategyChatTurn({
    required this.userMessage,
    required this.assistantText,
    this.strategies,
  });
}

/// Provider for the strategies chat flow (send message, stream response, select & save).
class StrategiesChatProvider extends ChangeNotifier {
  final AIService aiService;
  final StrategyService strategyService;

  final List<StrategyChatTurn> _turns = [];
  String? _conversationId;
  bool _isLoading = false;
  String? _errorMessage;
  final Set<SuggestedStrategy> _selectedStrategies = {};

  List<StrategyChatTurn> get turns => List.unmodifiable(_turns);
  String? get conversationId => _conversationId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<SuggestedStrategy> get selectedStrategies =>
      Set<SuggestedStrategy>.from(_selectedStrategies);

  StrategiesChatProvider({
    required this.aiService,
    required this.strategyService,
  });

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    // Guard against concurrent sends while a response is still streaming.
    if (_isLoading) {
      logDebug('[StrategiesChatProvider] Send ignored; response in flight');
      return;
    }
    _errorMessage = null;
    _turns.add(StrategyChatTurn(
      userMessage: content.trim(),
      assistantText: '',
      strategies: null,
    ));
    final turnIndex = _turns.length - 1;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await aiService.streamStrategiesResponse(
        content.trim(),
        conversationId: _conversationId,
      );
      if (result.conversationId != null) {
        _conversationId = result.conversationId;
      }

      String assistantText = '';
      List<SuggestedStrategy>? strategies;

      await for (final event in result.stream) {
        if (event.text != null) {
          assistantText = event.text!;
          _turns[turnIndex] = StrategyChatTurn(
            userMessage: _turns[turnIndex].userMessage,
            assistantText: assistantText,
            strategies: _turns[turnIndex].strategies,
          );
          notifyListeners();
        }
        if (event.strategies != null) {
          strategies = event.strategies;
          _turns[turnIndex] = StrategyChatTurn(
            userMessage: _turns[turnIndex].userMessage,
            assistantText: _turns[turnIndex].assistantText,
            strategies: strategies,
          );
          _selectedStrategies.clear();
          notifyListeners();
        }
      }
    } catch (e) {
      logError('[StrategiesChatProvider] sendMessage failed', e);
      _errorMessage = e is Exception
          ? e.toString()
          : 'Failed to get response. Please try again.';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectStrategy(SuggestedStrategy s) {
    _selectedStrategies.add(s);
    notifyListeners();
  }

  void deselectStrategy(SuggestedStrategy s) {
    _selectedStrategies.remove(s);
    notifyListeners();
  }

  void toggleStrategySelection(SuggestedStrategy s) {
    if (_selectedStrategies.contains(s)) {
      _selectedStrategies.remove(s);
    } else {
      _selectedStrategies.add(s);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedStrategies.clear();
    notifyListeners();
  }

  /// Save selected strategies to the library. Returns number saved; 0 on failure.
  Future<int> saveSelectedStrategies() async {
    if (_selectedStrategies.isEmpty) return 0;
    _errorMessage = null;
    int saved = 0;
    try {
      for (final s in _selectedStrategies) {
        await strategyService.saveStrategy(s.toCreateRequest());
        saved++;
      }
      _selectedStrategies.clear();
      notifyListeners();
      return saved;
    } catch (e) {
      logError('[StrategiesChatProvider] saveSelectedStrategies failed', e);
      _errorMessage =
          e is Exception ? e.toString() : 'Failed to save strategies';
      notifyListeners();
      return 0;
    }
  }

  void startNewConversation() {
    _turns.clear();
    _conversationId = null;
    _selectedStrategies.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetOnLogout() {
    startNewConversation();
    _isLoading = false;
    notifyListeners();
    logDebug('[StrategiesChatProvider] Reset on logout');
  }
}
