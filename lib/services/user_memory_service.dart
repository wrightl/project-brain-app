import 'dart:convert';
import 'package:projectbrain/models/user_memory/user_memory_list.dart';
import 'package:projectbrain/services/http_service.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Service for learned user memories (facts and episodes).
class UserMemoryService extends HttpService {
  UserMemoryService({required super.authService});

  Future<UserMemoryList> listMemories() async {
    final res = await get('/user/memory', useCache: false);
    if (res.statusCode == 200) {
      return UserMemoryList.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    _throwFromResponse(res, 'Failed to load learned memories');
  }

  Future<void> deleteFact(String id) async {
    final res = await delete('/user/memory/facts/$id');
    if (res.statusCode != 204) {
      if (res.statusCode == 404) {
        throw UserMemoryNotFoundException(id);
      }
      _throwFromResponse(res, 'Failed to delete memory');
    }
  }

  Future<void> deleteEpisode(String id) async {
    final res = await delete('/user/memory/episodes/$id');
    if (res.statusCode != 204) {
      if (res.statusCode == 404) {
        throw UserMemoryNotFoundException(id);
      }
      _throwFromResponse(res, 'Failed to delete memory');
    }
  }

  Future<void> pinFact(String id) async {
    final res = await post('/user/memory/facts/$id/pin');
    if (res.statusCode != 204) {
      _throwFromResponse(res, 'Failed to pin memory');
    }
  }

  Future<void> unpinFact(String id) async {
    final res = await post('/user/memory/facts/$id/unpin');
    if (res.statusCode != 204) {
      _throwFromResponse(res, 'Failed to unpin memory');
    }
  }

  Future<void> pinEpisode(String id) async {
    final res = await post('/user/memory/episodes/$id/pin');
    if (res.statusCode != 204) {
      _throwFromResponse(res, 'Failed to pin memory');
    }
  }

  Future<void> unpinEpisode(String id) async {
    final res = await post('/user/memory/episodes/$id/unpin');
    if (res.statusCode != 204) {
      _throwFromResponse(res, 'Failed to unpin memory');
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
    logDebug('[UserMemoryService] $message (status: ${res.statusCode})');
    throw Exception(message);
  }
}

class UserMemoryNotFoundException implements Exception {
  final String id;
  UserMemoryNotFoundException(this.id);

  @override
  String toString() => 'Memory not found: $id';
}
