import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/core/config/app_config.dart';

/// Cached response with expiry time
class _CachedResponse {
  final http.Response response;
  final DateTime expiresAt;

  _CachedResponse(this.response, Duration cacheDuration)
      : expiresAt = DateTime.now().add(cacheDuration);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Circuit breaker state
enum _CircuitState { closed, open, halfOpen }

/// Circuit breaker for handling repeated failures
class _CircuitBreaker {
  _CircuitState state = _CircuitState.closed;
  int failureCount = 0;
  DateTime? openedAt;

  static const int failureThreshold = 5;
  static const Duration openDuration = Duration(seconds: 60);

  bool get isOpen => state == _CircuitState.open;

  void recordSuccess() {
    failureCount = 0;
    state = _CircuitState.closed;
  }

  void recordFailure() {
    failureCount++;
    if (failureCount >= failureThreshold) {
      state = _CircuitState.open;
      openedAt = DateTime.now();
      debugPrint('[CircuitBreaker] Circuit opened after $failureCount failures');
    }
  }

  bool canAttempt() {
    if (state == _CircuitState.closed) return true;
    if (state == _CircuitState.open && openedAt != null) {
      if (DateTime.now().difference(openedAt!) > openDuration) {
        state = _CircuitState.halfOpen;
        debugPrint('[CircuitBreaker] Circuit half-open, allowing test request');
        return true;
      }
      return false;
    }
    return state == _CircuitState.halfOpen;
  }
}

/// Base HTTP service for making authenticated API requests with timeout, retry, caching, and circuit breaker
class HttpService {
  final AuthService authService;
  final String baseUrl = AppConfig.apiBaseUrl;

  // HTTP configuration
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration defaultCacheDuration = Duration(minutes: 5);

  // Cache for GET requests
  final Map<String, _CachedResponse> _cache = {};

  // Circuit breaker per endpoint
  final Map<String, _CircuitBreaker> _circuitBreakers = {};

  // Pending requests for deduplication
  final Map<String, Future<http.Response>> _pendingRequests = {};

  HttpService({required this.authService});

  /// Make a GET request with caching, timeout, retry logic, and circuit breaker
  Future<http.Response> get(
    String path, {
    Duration? timeout,
    Duration? cacheDuration,
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache && _cache.containsKey(path)) {
      final cached = _cache[path]!;
      if (!cached.isExpired) {
        debugPrint('[HttpService] Cache hit for GET $path');
        return cached.response;
      } else {
        _cache.remove(path);
      }
    }

    // Check for pending identical request (deduplication)
    if (_pendingRequests.containsKey(path)) {
      debugPrint('[HttpService] Deduplicating GET request to $path');
      return await _pendingRequests[path]!;
    }

    // Create new request
    final requestFuture = _retryRequest(
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

    // Store pending request for deduplication
    _pendingRequests[path] = requestFuture;

    try {
      final response = await requestFuture;

      // Cache successful GET responses
      if (useCache && response.statusCode == 200) {
        _cache[path] = _CachedResponse(
          response,
          cacheDuration ?? defaultCacheDuration,
        );
        debugPrint('[HttpService] Cached GET $path for ${cacheDuration ?? defaultCacheDuration}');
      }

      return response;
    } finally {
      // Remove from pending requests
      _pendingRequests.remove(path);
    }
  }

  /// Clear the cache
  void clearCache() {
    _cache.clear();
    debugPrint('[HttpService] Cache cleared');
  }

  /// Clear cache for a specific path
  void clearCacheForPath(String path) {
    _cache.remove(path);
    debugPrint('[HttpService] Cache cleared for $path');
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

  /// Retry logic for HTTP requests with circuit breaker
  Future<http.Response> _retryRequest(
    Future<http.Response> Function() request, {
    required String path,
    required String method,
  }) async {
    // Get or create circuit breaker for this endpoint
    final circuitBreaker = _circuitBreakers.putIfAbsent(
      path,
      () => _CircuitBreaker(),
    );

    // Check circuit breaker
    if (!circuitBreaker.canAttempt()) {
      debugPrint('[HttpService] Circuit breaker is open for $method $path');
      throw Exception('Circuit breaker is open for $method $path - too many recent failures');
    }

    int attempt = 0;
    Exception? lastException;

    while (attempt < maxRetries) {
      attempt++;
      try {
        final response = await request();

        // Check for server errors that should be retried
        if (response.statusCode >= 500 && attempt < maxRetries) {
          circuitBreaker.recordFailure();
          debugPrint('[HttpService] $method $path failed with ${response.statusCode}, retrying (attempt $attempt/$maxRetries)');
          await Future.delayed(retryDelay * attempt);
          continue;
        }

        // Success - record in circuit breaker
        if (response.statusCode < 500) {
          circuitBreaker.recordSuccess();
        }

        return response;
      } on Exception catch (error, stackTrace) {
        lastException = error;
        circuitBreaker.recordFailure();
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

  /// Get circuit breaker status for debugging
  Map<String, String> getCircuitBreakerStatus() {
    return _circuitBreakers.map((path, breaker) {
      final status = switch (breaker.state) {
        _CircuitState.closed => 'closed (healthy)',
        _CircuitState.open => 'open (failing)',
        _CircuitState.halfOpen => 'half-open (testing)',
      };
      return MapEntry(path, '$status - ${breaker.failureCount} failures');
    });
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
