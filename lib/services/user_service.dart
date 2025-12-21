import 'dart:convert';
import 'package:projectbrain/services/http_service.dart';

class UserService extends HttpService {
  UserService({required super.authService});

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
