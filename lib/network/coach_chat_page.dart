import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/models/connection.dart';
import 'package:projectbrain/services/coach_message_signalr_service.dart';
import 'package:projectbrain/services/coach_service.dart';
import 'package:projectbrain/services/connection_service.dart';
import 'package:projectbrain/utils/coach_message_utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';
import 'package:projectbrain/core/network/user_friendly_error.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:projectbrain/core/util/app_date_format.dart';
import 'package:projectbrain/widgets/chat/chat_composer.dart';

/// Chat page for communicating with connected coaches.
class CoachChatPage extends StatefulWidget {
  /// Route param: connection GUID, or legacy coach Auth0 user id.
  final String? connectionId;

  const CoachChatPage({super.key, this.connectionId});

  @override
  State<CoachChatPage> createState() => _CoachChatPageState();
}

class _CoachChatPageState extends State<CoachChatPage> {
  final CoachService _coachService = sl<CoachService>();
  final ConnectionService _connectionService = sl<ConnectionService>();
  final CoachMessageSignalRService _signalRService =
      sl<CoachMessageSignalRService>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;

  /// Downloaded audio per message id, deleted when the page closes.
  final Map<String, File> _downloadedAudio = {};
  String? _playingMessageId;
  String? _loadingAudioMessageId;

  List<Connection> _connections = [];
  String? _selectedConnectionId;
  String? _headerName;
  List<CoachMessage> _messages = [];
  bool _isLoading = true;
  bool _messagesLoadFailed = false;
  bool _isSending = false;
  bool _isRecording = false;
  Timer? _recordingTimer;
  String? _errorMessage;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() => _playingMessageId = null);
        _audioPlayer.stop();
      }
    });
    _loadConnections();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _signalRService.stop();
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    for (final file in _downloadedAudio.values) {
      file.delete().catchError((_) => file);
    }
    super.dispose();
  }

  Future<void> _toggleAudio(CoachMessage message) async {
    if (_playingMessageId == message.id) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _playingMessageId = null);
      return;
    }
    if (_loadingAudioMessageId != null) return;

    setState(() => _loadingAudioMessageId = message.id);
    try {
      final file = _downloadedAudio[message.id] ??=
          await _coachService.downloadMessageAudio(message.id);
      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(file.path);
      if (!mounted) return;
      setState(() {
        _playingMessageId = message.id;
        _loadingAudioMessageId = null;
      });
      await _audioPlayer.play();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingAudioMessageId = null;
        _errorMessage = "Couldn't play that audio message. Please try again.";
      });
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {
      // Nothing to send either way.
    }
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _loadConnections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final connections = await _connectionService.getAcceptedConnections();
      if (!mounted) return;
      final selectedId = _resolveInitialConnectionId(connections);

      setState(() {
        _connections = connections;
        _selectedConnectionId = selectedId;
        _isLoading = false;
      });

      if (selectedId != null) {
        await _startRealtime(selectedId);
        await _loadConnectionDetails(selectedId);
        await _loadMessages();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            userFriendlyError(e, fallback: "Couldn't load coaches.");
        _isLoading = false;
      });
    }
  }

  Future<void> _startRealtime(String connectionId) async {
    await _signalRService.start(onNewMessage: _handleNewMessage);
    await _signalRService.joinConversation(connectionId);
  }

  void _handleNewMessage(CoachMessage message) {
    if (!mounted) return;
    if (message.connectionId != _selectedConnectionId) return;

    setState(() {
      _messages = mergeCoachMessages(_messages, [message]);
    });
    _scrollToBottom();

    final connectionId = _selectedConnectionId;
    if (connectionId != null) {
      _coachService.markConversationRead(connectionId).catchError((_) {});
    }
  }

  String? _resolveInitialConnectionId(List<Connection> connections) {
    final routeParam = widget.connectionId;
    if (routeParam == null) {
      return connections.isNotEmpty ? connections.first.id : null;
    }

    if (isConnectionGuid(routeParam)) {
      return connections.any((c) => c.id == routeParam) ? routeParam : null;
    }

    final match = connections.where((c) => c.coachId == routeParam);
    return match.isNotEmpty ? match.first.id : null;
  }

  Future<void> _loadConnectionDetails(String connectionId) async {
    try {
      final connection =
          await _connectionService.getConnectionById(connectionId);
      if (!mounted) return;
      setState(() {
        _headerName = connection.coachName ?? 'Coach';
      });
    } catch (e) {
      if (!mounted) return;
      String? fallback;
      for (final connection in _connections) {
        if (connection.id == connectionId) {
          fallback = connection.coachName;
          break;
        }
      }
      setState(() {
        _headerName = fallback ?? 'Coach';
      });
    }
  }

  Future<void> _selectConnection(Connection connection) async {
    final oldId = _selectedConnectionId;
    if (oldId != null) {
      await _signalRService.leaveConversation(oldId);
    }
    if (!mounted) return;

    setState(() {
      _selectedConnectionId = connection.id;
      _headerName = connection.coachName ?? 'Coach';
      _messages = [];
      _errorMessage = null;
    });

    await _signalRService.joinConversation(connection.id);
    await _loadConnectionDetails(connection.id);
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    final connectionId = _selectedConnectionId;
    if (connectionId == null) return;

    setState(() => _messagesLoadFailed = false);
    try {
      final messages = await _coachService.getMessages(connectionId);
      if (!mounted) return;
      setState(() {
        _messages = mergeCoachMessages([], messages);
      });
      _scrollToBottom();

      try {
        await _coachService.markConversationRead(connectionId);
      } catch (_) {
        // Non-fatal if read receipt fails.
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            userFriendlyError(e, fallback: "Couldn't load messages.");
        _messagesLoadFailed = true;
      });
    }
  }

  Future<void> _sendTextMessage() async {
    final connectionId = _selectedConnectionId;
    // The keyboard's send action bypasses the disabled button, so check here.
    if (_isSending ||
        connectionId == null ||
        _textController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final message = await _coachService.sendTextMessage(
        connectionId,
        _textController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _messages = mergeCoachMessages(_messages, [message]);
        _textController.clear();
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            userFriendlyError(e, fallback: "Couldn't send message.");
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/coach_audio_$timestamp.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _errorMessage = null;
      });

      _startRecordingTimer();
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().toLowerCase();
      final permissionDenied =
          errorMsg.contains('permission') || errorMsg.contains('denied');
      if (permissionDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Allow microphone access in Settings to record.'),
            action: SnackBarAction(
              label: 'Open settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      setState(() {
        if (permissionDenied) {
          _errorMessage =
              'Microphone permission denied. Please enable microphone access in settings.';
        } else {
          _errorMessage =
              userFriendlyError(e, fallback: "Couldn't start recording.");
        }
        _isRecording = false;
      });
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isRecording) {
        timer.cancel();
        return;
      }
      setState(() {
        _recordingDuration = _recordingDuration + const Duration(seconds: 1);
      });
    });
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
      });
      if (path != null) {
        await _sendAudioMessage(File(path));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            userFriendlyError(e, fallback: "Couldn't stop recording.");
        _isRecording = false;
      });
    }
  }

  Future<void> _sendAudioMessage(File audioFile) async {
    final connectionId = _selectedConnectionId;
    if (connectionId == null) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final message = await _coachService.sendAudioMessage(
        connectionId,
        audioFile,
      );
      if (!mounted) return;
      setState(() {
        _messages = mergeCoachMessages(_messages, [message]);
        _recordingDuration = Duration.zero;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = userFriendlyError(e, fallback: "Couldn't send audio.");
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime date) {
    return AppDateFormat.time(date);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coachName = _headerName ?? 'Select a Coach';

    return Scaffold(
      appBar: AppBar(
        title: Text(coachName),
        actions: [
          if (_connections.length > 1)
            PopupMenuButton<Connection>(
              icon: const Icon(Icons.more_vert),
              onSelected: _selectConnection,
              itemBuilder: (context) => _connections.map((connection) {
                return PopupMenuItem<Connection>(
                  value: connection,
                  child: Text(connection.coachName ?? 'Coach'),
                );
              }).toList(),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: AppInsets.screen,
              color: theme.colorScheme.errorContainer,
              child: Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          if (_isLoading)
            const Expanded(
                child: Center(
                    child:
                        CircularProgressIndicator(semanticsLabel: 'Loading')))
          else if (_selectedConnectionId == null)
            const Expanded(
              child: Center(child: Text('No connected coaches available')),
            )
          else
            Expanded(
              child: _messages.isEmpty && _messagesLoadFailed
                  ? DsLoadFailed(
                      message: "Couldn't load your messages.",
                      onRetry: _loadMessages,
                    )
                  : _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Start a conversation with $coachName',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: context.appTheme.textMuted,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: AppInsets.screen,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return Align(
                              alignment: message.isFromCoach
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: message.isFromCoach
                                      ? theme.colorScheme.surface
                                      : theme.colorScheme.primary,
                                  borderRadius: message.isFromCoach
                                      ? const BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          topRight: Radius.circular(18),
                                          bottomRight: Radius.circular(18),
                                          bottomLeft: Radius.circular(4),
                                        )
                                      : const BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          topRight: Radius.circular(18),
                                          bottomLeft: Radius.circular(18),
                                          bottomRight: Radius.circular(4),
                                        ),
                                  border: message.isFromCoach
                                      ? Border.all(
                                          color: context.appTheme.borderColor,
                                        )
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (message.text != null)
                                      Text(
                                        message.text!,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: message.isFromCoach
                                              ? theme.colorScheme.onSurface
                                              : theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    if (message.audioUrl != null)
                                      _AudioMessageControl(
                                        isPlaying:
                                            _playingMessageId == message.id,
                                        isLoading: _loadingAudioMessageId ==
                                            message.id,
                                        color: message.isFromCoach
                                            ? theme.colorScheme.onSurface
                                            : theme.colorScheme.onPrimary,
                                        onPressed: () => _toggleAudio(message),
                                      ),
                                    SizedBox(height: AppSpacing.xs),
                                    Text(
                                      _formatTime(message.createdAt),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: message.isFromCoach
                                            ? context.appTheme.textMuted
                                            : theme.colorScheme.onPrimary
                                                .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          if (_isRecording)
            Container(
              padding: AppInsets.screen,
              color: theme.colorScheme.errorContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: theme.colorScheme.onErrorContainer),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  TextButton(
                    onPressed: _cancelRecording,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: _stopRecording,
                    child: const Text('Stop & Send'),
                  ),
                ],
              ),
            ),
          if (_selectedConnectionId != null)
            ChatComposer(
              controller: _textController,
              hintText: 'Message coach…',
              semanticsLabel: 'Message to your coach',
              isBusy: _isSending,
              showBusySpinner: true,
              onSend: (_) => _sendTextMessage(),
              leading: IconButton(
                icon: const Icon(Icons.mic),
                onPressed: _isSending || _isRecording ? null : _startRecording,
                tooltip: 'Record audio',
              ),
            ),
        ],
      ),
    );
  }
}

/// Play/pause button and label for a voice message bubble.
class _AudioMessageControl extends StatelessWidget {
  const _AudioMessageControl({
    required this.isPlaying,
    required this.isLoading,
    required this.color,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool isLoading;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    semanticsLabel: 'Loading', strokeWidth: 2, color: color),
              ),
            ),
          )
        else
          IconButton(
            onPressed: onPressed,
            tooltip: isPlaying ? 'Pause audio message' : 'Play audio message',
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: color,
              size: 32,
            ),
          ),
        Text(
          'Audio message',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
