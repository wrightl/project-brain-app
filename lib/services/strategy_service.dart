import 'dart:convert';
import 'package:projectbrain/services/http_service.dart';
import 'package:projectbrain/models/strategies/coping_strategy_library_item.dart';
import 'package:projectbrain/models/strategies/coping_strategy_library_response.dart';
import 'package:projectbrain/models/strategies/create_coping_strategy_request.dart';
import 'package:projectbrain/models/strategies/update_coping_strategy_rating_request.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Service for coping strategies library and API.
class StrategyService extends HttpService {
  StrategyService({required super.authService});

  Future<CopingStrategyLibraryResponse> getLibrary() async {
    final res = await get('/strategies/library', useCache: false);
    if (res.statusCode == 200) {
      return CopingStrategyLibraryResponse.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else {
      _throwFromResponse(res, 'Failed to load strategies library');
    }
  }

  Future<CopingStrategyLibraryItem> saveStrategy(
      CreateCopingStrategyRequest request) async {
    final res = await post(
      '/strategies',
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 200) {
      return CopingStrategyLibraryItem.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else {
      _throwFromResponse(res, 'Failed to save strategy');
    }
  }

  Future<void> deleteStrategy(String id) async {
    final res = await delete('/strategies/$id');
    if (res.statusCode != 204) {
      if (res.statusCode == 404) throw StrategyNotFoundException(id);
      _throwFromResponse(res, 'Failed to delete strategy');
    }
  }

  Future<CopingStrategyLibraryItem> updateRating(
      String id, UpdateCopingStrategyRatingRequest request) async {
    final res = await put(
      '/strategies/$id/rating',
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 200) {
      return CopingStrategyLibraryItem.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else if (res.statusCode == 404) {
      throw StrategyNotFoundException(id);
    } else {
      _throwFromResponse(res, 'Failed to update rating');
    }
  }

  Never _throwFromResponse(dynamic res, String fallback) {
    String message = fallback;
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        message = body['message'] as String;
      } else if (body is Map && body['error'] != null) {
        message = body['error'] is String
            ? body['error'] as String
            : (body['error']?.toString() ?? fallback);
      }
    } catch (_) {}
    logDebug('[StrategyService] $message (status: ${res.statusCode})');
    throw Exception(message);
  }
}

class StrategyNotFoundException implements Exception {
  final String id;
  StrategyNotFoundException(this.id);
  @override
  String toString() => 'Strategy not found: $id';
}
