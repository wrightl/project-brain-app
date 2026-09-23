import 'dart:convert';

import 'package:projectbrain/models/community.dart';
import 'package:projectbrain/services/http_service.dart';

class CommunityService {
  final HttpService _httpService;

  CommunityService({required HttpService httpService})
      : _httpService = httpService;

  Future<List<CommunityChannel>> getChannels() async {
    final response = await _httpService.get('/community/channels');
    if (response.statusCode != 200) {
      throw Exception('Failed to load channels');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CommunityChannel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityPostsPage> getPosts(
    String slug, {
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }
    final query = params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final response = await _httpService.get(
      '/community/channels/${Uri.encodeComponent(slug)}/posts?$query',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load posts');
    }
    return CommunityPostsPage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CommunityPostsPage> getLatestFeed({
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }
    final query = params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final response = await _httpService.get('/community/feed?$query');
    if (response.statusCode != 200) {
      throw Exception('Failed to load feed');
    }
    return CommunityPostsPage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CommunityPost> createPost(String slug, String body) async {
    final response = await _httpService.post(
      '/community/channels/${Uri.encodeComponent(slug)}/posts',
      body: jsonEncode({'body': body}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create post');
    }
    return CommunityPost.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deletePost(String id) async {
    final response = await _httpService.delete('/community/posts/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete post');
    }
  }

  Future<void> addReaction(String id) async {
    final response =
        await _httpService.post('/community/posts/$id/reactions');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to react');
    }
  }

  Future<void> removeReaction(String id) async {
    final response =
        await _httpService.delete('/community/posts/$id/reactions');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove reaction');
    }
  }

  Future<void> reportPost(String id, String reason) async {
    final response = await _httpService.post(
      '/community/posts/$id/reports',
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to report post');
    }
  }
}
