import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/core/config/app_config.dart';

/// Base HTTP service for making authenticated API requests
class HttpService {
  final AuthService authService;
  final String baseUrl = AppConfig.apiBaseUrl;

  HttpService({required this.authService});

  /// Make a GET request
  Future<http.Response> get(String path) async {
    final token = await _getToken();
    try {
      return await http.get(
        Uri.parse('$baseUrl$path'),
        headers: _authHeaders(token),
      );
    } catch (error, stackTrace) {
      debugPrint('[HttpService] Error in GET request: $error');
      debugPrint('[HttpService] Stack trace: $stackTrace');
      throw Exception('Failed to fetch data from $path');
    }
  }

  /// Make a streaming POST request
  Future<http.StreamedResponse> send(String path, String body) async {
    final token = await _getToken();
    final request = http.Request('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll(_authHeaders(token))
      ..body = body;

    try {
      return await request.send();
    } catch (error, stackTrace) {
      debugPrint('[HttpService] Error in POST request: $error');
      debugPrint('[HttpService] Stack trace: $stackTrace');
      throw Exception('Failed to send data to $path');
    }
  }

  /// Make a POST request
  Future<http.Response> post(String path, {Object? body}) async {
    final token = await _getToken();
    return await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders(token),
      body: body,
    );
  }

  /// Make a PUT request
  Future<http.Response> put(String path, {Object? body}) async {
    final token = await _getToken();
    return await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders(token),
      body: body,
    );
  }

  /// Make a DELETE request
  Future<http.Response> delete(String path) async {
    final token = await _getToken();
    return await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders(token),
    );
  }

  /// Generate authentication headers
  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// Get valid access token
  Future<String> _getToken() async {
    final token = await authService.getAccessToken();
    return token;
  }
}
