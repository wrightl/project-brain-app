import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/resource.dart';
import 'package:projectbrain/services/http_service.dart';

/// Service for managing user resources (files)
class ResourceService extends HttpService {
  ResourceService({required super.authService});

  /// Get all resources for the current user
  Future<List<Resource>> getResources() async {
    logDebug('[ResourceService] Fetching resources');

    final response = await get(
      '/resource/user',
      useCache: false, // Don't cache resource list as it changes frequently
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final List<dynamic> data = jsonDecode(body);
      final resources = data.map((json) => Resource.fromJson(json)).toList();
      logDebug('[ResourceService] Fetched ${resources.length} resources');
      return resources;
    } else {
      logError(
          '[ResourceService] Failed to fetch resources: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch resources: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Upload one or more files
  Future<void> uploadFiles(List<File> files) async {
    logDebug('[ResourceService] Uploading ${files.length} file(s)');

    final token = await authService.getAccessToken();
    final uri = Uri.parse('$baseUrl/resource/upload/user');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add all files to the request
      for (final file in files) {
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();
        final multipartFile = http.MultipartFile(
          'files', // Field name for files
          fileStream,
          fileLength,
          filename: file.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse =
          await request.send().timeout(Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        logDebug(
            '[ResourceService] Successfully uploaded ${files.length} file(s)');
        // Clear cache for resource list
        clearCacheForPath('/resource/user');
      } else {
        logError(
            '[ResourceService] Failed to upload files: ${response.statusCode} ${response.reasonPhrase}');
        throw Exception(
          'Failed to upload files: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (error, stackTrace) {
      logError('[ResourceService] Error uploading files: $error');
      logDebug('[ResourceService] Stack trace: $stackTrace');
      throw Exception('Failed to upload files: $error');
    }
  }

  /// Delete a resource by ID
  Future<void> deleteResource(String resourceId) async {
    logDebug('[ResourceService] Deleting resource: $resourceId');

    final response = await delete('/resource/user/$resourceId');

    if (response.statusCode == 200 || response.statusCode == 204) {
      logDebug('[ResourceService] Successfully deleted resource: $resourceId');
      // Clear cache for resource list
      clearCacheForPath('/resource/user');
    } else {
      logError(
          '[ResourceService] Failed to delete resource: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to delete resource: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }
}
