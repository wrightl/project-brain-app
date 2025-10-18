import 'dart:convert';

import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';

/// Service responsible for fetching user profile information from Auth0
class UserProfileService {
  final http.Client _httpClient;

  UserProfileService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Fetch user profile information from Auth0
  Future<Auth0User> getUserProfile(String accessToken) async {
    try {
      logDebug('[UserProfileService] Fetching user profile');
      final url = Uri.https(AppConfig.authDomain, '/userinfo');

      final response = await _httpClient.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        logDebug('[UserProfileService] User profile fetched successfully');
        return Auth0User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized - invalid access token');
      } else {
        throw AuthException(
          'Failed to get user details (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      logDebug('[UserProfileService] Error fetching user profile: $e');
      throw AuthException('Failed to fetch user details', e);
    }
  }

  /// Clean up resources
  void dispose() {
    _httpClient.close();
  }
}
