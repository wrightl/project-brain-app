import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Parses a coach message payload from a SignalR hub invocation.
CoachMessage? parseCoachMessageFromSignalR(List<Object?>? arguments) {
  if (arguments == null || arguments.isEmpty) return null;

  final raw = arguments.first;
  if (raw is Map) {
    return CoachMessage.fromJson(Map<String, dynamic>.from(raw));
  }
  return null;
}

/// Real-time coach messaging via the backend SignalR hub.
class CoachMessageSignalRService {
  CoachMessageSignalRService({required this.authService});

  final AuthService authService;

  HubConnection? _hub;
  String? _joinedConnectionId;
  void Function(CoachMessage)? _onNewMessage;
  void Function(CoachMessage)? _onMessageDelivered;
  void Function(CoachMessage)? _onMessageRead;

  bool get isConnected => _hub?.state == HubConnectionState.Connected;

  Future<void> start({
    required void Function(CoachMessage message) onNewMessage,
    void Function(CoachMessage message)? onMessageDelivered,
    void Function(CoachMessage message)? onMessageRead,
  }) async {
    _onNewMessage = onNewMessage;
    _onMessageDelivered = onMessageDelivered;
    _onMessageRead = onMessageRead;

    if (_hub != null) {
      if (_hub!.state == HubConnectionState.Connected ||
          _hub!.state == HubConnectionState.Connecting) {
        return;
      }
      await _hub!.stop();
      _hub = null;
    }

    final hubUrl = '${AppConfig.apiBaseUrl}/hubs/coach-messages';
    logDebug('[CoachMessageSignalRService] Connecting to $hubUrl');

    _hub = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => authService.getAccessToken(),
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hub!.on('NewMessage', (arguments) {
      final message = parseCoachMessageFromSignalR(arguments);
      if (message != null) {
        _onNewMessage?.call(message);
      }
    });

    _hub!.on('MessageDelivered', (arguments) {
      final message = parseCoachMessageFromSignalR(arguments);
      if (message != null) {
        _onMessageDelivered?.call(message);
      }
    });

    _hub!.on('MessageRead', (arguments) {
      final message = parseCoachMessageFromSignalR(arguments);
      if (message != null) {
        _onMessageRead?.call(message);
      }
    });

    _hub!.onreconnected(({connectionId}) async {
      logDebug('[CoachMessageSignalRService] Reconnected');
      final joinedId = _joinedConnectionId;
      if (joinedId != null) {
        try {
          await _hub!.invoke('JoinConversation', args: [joinedId]);
        } catch (e, stackTrace) {
          logError(
            '[CoachMessageSignalRService] Error rejoining conversation',
            e,
            stackTrace,
          );
        }
      }
    });

    _hub!.onclose(({error}) {
      if (error != null) {
        logDebug('[CoachMessageSignalRService] Connection closed: $error');
      }
    });

    await _hub!.start();
    logDebug('[CoachMessageSignalRService] Connected');
  }

  Future<void> joinConversation(String connectionId) async {
    if (_joinedConnectionId != null &&
        _joinedConnectionId != connectionId) {
      await leaveConversation(_joinedConnectionId!);
    }

    _joinedConnectionId = connectionId;

    if (_hub?.state != HubConnectionState.Connected) {
      return;
    }

    try {
      await _hub!.invoke('JoinConversation', args: [connectionId]);
      logDebug(
        '[CoachMessageSignalRService] Joined conversation $connectionId',
      );
    } catch (e, stackTrace) {
      logError(
        '[CoachMessageSignalRService] Error joining conversation',
        e,
        stackTrace,
      );
    }
  }

  Future<void> leaveConversation(String connectionId) async {
    if (_hub?.state == HubConnectionState.Connected) {
      try {
        await _hub!.invoke('LeaveConversation', args: [connectionId]);
      } catch (e, stackTrace) {
        logDebug(
          '[CoachMessageSignalRService] Error leaving conversation: $e',
        );
        logDebug('[CoachMessageSignalRService] Stack trace: $stackTrace');
      }
    }

    if (_joinedConnectionId == connectionId) {
      _joinedConnectionId = null;
    }
  }

  Future<void> stop() async {
    final joinedId = _joinedConnectionId;
    if (joinedId != null) {
      await leaveConversation(joinedId);
    }

    if (_hub != null) {
      try {
        await _hub!.stop();
      } catch (e, stackTrace) {
        logDebug('[CoachMessageSignalRService] Error stopping hub: $e');
        logDebug('[CoachMessageSignalRService] Stack trace: $stackTrace');
      }
      _hub = null;
    }
  }
}
