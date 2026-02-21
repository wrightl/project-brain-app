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

  GoalsRealtimeService({required this.authService});

  bool get isRunning => _running;

  /// Start listening for goals updates. When the backend sends an SSE event
  /// (e.g. event: goals-updated), [onGoalsUpdated] is called.
  /// Only one connection is active; call [stop] before starting again.
  Future<void> start(void Function() onGoalsUpdated) async {
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
      final response = await _client!.send(request);

      if (response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode >= 500) {
        logDebug(
            '[GoalsRealtimeService] Stream failed: ${response.statusCode}');
        _client?.close();
        _client = null;
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
        },
        onError: (e, st) {
          _running = false;
          logDebug('[GoalsRealtimeService] SSE error: $e');
        },
        cancelOnError: true,
      );
    } catch (e, st) {
      logDebug('[GoalsRealtimeService] Failed to start: $e');
      logDebug('[GoalsRealtimeService] $st');
      _client?.close();
      _client = null;
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
    if (eventType == 'goals-updated' || eventType != null) {
      _onGoalsUpdated?.call();
    }
  }

  /// Stop the SSE connection and release resources.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
    _running = false;
    _onGoalsUpdated = null;
    logDebug('[GoalsRealtimeService] Stopped');
  }
}
