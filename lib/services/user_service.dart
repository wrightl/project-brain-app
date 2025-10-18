import 'dart:convert';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/services/http_service.dart';

class UserService extends HttpService {
  UserService({required AuthService authService})
      : super(authService: authService);

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
}
