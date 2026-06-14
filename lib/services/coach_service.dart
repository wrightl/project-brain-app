import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/services/http_service.dart';

/// Service for managing coaches and coach interactions
class CoachService extends HttpService {
  CoachService({required super.authService});

  /// Get all coaches (uses search endpoint per API; no filters = all coaches)
  Future<List<Coach>> getCoaches() async {
    logDebug('[CoachService] Fetching coaches');

    final response = await get(
      '/coaches/search',
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

  /// Get the catalog of coach specialism options
  Future<List<String>> getSpecialisms() async {
    logDebug('[CoachService] Fetching coach specialisms');

    final response = await get(
      '/coaches/specialisms',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final specialisms = data.map((item) => item.toString()).toList();
      logDebug('[CoachService] Fetched ${specialisms.length} specialisms');
      return specialisms;
    } else {
      logError(
          '[CoachService] Failed to fetch specialisms: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch specialisms: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Build query string for coach search (testable; mirrors web portal).
  static String buildCoachSearchQuery({
    String? city,
    String? stateProvince,
    String? country,
    double? latitude,
    double? longitude,
    int? distanceMiles,
    List<String>? ageGroups,
    List<String>? specialisms,
  }) {
    final parts = <String>[];

    void addParam(String key, String value) {
      parts.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
      );
    }

    final hasGeoCenter = latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        distanceMiles != null &&
        distanceMiles > 0;

    if (hasGeoCenter) {
      addParam('latitude', latitude.toString());
      addParam('longitude', longitude.toString());
      addParam('distanceMiles', distanceMiles.toString());
    } else {
      if (country != null && country.isNotEmpty) {
        addParam('country', country);
      }
      if (city != null && city.isNotEmpty) {
        addParam('city', city);
      }
      if (stateProvince != null && stateProvince.isNotEmpty) {
        addParam('stateProvince', stateProvince);
      }
    }

    if (ageGroups != null) {
      for (final ageGroup in ageGroups) {
        if (ageGroup.isNotEmpty) {
          addParam('ageGroups', ageGroup);
        }
      }
    }

    if (specialisms != null) {
      for (final specialism in specialisms) {
        if (specialism.isNotEmpty) {
          addParam('specialisms', specialism);
        }
      }
    }

    return parts.isEmpty ? '' : '?${parts.join('&')}';
  }

  /// Search for coaches by location, age groups, and specialisms.
  Future<List<Coach>> searchCoaches({
    String? city,
    String? stateProvince,
    String? country,
    double? latitude,
    double? longitude,
    int? distanceMiles,
    List<String>? ageGroups,
    List<String>? specialisms,
  }) async {
    logDebug('[CoachService] Searching coaches');

    final queryString = buildCoachSearchQuery(
      city: city,
      stateProvince: stateProvince,
      country: country,
      latitude: latitude,
      longitude: longitude,
      distanceMiles: distanceMiles,
      ageGroups: ageGroups,
      specialisms: specialisms,
    );

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

  /// Build path for fetching conversation messages (testable).
  static String buildConversationMessagesPath(
    String connectionId, {
    int pageSize = 20,
  }) {
    return '/coach-messages/conversation/$connectionId?pageSize=$pageSize';
  }

  /// Get messages for a coach connection conversation.
  Future<List<CoachMessage>> getMessages(String connectionId) async {
    logDebug('[CoachService] Fetching messages for connection: $connectionId');

    final response = await get(
      buildConversationMessagesPath(connectionId),
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

  /// Send a text message on a coach connection.
  Future<CoachMessage> sendTextMessage(
    String connectionId,
    String content,
  ) async {
    logDebug(
        '[CoachService] Sending text message to connection: $connectionId');

    final response = await post(
      '/coach-messages',
      body: jsonEncode({
        'connectionId': connectionId,
        'content': content,
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

  /// Send a voice message on a coach connection.
  Future<CoachMessage> sendAudioMessage(
    String connectionId,
    File audioFile,
  ) async {
    logDebug(
        '[CoachService] Sending audio message to connection: $connectionId');

    final token = await authService.getAccessToken();
    final uri = Uri.parse('$baseUrl/coach-messages/voice');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      request.fields['connectionId'] = connectionId;

      final fileStream = http.ByteStream(audioFile.openRead());
      final fileLength = await audioFile.length();
      final multipartFile = http.MultipartFile(
        'file',
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

  /// Mark all messages in a conversation as read.
  Future<void> markConversationRead(String connectionId) async {
    logDebug('[CoachService] Marking conversation read: $connectionId');

    final response =
        await put('/coach-messages/conversation/$connectionId/read');

    if (response.statusCode == 200 || response.statusCode == 204) {
      logDebug('[CoachService] Conversation marked as read');
    } else {
      logError(
          '[CoachService] Failed to mark conversation read: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to mark conversation read: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Delete a message.
  Future<void> deleteMessage(String messageId) async {
    logDebug('[CoachService] Deleting message: $messageId');

    final response = await delete('/coach-messages/$messageId');

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

  /// Get the connection status between the current user and a coach.
  /// API Endpoint: GET /coaches/{coachId}/connection-status
  Future<CoachConnectionStatusResult> getConnectionStatus(
      String coachId) async {
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
      final connectionId =
          data['connectionId']?.toString() ?? data['ConnectionId']?.toString();
      logDebug('[CoachService] Connection status: ${status.displayName}');
      return CoachConnectionStatusResult(
        status: status,
        connectionId: connectionId,
      );
    } else if (response.statusCode == 404) {
      logDebug('[CoachService] No connection found, returning none');
      return const CoachConnectionStatusResult(status: ConnectionStatus.none);
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
  Future<ConnectionStatus> sendConnectionRequest(String coachId) async {
    logDebug('[CoachService] Sending connection request to coach: $coachId');

    final response = await post(
      '/coaches/$coachId/connections',
      body: jsonEncode({}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      logDebug('[CoachService] Connection request sent successfully');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'pending';
      return ConnectionStatus.fromString(status);
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
