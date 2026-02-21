import 'dart:convert';
import 'package:projectbrain/services/http_service.dart';
import 'package:projectbrain/models/journal/timezone_response.dart';

class UserService extends HttpService {
  UserService({required super.authService});

  /// Get user's stored timezone (IANA string or null).
  Future<TimezoneResponse> getTimezone() async {
    final res = await get('/users/me/timezone', useCache: false);
    if (res.statusCode == 200) {
      return TimezoneResponse.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to fetch timezone');
    }
  }

  /// Set user's timezone (IANA string). Used for streak calculation.
  Future<TimezoneResponse> setTimezone(String timezone) async {
    final res = await put(
      '/users/me/timezone',
      body: jsonEncode({'timezone': timezone}),
    );
    if (res.statusCode == 200) {
      return TimezoneResponse.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to set timezone');
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final res = await get('/users/me');
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<void> completeOnboarding(Map<String, dynamic> formData) async {
    final res = await post(
      '/users/me/onboarding',
      body: jsonEncode(formData),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to complete onboarding');
    }
  }

  Future<Map<String, dynamic>> updateUser(
      String userId, Map<String, dynamic> userData) async {
    final res = await put(
      '/users/me/$userId',
      body: jsonEncode(userData),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to update user profile');
    }
  }
}
