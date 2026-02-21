import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/voice_note.dart';
import 'package:projectbrain/services/http_service.dart';

/// Service for managing voice notes
class VoiceNoteService extends HttpService {
  VoiceNoteService({required super.authService});

  /// Get all voice notes for the current user
  Future<List<VoiceNote>> getVoiceNotes() async {
    logDebug('[VoiceNoteService] Fetching voice notes');

    final response = await get(
      '/voicenotes',
      useCache: false, // Don't cache voice notes list as it changes frequently
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);
      final List<dynamic> items = data is Map && data.containsKey('items')
          ? (data['items'] as List<dynamic>)
          : (data is List ? data : <dynamic>[]);
      final voiceNotes = items
          .map((json) => VoiceNote.fromJson(json as Map<String, dynamic>))
          .toList();
      logDebug('[VoiceNoteService] Fetched ${voiceNotes.length} voice notes');
      return voiceNotes;
    } else {
      logError(
          '[VoiceNoteService] Failed to fetch voice notes: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch voice notes: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Upload a voice note file
  Future<void> uploadVoiceNote(
    File audioFile, {
    String? description,
  }) async {
    logDebug('[VoiceNoteService] Uploading voice note: ${audioFile.path}');

    final token = await authService.getAccessToken();
    final uri = Uri.parse('$baseUrl/voicenotes');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add the audio file to the request
      final fileStream = http.ByteStream(audioFile.openRead());
      final fileLength = await audioFile.length();
      final multipartFile = http.MultipartFile(
        'file', // Field name for the file
        fileStream,
        fileLength,
        filename: audioFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Add description if provided
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }

      final streamedResponse =
          await request.send().timeout(Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        logDebug('[VoiceNoteService] Successfully uploaded voice note');
        // Clear cache for voice notes list
        clearCacheForPath('/voicenotes');
      } else {
        logError(
            '[VoiceNoteService] Failed to upload voice note: ${response.statusCode} ${response.reasonPhrase}');
        throw Exception(
          'Failed to upload voice note: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (error, stackTrace) {
      logError('[VoiceNoteService] Error uploading voice note: $error');
      logDebug('[VoiceNoteService] Stack trace: $stackTrace');
      throw Exception('Failed to upload voice note: $error');
    }
  }

  /// Delete a voice note by ID
  Future<void> deleteVoiceNote(String voiceNoteId) async {
    logDebug('[VoiceNoteService] Deleting voice note: $voiceNoteId');

    final response = await delete('/voicenotes/$voiceNoteId');

    if (response.statusCode == 200 || response.statusCode == 204) {
      logDebug(
          '[VoiceNoteService] Successfully deleted voice note: $voiceNoteId');
      // Clear cache for voice notes list
      clearCacheForPath('/voicenotes');
    } else {
      logError(
          '[VoiceNoteService] Failed to delete voice note: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to delete voice note: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Get the audio URL for a voice note
  /// This URL can be used to stream or download the audio file
  String getVoiceNoteAudioUrl(String voiceNoteId) {
    return '$baseUrl/voicenotes/$voiceNoteId/audio';
  }

  /// Get authentication headers for audio playback
  /// Returns a map with Authorization header for use with audio players
  Future<Map<String, String>> getAudioHeaders() async {
    final token = await authService.getAccessToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  /// Download voice note audio file to a temporary location
  /// Returns the path to the downloaded file
  Future<File> downloadVoiceNoteAudio(String voiceNoteId) async {
    logDebug('[VoiceNoteService] Downloading voice note audio: $voiceNoteId');

    final token = await authService.getAccessToken();
    final uri = Uri.parse('$baseUrl/voicenotes/$voiceNoteId/audio');

    try {
      final request = http.Request('GET', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 120),
          );

      if (streamedResponse.statusCode != 200) {
        throw Exception(
          'Failed to download audio: ${streamedResponse.statusCode} ${streamedResponse.reasonPhrase}',
        );
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/voice_note_$voiceNoteId.m4a');

      // Write the response to file
      final sink = file.openWrite();
      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
      }
      await sink.close();

      logDebug('[VoiceNoteService] Downloaded audio to: ${file.path}');
      return file;
    } catch (error, stackTrace) {
      logError('[VoiceNoteService] Error downloading audio: $error');
      logDebug('[VoiceNoteService] Stack trace: $stackTrace');
      throw Exception('Failed to download voice note audio: $error');
    }
  }
}
