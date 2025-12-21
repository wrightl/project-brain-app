import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/services/http_service.dart';

/// Service for managing coaches and coach interactions
class CoachService extends HttpService {
  CoachService({required super.authService});

  /// Get all coaches
  Future<List<Coach>> getCoaches() async {
    logDebug('[CoachService] Fetching coaches');

    final response = await get(
      '/coaches',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final List<dynamic> data = jsonDecode(body);
      final coaches = data.map((json) => Coach.fromJson(json)).toList();
      logDebug('[CoachService] Fetched ${coaches.length} coaches');
      return coaches;
    } else {
      logError(
          '[CoachService] Failed to fetch coaches: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch coaches: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Get connected coaches (coaches the user has an active connection with)
  Future<List<Coach>> getConnectedCoaches() async {
    logDebug('[CoachService] Fetching connected coaches');

    final response = await get(
      '/coaches/connected',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final List<dynamic> data = jsonDecode(body);
      final coaches = data.map((json) => Coach.fromJson(json)).toList();
      logDebug('[CoachService] Fetched ${coaches.length} connected coaches');
      return coaches;
    } else {
      logError(
          '[CoachService] Failed to fetch connected coaches: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch connected coaches: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Search for coaches by postcode, address, location, neurodiverse traits, or age groups
  Future<List<Coach>> searchCoaches({
    String? postcode,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? neurodiverseTraits,
    List<String>? ageGroups,
  }) async {
    logDebug('[CoachService] Searching coaches');

    final queryParams = <String, String>{};
    if (postcode != null && postcode.isNotEmpty) {
      queryParams['postcode'] = postcode;
    }
    if (address != null && address.isNotEmpty) {
      queryParams['address'] = address;
    }
    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
    }
    if (neurodiverseTraits != null && neurodiverseTraits.isNotEmpty) {
      queryParams['neurodiverseTraits'] = neurodiverseTraits.join(',');
    }
    if (ageGroups != null && ageGroups.isNotEmpty) {
      queryParams['ageGroups'] = ageGroups.join(',');
    }

    final queryString = queryParams.isEmpty
        ? ''
        : '?${Uri(queryParameters: queryParams).query}';

    final response = await get(
      '/coaches/search$queryString',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final List<dynamic> data = jsonDecode(body);
      final coaches = data.map((json) => Coach.fromJson(json)).toList();
      logDebug('[CoachService] Found ${coaches.length} coaches');
      return coaches;
    } else {
      logError(
          '[CoachService] Failed to search coaches: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to search coaches: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Get messages with a specific coach
  Future<List<CoachMessage>> getMessages(String coachId) async {
    logDebug('[CoachService] Fetching messages for coach: $coachId');

    final response = await get(
      '/coaches/$coachId/messages',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final List<dynamic> data = jsonDecode(body);
      final messages = data.map((json) => CoachMessage.fromJson(json)).toList();
      logDebug('[CoachService] Fetched ${messages.length} messages');
      return messages;
    } else {
      logError(
          '[CoachService] Failed to fetch messages: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch messages: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Send a text message to a coach
  Future<CoachMessage> sendTextMessage(String coachId, String text) async {
    logDebug('[CoachService] Sending text message to coach: $coachId');

    final response = await post(
      '/coaches/$coachId/messages',
      body: jsonEncode({
        'text': text,
        'messageType': 'text',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.body;
      final data = jsonDecode(body);
      final message = CoachMessage.fromJson(data);
      logDebug('[CoachService] Message sent successfully');
      return message;
    } else {
      logError(
          '[CoachService] Failed to send message: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to send message: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Send an audio message to a coach
  Future<CoachMessage> sendAudioMessage(String coachId, File audioFile) async {
    logDebug('[CoachService] Sending audio message to coach: $coachId');

    final token = await authService.getAccessToken();
    final uri = Uri.parse('$baseUrl/coaches/$coachId/messages/audio');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final fileStream = http.ByteStream(audioFile.openRead());
      final fileLength = await audioFile.length();
      final multipartFile = http.MultipartFile(
        'audio',
        fileStream,
        fileLength,
        filename: audioFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      final streamedResponse =
          await request.send().timeout(Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        final data = jsonDecode(body);
        final message = CoachMessage.fromJson(data);
        logDebug('[CoachService] Audio message sent successfully');
        return message;
      } else {
        logError(
            '[CoachService] Failed to send audio message: ${response.statusCode} ${response.reasonPhrase}');
        throw Exception(
          'Failed to send audio message: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (error, stackTrace) {
      logError('[CoachService] Error sending audio message: $error');
      logDebug('[CoachService] Stack trace: $stackTrace');
      throw Exception('Failed to send audio message: $error');
    }
  }

  /// Send a file to a coach
  Future<CoachMessage> sendFile(String coachId, File file) async {
    logDebug('[CoachService] Sending file to coach: $coachId');

    final token = await authService.getAccessToken();
    final uri = Uri.parse('$baseUrl/coaches/$coachId/messages/file');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      final streamedResponse =
          await request.send().timeout(Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        final data = jsonDecode(body);
        final message = CoachMessage.fromJson(data);
        logDebug('[CoachService] File sent successfully');
        return message;
      } else {
        logError(
            '[CoachService] Failed to send file: ${response.statusCode} ${response.reasonPhrase}');
        throw Exception(
          'Failed to send file: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (error, stackTrace) {
      logError('[CoachService] Error sending file: $error');
      logDebug('[CoachService] Stack trace: $stackTrace');
      throw Exception('Failed to send file: $error');
    }
  }

  /// Send a photo to a coach
  Future<CoachMessage> sendPhoto(String coachId, File imageFile) async {
    logDebug('[CoachService] Sending photo to coach: $coachId');

    final token = await authService.getAccessToken();
    final uri = Uri.parse('$baseUrl/coaches/$coachId/messages/photo');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'photo',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      final streamedResponse =
          await request.send().timeout(Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        final data = jsonDecode(body);
        final message = CoachMessage.fromJson(data);
        logDebug('[CoachService] Photo sent successfully');
        return message;
      } else {
        logError(
            '[CoachService] Failed to send photo: ${response.statusCode} ${response.reasonPhrase}');
        throw Exception(
          'Failed to send photo: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (error, stackTrace) {
      logError('[CoachService] Error sending photo: $error');
      logDebug('[CoachService] Stack trace: $stackTrace');
      throw Exception('Failed to send photo: $error');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String coachId, String messageId) async {
    logDebug('[CoachService] Deleting message: $messageId');

    final response = await delete('/coaches/$coachId/messages/$messageId');

    if (response.statusCode == 200 || response.statusCode == 204) {
      logDebug('[CoachService] Successfully deleted message: $messageId');
    } else {
      logError(
          '[CoachService] Failed to delete message: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to delete message: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Get a specific coach by ID
  Future<Coach> getCoachById(String coachId) async {
    logDebug('[CoachService] Fetching coach: $coachId');

    final response = await get(
      '/coaches/$coachId',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);
      final coach = Coach.fromJson(data);
      logDebug('[CoachService] Fetched coach: ${coach.fullName}');
      return coach;
    } else {
      logError(
          '[CoachService] Failed to fetch coach: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch coach: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Get the connection status between the current user and a coach
  /// API Endpoint: GET /coaches/{coachId}/connection-status
  Future<ConnectionStatus> getConnectionStatus(String coachId) async {
    logDebug('[CoachService] Getting connection status for coach: $coachId');

    final response = await get(
      '/coaches/$coachId/connection-status',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);
      final statusString = data['status'] ?? data['Status'] ?? 'none';
      final status = ConnectionStatus.fromString(statusString.toString());
      logDebug('[CoachService] Connection status: ${status.displayName}');
      return status;
    } else if (response.statusCode == 404) {
      // No connection exists yet
      logDebug('[CoachService] No connection found, returning none');
      return ConnectionStatus.none;
    } else {
      logError(
          '[CoachService] Failed to get connection status: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to get connection status: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Send a connection request to a coach
  /// API Endpoint: POST /coaches/{coachId}/connections
  Future<void> sendConnectionRequest(String coachId) async {
    logDebug('[CoachService] Sending connection request to coach: $coachId');

    final response = await post(
      '/coaches/$coachId/connections',
      body: jsonEncode({}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      logDebug('[CoachService] Connection request sent successfully');
    } else {
      logError(
          '[CoachService] Failed to send connection request: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to send connection request: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Cancel or remove a connection request to a coach
  /// API Endpoint: DELETE /coaches/{coachId}/connections
  Future<void> cancelConnectionRequest(String coachId) async {
    logDebug('[CoachService] Canceling connection request for coach: $coachId');

    final response = await delete('/coaches/$coachId/connections');

    if (response.statusCode == 200 || response.statusCode == 204) {
      logDebug('[CoachService] Connection request canceled successfully');
    } else {
      logError(
          '[CoachService] Failed to cancel connection request: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to cancel connection request: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }
}
