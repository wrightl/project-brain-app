import 'package:flutter/material.dart';
import 'package:projectbrain/models/strategies/coping_strategy_library_item.dart';
import 'package:projectbrain/models/strategies/create_coping_strategy_request.dart';
import 'package:projectbrain/models/strategies/update_coping_strategy_rating_request.dart';
import 'package:projectbrain/services/strategy_service.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Provider for the coping strategies library (list, load, save, delete, rating).
class StrategiesProvider extends ChangeNotifier {
  final StrategyService strategyService;

  List<CopingStrategyLibraryItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CopingStrategyLibraryItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StrategiesProvider({required this.strategyService});

  Future<void> loadLibrary() async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final res = await strategyService.getLibrary();
      _items = res.items;
    } catch (e) {
      logError('[StrategiesProvider] loadLibrary failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to load library';
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CopingStrategyLibraryItem?> saveStrategy(
      CreateCopingStrategyRequest request) async {
    _errorMessage = null;
    try {
      final item = await strategyService.saveStrategy(request);
      _items = [item, ..._items];
      notifyListeners();
      return item;
    } catch (e) {
      logError('[StrategiesProvider] saveStrategy failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to save strategy';
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteStrategy(String id) async {
    _errorMessage = null;
    try {
      await strategyService.deleteStrategy(id);
      _items = _items.where((e) => e.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      logError('[StrategiesProvider] deleteStrategy failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to delete';
      notifyListeners();
      return false;
    }
  }

  Future<CopingStrategyLibraryItem?> updateRating(String id, int rating) async {
    _errorMessage = null;
    if (rating < 1 || rating > 5) return null;
    try {
      final item = await strategyService.updateRating(
          id, UpdateCopingStrategyRatingRequest(rating: rating));
      final index = _items.indexWhere((e) => e.id == id);
      if (index >= 0) {
        _items = [..._items]..[index] = item;
      }
      notifyListeners();
      return item;
    } catch (e) {
      logError('[StrategiesProvider] updateRating failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to update rating';
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
