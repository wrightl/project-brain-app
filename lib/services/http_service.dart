import 'dart:collection';
import 'dart:math' as math;

import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/core/network/rate_limited_exception.dart';
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

  /// The API runs an always-on replica on a database that resumes in under a
  /// second, so a handful of consecutive failures means a real outage.
  static const int failureThreshold = 5;
  static const Duration openDuration = Duration(seconds: 30);

  bool get isOpen => state == _CircuitState.open;

  void recordSuccess() {
    failureCount = 0;
    state = _CircuitState.closed;
  }

  void recordFailure({bool countTowardOpen = true}) {
    if (!countTowardOpen) return;
    failureCount++;
    if (failureCount >= failureThreshold) {
      state = _CircuitState.open;
      openedAt = DateTime.now();
      logDebug('[CircuitBreaker] Circuit opened after $failureCount failures');
    }
  }

  bool canAttempt() {
    if (state == _CircuitState.closed) return true;
    if (state == _CircuitState.open && openedAt != null) {
      if (DateTime.now().difference(openedAt!) > openDuration) {
        state = _CircuitState.halfOpen;
        logDebug('[CircuitBreaker] Circuit half-open, allowing test request');
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

  // HTTP configuration — short retry budget for transient errors and the API's
  // brief 503 startup gate (Retry-After is honoured, capped at maxRetryDelay).
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);
  static const Duration maxRetryDelay = Duration(seconds: 5);
  static const Duration defaultCacheDuration = Duration(minutes: 5);

  /// Max distinct GET paths kept in memory (LRU by last access).
  static const int maxCacheEntries = 64;

  // Cache for GET requests (insertion order = oldest → newest for eviction)
  final LinkedHashMap<String, _CachedResponse> _cache = LinkedHashMap();

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
    // Check cache first (refresh LRU order on hit)
    if (useCache && _cache.containsKey(path)) {
      final cached = _cache.remove(path)!;
      if (!cached.isExpired) {
        logDebug('[HttpService] Cache hit for GET $path');
        _cache[path] = cached;
        return cached.response;
      }
    }

    // Check for pending identical request (deduplication)
    if (_pendingRequests.containsKey(path)) {
      logDebug('[HttpService] Deduplicating GET request to $path');
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
      idempotent: true,
    );

    // Store pending request for deduplication
    _pendingRequests[path] = requestFuture;

    try {
      final response = await requestFuture;

      // Cache successful GET responses (evict oldest entries if over cap)
      if (useCache && response.statusCode == 200) {
        while (_cache.length >= maxCacheEntries) {
          final oldest = _cache.keys.first;
          _cache.remove(oldest);
          logDebug('[HttpService] Cache evicted (LRU cap) GET $oldest');
        }
        _cache[path] = _CachedResponse(
          response,
          cacheDuration ?? defaultCacheDuration,
        );
        logDebug(
            '[HttpService] Cached GET $path for ${cacheDuration ?? defaultCacheDuration}');
      }

      return response;
    } finally {
      // Remove from pending requests
      _pendingRequests.remove(path);
    }
  }

  /// Clear GET cache, in-flight dedupe map, and circuit breakers (e.g. on logout).
  void clearCache() {
    _cache.clear();
    _pendingRequests.clear();
    _circuitBreakers.clear();
    logDebug('[HttpService] Cache and request state cleared');
  }

  /// Clear cache for a specific path
  void clearCacheForPath(String path) {
    _cache.remove(path);
    logDebug('[HttpService] Cache cleared for $path');
  }

  /// Make a streaming POST request (no retry for streaming).
  /// [extraHeaders] e.g. {'Accept': 'text/event-stream'} for SSE.
  Future<http.StreamedResponse> send(
    String path,
    String body, {
    Duration? timeout,
    Map<String, String>? extraHeaders,
  }) async {
    final token = await _getToken();
    final headers = Map<String, String>.from(_authHeaders(token));
    if (extraHeaders != null) headers.addAll(extraHeaders);
    final request = http.Request('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll(headers)
      ..body = body;

    final http.StreamedResponse response;
    try {
      response = await request.send().timeout(timeout ?? defaultTimeout);
    } catch (error, stackTrace) {
      logDebug('[HttpService] Error in streaming POST request: $error');
      logDebug('[HttpService] Stack trace: $stackTrace');
      throw Exception('Failed to send data to $path: $error');
    }

    if (response.statusCode == 429) {
      final body = await response.stream.bytesToString();
      throw RateLimitedException.fromResponse(body, response.headers);
    }
    return response;
  }

  /// Make a POST request with timeout and retry logic
  Future<http.Response> post(String path,
      {Object? body, Duration? timeout}) async {
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
      idempotent: false,
    );
  }

  /// Make a PUT request with timeout and retry logic
  Future<http.Response> put(String path,
      {Object? body, Duration? timeout}) async {
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
      idempotent: true,
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
      idempotent: true,
    );
  }

  /// Retry logic for HTTP requests with circuit breaker.
  ///
  /// 429 and 503 are rejected by the API before any handler runs, so every
  /// method may retry them. Other failures (5xx, timeouts, dropped connections)
  /// may have been processed server-side, so only [idempotent] requests retry
  /// them; retrying a POST could create a duplicate journal entry or message.
  Future<http.Response> _retryRequest(
    Future<http.Response> Function() request, {
    required String path,
    required String method,
    required bool idempotent,
  }) async {
    // Get or create circuit breaker for this endpoint
    final circuitBreaker = _circuitBreakers.putIfAbsent(
      path,
      () => _CircuitBreaker(),
    );

    // Check circuit breaker
    if (!circuitBreaker.canAttempt()) {
      logDebug('[HttpService] Circuit breaker is open for $method $path');
      throw Exception(
          'Circuit breaker is open for $method $path - too many recent failures');
    }

    int attempt = 0;
    Exception? lastException;
    http.Response? lastErrorResponse;

    while (attempt < maxRetries) {
      attempt++;
      try {
        final response = await request();

        if (response.statusCode == 429) {
          final retryAfter = RateLimitedException.parseRetryAfter(
            response.headers,
          );
          if (retryAfter != null &&
              retryAfter <= maxRetryDelay &&
              attempt < maxRetries) {
            logDebug(
                '[HttpService] $method $path rate limited, retrying in ${retryAfter.inMilliseconds}ms');
            await Future.delayed(retryAfter);
            continue;
          }
          throw RateLimitedException.fromResponse(
            response.body,
            response.headers,
          );
        }

        final retryableStatus = response.statusCode == 503 ||
            (idempotent && response.statusCode >= 500);

        // Check for server errors that should be retried (incl. 503 starting gate)
        if (retryableStatus && attempt < maxRetries) {
          // 503 during warmup should not trip the circuit mid-burst
          circuitBreaker.recordFailure(
            countTowardOpen: response.statusCode != 503,
          );
          final delay = _retryDelayFor(response, attempt);
          logDebug(
              '[HttpService] $method $path failed with ${response.statusCode}, retrying in ${delay.inMilliseconds}ms (attempt $attempt/$maxRetries)');
          await Future.delayed(delay);
          lastErrorResponse = response;
          continue;
        }

        // Success - record in circuit breaker
        if (response.statusCode < 500) {
          circuitBreaker.recordSuccess();
        } else {
          circuitBreaker.recordFailure();
        }

        return response;
      } on RateLimitedException {
        rethrow;
      } on Exception catch (error, stackTrace) {
        lastException = error;
        final willRetry = idempotent && attempt < maxRetries;
        // Transient network during scale-from-0: don't trip circuit until exhausted
        circuitBreaker.recordFailure(countTowardOpen: !willRetry);
        logDebug(
            '[HttpService] $method $path failed (attempt $attempt/$maxRetries): $error');

        if (!idempotent) {
          logDebug(
              '[HttpService] Not retrying $method $path: it may already have been processed');
          break;
        }

        if (attempt < maxRetries) {
          final delay = _backoffDelay(attempt);
          logDebug('[HttpService] Retrying in ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
        } else {
          logDebug('[HttpService] Max retries reached for $method $path');
          logDebug('[HttpService] Stack trace: $stackTrace');
        }
      }
    }

    if (lastErrorResponse != null && lastException == null) {
      return lastErrorResponse;
    }

    throw lastException ??
        Exception('Failed to $method $path after $maxRetries attempts');
  }

  static Duration _retryDelayFor(http.Response response, int attempt) {
    final retryAfter = response.headers['retry-after'];
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter.trim());
      if (seconds != null && seconds > 0) {
        final fromHeader = Duration(seconds: seconds);
        return fromHeader > maxRetryDelay ? maxRetryDelay : fromHeader;
      }
    }
    return _backoffDelay(attempt);
  }

  static Duration _backoffDelay(int attempt) {
    final millis =
        (retryDelay.inMilliseconds * math.pow(2, attempt - 1).toInt())
            .clamp(retryDelay.inMilliseconds, maxRetryDelay.inMilliseconds);
    return Duration(milliseconds: millis);
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
