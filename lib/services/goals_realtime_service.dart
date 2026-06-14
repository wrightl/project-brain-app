import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/services/auth/auth_service.dart';

/// Service that maintains an SSE connection to GET eggs/stream and invokes
/// a callback when the backend sends a goals-updated event.
class GoalsRealtimeService {
  final AuthService authService;

  http.Client? _client;
  StreamSubscription<List<int>>? _subscription;
  void Function()? _onGoalsUpdated;
  bool _running = false;

  /// True once [stop] is called, to prevent auto-reconnect after teardown.
  bool _stopped = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  static const Duration _minReconnectDelay = Duration(seconds: 2);
  static const Duration _maxReconnectDelay = Duration(seconds: 60);
  static const Duration _connectTimeout = Duration(seconds: 15);

  GoalsRealtimeService({required this.authService});

  bool get isRunning => _running;

  /// Start listening for goals updates. When the backend sends an SSE event
  /// (e.g. event: goals-updated), [onGoalsUpdated] is called.
  /// Only one connection is active; call [stop] before starting again.
  Future<void> start(void Function() onGoalsUpdated) async {
    _stopped = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_running) {
      logDebug('[GoalsRealtimeService] Already running');
      return;
    }

    _onGoalsUpdated = onGoalsUpdated;

    try {
      final token = await authService.getAccessToken();
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/eggs/stream');
      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Authorization'] = 'Bearer $token';

      _client = http.Client();
      final response = await _client!.send(request).timeout(_connectTimeout);

      // Auth/not-found are terminal; reconnecting will not help.
      if (response.statusCode == 401 || response.statusCode == 404) {
        logDebug(
            '[GoalsRealtimeService] Stream terminal failure: ${response.statusCode}');
        _client?.close();
        _client = null;
        return;
      }

      // Server errors are transient: back off and retry.
      if (response.statusCode >= 500) {
        logDebug(
            '[GoalsRealtimeService] Stream server error: ${response.statusCode}');
        _client?.close();
        _client = null;
        _scheduleReconnect();
        return;
      }

      if (response.statusCode != 200) {
        logDebug(
            '[GoalsRealtimeService] Unexpected status: ${response.statusCode}');
        _client?.close();
        _client = null;
        return;
      }

      _running = true;
      _reconnectAttempts = 0;
      logDebug('[GoalsRealtimeService] SSE connection opened');

      String buffer = '';
      _subscription = response.stream.listen(
        (chunk) {
          buffer += utf8.decode(chunk);
          while (buffer.contains('\n\n')) {
            final idx = buffer.indexOf('\n\n');
            final block = buffer.substring(0, idx);
            buffer = buffer.substring(idx + 2);
            _processEventBlock(block);
          }
        },
        onDone: () {
          _running = false;
          logDebug('[GoalsRealtimeService] SSE stream closed');
          _scheduleReconnect();
        },
        onError: (e, st) {
          _running = false;
          logWarning('[GoalsRealtimeService] SSE error', e);
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e, st) {
      logWarning('[GoalsRealtimeService] Failed to start', e, st);
      _client?.close();
      _client = null;
      _running = false;
      _scheduleReconnect();
    }
  }

  void _processEventBlock(String block) {
    String? eventType;
    for (final line in block.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('event:')) {
        eventType = trimmed.substring(6).trim();
        break;
      }
    }
    // Only react to the goals-updated event (the previous `|| eventType != null`
    // fired on every event, including unrelated keep-alives/comments).
    if (eventType == 'goals-updated') {
      _onGoalsUpdated?.call();
    }
  }

  /// Schedule a reconnect with exponential backoff, unless [stop] was called.
  void _scheduleReconnect() {
    if (_stopped) return;
    final callback = _onGoalsUpdated;
    if (callback == null) return;
    _reconnectTimer?.cancel();

    final delaySeconds =
        (_minReconnectDelay.inSeconds * (1 << _reconnectAttempts))
            .clamp(_minReconnectDelay.inSeconds, _maxReconnectDelay.inSeconds);
    _reconnectAttempts =
        (_reconnectAttempts + 1).clamp(0, 6); // cap so the shift stays bounded

    logDebug('[GoalsRealtimeService] Reconnecting in ${delaySeconds}s');
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_stopped) return;
      start(callback);
    });
  }

  /// Stop the SSE connection and release resources.
  Future<void> stop() async {
    _stopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    await _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
    _running = false;
    _onGoalsUpdated = null;
    logDebug('[GoalsRealtimeService] Stopped');
  }
}
