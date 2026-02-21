import 'dart:convert';
import 'package:projectbrain/services/http_service.dart';
import 'package:projectbrain/models/journal/journal_tag.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Service for user (custom) tags.
class TagService extends HttpService {
  TagService({required super.authService});

  Future<List<JournalTag>> listTags() async {
    final res = await get('/tag', useCache: false);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => JournalTag.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _throwFromResponse(res, 'Failed to load tags');
    }
  }

  Future<JournalTag> createTag(String name) async {
    final res = await post(
      '/tag',
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode == 201) {
      return JournalTag.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else {
      _throwFromResponse(res, 'Failed to create tag');
    }
  }

  Future<JournalTag?> getTagByName(String name) async {
    final encoded = Uri.encodeComponent(name);
    final res = await get('/tag/name/$encoded', useCache: false);
    if (res.statusCode == 200) {
      return JournalTag.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else if (res.statusCode == 404) {
      return null;
    } else {
      _throwFromResponse(res, 'Failed to get tag by name');
    }
  }

  Never _throwFromResponse(dynamic res, String fallback) {
    String message = fallback;
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        message = body['message'] as String;
      } else if (body is Map && body['error'] != null) {
        message = body['error'] as String;
      }
    } catch (_) {}
    logDebug('[TagService] $message (status: ${res.statusCode})');
    throw Exception(message);
  }
}
