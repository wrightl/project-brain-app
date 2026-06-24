import 'package:flutter/material.dart';
import 'package:projectbrain/models/user_memory/user_episode_memory.dart';
import 'package:projectbrain/models/user_memory/user_fact_memory.dart';
import 'package:projectbrain/services/user_memory_service.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Provider for learned memories (load and delete).
class UserMemoryProvider extends ChangeNotifier {
  final UserMemoryService userMemoryService;

  List<UserFactMemory> _facts = [];
  List<UserEpisodeMemory> _episodes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserFactMemory> get facts => List.unmodifiable(_facts);
  List<UserEpisodeMemory> get episodes => List.unmodifiable(_episodes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _facts.isEmpty && _episodes.isEmpty;

  UserMemoryProvider({required this.userMemoryService});

  Future<void> loadMemories() async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final list = await userMemoryService.listMemories();
      _facts = list.facts;
      _episodes = list.episodes;
    } catch (e) {
      logError('[UserMemoryProvider] loadMemories failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to load memories';
      _facts = [];
      _episodes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteFact(String id) async {
    _errorMessage = null;
    try {
      await userMemoryService.deleteFact(id);
      _facts = _facts.where((f) => f.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      logError('[UserMemoryProvider] deleteFact failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to delete memory';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEpisode(String id) async {
    _errorMessage = null;
    try {
      await userMemoryService.deleteEpisode(id);
      _episodes = _episodes.where((e) => e.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      logError('[UserMemoryProvider] deleteEpisode failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to delete memory';
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePinFact(String id, {required bool pin}) async {
    _errorMessage = null;
    try {
      if (pin) {
        await userMemoryService.pinFact(id);
      } else {
        await userMemoryService.unpinFact(id);
      }
      _facts = _facts
          .map((f) => f.id == id ? f.copyWith(isPinned: pin) : f)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      logError('[UserMemoryProvider] togglePinFact failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to update memory';
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePinEpisode(String id, {required bool pin}) async {
    _errorMessage = null;
    try {
      if (pin) {
        await userMemoryService.pinEpisode(id);
      } else {
        await userMemoryService.unpinEpisode(id);
      }
      _episodes = _episodes
          .map((e) => e.id == id ? e.copyWith(isPinned: pin) : e)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      logError('[UserMemoryProvider] togglePinEpisode failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to update memory';
      notifyListeners();
      return false;
    }
  }

  void resetOnLogout() {
    _facts = [];
    _episodes = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
    logDebug('[UserMemoryProvider] Reset on logout');
  }
}
