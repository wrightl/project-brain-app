import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
      final data = jsonDecode(body);
      final List<dynamic> items = data is Map && data.containsKey('items')
          ? (data['items'] as List<dynamic>)
          : (data is List ? data : <dynamic>[]);
      final resources = items
          .map((json) => Resource.fromJson(json as Map<String, dynamic>))
          .toList();
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

  /// Whether [file] has at least one way to read bytes for upload (path, in-memory bytes, or sized stream).
  static bool platformFileHasReadableData(PlatformFile file) {
    if (file.path != null && file.path!.isNotEmpty) return true;
    if (file.bytes != null) return true;
    if (file.readStream != null && file.size > 0) return true;
    return false;
  }

  static String _uploadFilename(PlatformFile file) {
    final n = file.name.trim();
    return n.isEmpty ? 'upload.bin' : n;
  }

  static Future<http.MultipartFile> _multipartFromPlatformFile(
      PlatformFile file) async {
    final filename = _uploadFilename(file);
    if (file.path != null && file.path!.isNotEmpty) {
      final f = File(file.path!);
      final length = await f.length();
      return http.MultipartFile(
        'files',
        http.ByteStream(f.openRead()),
        length,
        filename: filename,
      );
    }
    if (file.bytes != null) {
      return http.MultipartFile.fromBytes(
        'files',
        file.bytes!,
        filename: filename,
      );
    }
    if (file.readStream != null && file.size > 0) {
      return http.MultipartFile(
        'files',
        http.ByteStream(file.readStream!),
        file.size,
        filename: filename,
      );
    }
    throw Exception(
      'Could not read file data for "$filename" (no path, bytes, or readable stream).',
    );
  }

  /// Upload files picked via [file_picker] (supports path, [PlatformFile.bytes], or [PlatformFile.readStream]).
  Future<void> uploadPlatformFiles(List<PlatformFile> files) async {
    if (files.isEmpty) {
      throw ArgumentError('No files to upload');
    }
    logDebug('[ResourceService] Uploading ${files.length} file(s)');

    final token = await authService.getAccessToken();
    final uri = Uri.parse('$baseUrl/resource/upload/user');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      for (final file in files) {
        request.files.add(await _multipartFromPlatformFile(file));
      }

      final streamedResponse =
          await request.send().timeout(Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        logDebug(
            '[ResourceService] Successfully uploaded ${files.length} file(s)');
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

  /// Upload one or more local [File]s (e.g. from recording or cache).
  Future<void> uploadFiles(List<File> files) async {
    if (files.isEmpty) {
      throw ArgumentError('No files to upload');
    }
    final platformFiles = <PlatformFile>[];
    for (final file in files) {
      final len = await file.length();
      final segments = file.path.replaceAll('\\', '/').split('/');
      final base = segments.isNotEmpty ? segments.last : '';
      final name = base.isEmpty ? 'upload.bin' : base;
      platformFiles.add(
        PlatformFile(path: file.path, name: name, size: len),
      );
    }
    await uploadPlatformFiles(platformFiles);
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
