import 'dart:convert';
import 'package:projectbrain/services/http_service.dart';
import 'package:projectbrain/models/journal/journal_entry.dart';
import 'package:projectbrain/models/journal/journal_request_dtos.dart';
import 'package:projectbrain/models/journal/journal_streak_summary.dart';
import 'package:projectbrain/models/journal/paged_response.dart';
import 'package:projectbrain/models/journal/system_tag.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Service for journal entries and system tags.
class JournalService extends HttpService {
  JournalService({required super.authService});

  Future<JournalEntry> createEntry(JournalCreateRequest request) async {
    final res = await post(
      '/journal',
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 201) {
      return JournalEntry.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else {
      _throwFromResponse(res, 'Failed to create entry');
    }
  }

  Future<JournalEntry> getEntry(String id) async {
    final res = await get('/journal/$id', useCache: false);
    if (res.statusCode == 200) {
      return JournalEntry.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else if (res.statusCode == 404) {
      throw JournalNotFoundException(id);
    } else {
      _throwFromResponse(res, 'Failed to load entry');
    }
  }

  Future<PagedJournalResponse> listEntries(
      {int page = 1, int pageSize = 20}) async {
    final path = '/journal?page=$page&pageSize=$pageSize';
    final res = await get(path, useCache: false);
    if (res.statusCode == 200) {
      return PagedJournalResponse.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else {
      _throwFromResponse(res, 'Failed to load entries');
    }
  }

  Future<int> getEntryCount() async {
    final res = await get('/journal/count', useCache: false);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['count'] as num?)?.toInt() ?? 0;
    } else {
      _throwFromResponse(res, 'Failed to get entry count');
    }
  }

  Future<List<JournalEntry>> getRecentEntries({int count = 3}) async {
    final path = '/journal/recent?count=$count';
    final res = await get(path, useCache: false);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _throwFromResponse(res, 'Failed to load recent entries');
    }
  }

  Future<JournalEntry> updateEntry(
      String id, JournalUpdateRequest request) async {
    final res = await put(
      '/journal/$id',
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 200) {
      return JournalEntry.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else if (res.statusCode == 404) {
      throw JournalNotFoundException(id);
    } else {
      _throwFromResponse(res, 'Failed to update entry');
    }
  }

  Future<void> deleteEntry(String id) async {
    final res = await delete('/journal/$id');
    if (res.statusCode != 204) {
      if (res.statusCode == 404) throw JournalNotFoundException(id);
      _throwFromResponse(res, 'Failed to delete entry');
    }
  }

  Future<List<SystemTag>> getSystemTags() async {
    final res = await get('/journal/system-tags', useCache: false);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => SystemTag.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _throwFromResponse(res, 'Failed to load system tags');
    }
  }

  Future<JournalStreakSummary> getStreakSummary() async {
    final res = await get('/journal/streak-summary', useCache: false);
    if (res.statusCode == 200) {
      return JournalStreakSummary.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else {
      _throwFromResponse(res, 'Failed to load streak summary');
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
    logDebug('[JournalService] $message (status: ${res.statusCode})');
    throw Exception(message);
  }
}

class JournalNotFoundException implements Exception {
  final String id;
  JournalNotFoundException(this.id);
  @override
  String toString() => 'Journal entry not found: $id';
}
