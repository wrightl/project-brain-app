import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/core/config/app_config.dart';

/// Base HTTP service for making authenticated API requests with timeout and retry logic
class HttpService {
  final AuthService authService;
  final String baseUrl = AppConfig.apiBaseUrl;

  // HTTP configuration
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  HttpService({required this.authService});

  /// Make a GET request with timeout and retry logic
  Future<http.Response> get(String path, {Duration? timeout}) async {
    return await _retryRequest(
      () async {
        final token = await _getToken();
        return await http
            .get(
              Uri.parse('$baseUrl$path'),
              headers: _authHeaders(token),
            )
            .timeout(timeout ?? defaultTimeout);
      },
      path: path,
      method: 'GET',
    );
  }

  /// Make a streaming POST request (no retry for streaming)
  Future<http.StreamedResponse> send(String path, String body, {Duration? timeout}) async {
    final token = await _getToken();
    final request = http.Request('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll(_authHeaders(token))
      ..body = body;

    try {
      return await request.send().timeout(timeout ?? defaultTimeout);
    } catch (error, stackTrace) {
      debugPrint('[HttpService] Error in streaming POST request: $error');
      debugPrint('[HttpService] Stack trace: $stackTrace');
      throw Exception('Failed to send data to $path: $error');
    }
  }

  /// Make a POST request with timeout and retry logic
  Future<http.Response> post(String path, {Object? body, Duration? timeout}) async {
    return await _retryRequest(
      () async {
        final token = await _getToken();
        return await http
            .post(
              Uri.parse('$baseUrl$path'),
              headers: _authHeaders(token),
              body: body,
            )
            .timeout(timeout ?? defaultTimeout);
      },
      path: path,
      method: 'POST',
    );
  }

  /// Make a PUT request with timeout and retry logic
  Future<http.Response> put(String path, {Object? body, Duration? timeout}) async {
    return await _retryRequest(
      () async {
        final token = await _getToken();
        return await http
            .put(
              Uri.parse('$baseUrl$path'),
              headers: _authHeaders(token),
              body: body,
            )
            .timeout(timeout ?? defaultTimeout);
      },
      path: path,
      method: 'PUT',
    );
  }

  /// Make a DELETE request with timeout and retry logic
  Future<http.Response> delete(String path, {Duration? timeout}) async {
    return await _retryRequest(
      () async {
        final token = await _getToken();
        return await http
            .delete(
              Uri.parse('$baseUrl$path'),
              headers: _authHeaders(token),
            )
            .timeout(timeout ?? defaultTimeout);
      },
      path: path,
      method: 'DELETE',
    );
  }

  /// Retry logic for HTTP requests
  Future<http.Response> _retryRequest(
    Future<http.Response> Function() request, {
    required String path,
    required String method,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxRetries) {
      attempt++;
      try {
        final response = await request();

        // Check for server errors that should be retried
        if (response.statusCode >= 500 && attempt < maxRetries) {
          debugPrint('[HttpService] $method $path failed with ${response.statusCode}, retrying (attempt $attempt/$maxRetries)');
          await Future.delayed(retryDelay * attempt);
          continue;
        }

        return response;
      } on Exception catch (error, stackTrace) {
        lastException = error;
        debugPrint('[HttpService] $method $path failed (attempt $attempt/$maxRetries): $error');

        if (attempt < maxRetries) {
          debugPrint('[HttpService] Retrying in ${retryDelay.inSeconds * attempt}s...');
          await Future.delayed(retryDelay * attempt);
        } else {
          debugPrint('[HttpService] Max retries reached for $method $path');
          debugPrint('[HttpService] Stack trace: $stackTrace');
        }
      }
    }

    throw lastException ?? Exception('Failed to $method $path after $maxRetries attempts');
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
