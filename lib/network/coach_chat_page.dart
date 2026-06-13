import 'dart:io';

import 'package:flutter/material.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/models/connection.dart';
import 'package:projectbrain/services/coach_message_signalr_service.dart';
import 'package:projectbrain/services/coach_service.dart';
import 'package:projectbrain/services/connection_service.dart';
import 'package:projectbrain/utils/coach_message_utils.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

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

  List<Connection> _connections = [];
  String? _selectedConnectionId;
  String? _headerName;
  List<CoachMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isRecording = false;
  String? _errorMessage;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  @override
  void dispose() {
    _signalRService.stop();
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final connections = await _connectionService.getAcceptedConnections();
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
      setState(() {
        _errorMessage = 'Failed to load coaches: ${e.toString()}';
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
      return connections.any((c) => c.id == routeParam)
          ? routeParam
          : routeParam;
    }

    final match = connections.where((c) => c.coachId == routeParam);
    return match.isNotEmpty ? match.first.id : null;
  }

  Future<void> _loadConnectionDetails(String connectionId) async {
    try {
      final connection =
          await _connectionService.getConnectionById(connectionId);
      setState(() {
        _headerName = connection.coachName ?? 'Coach';
      });
    } catch (e) {
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

    try {
      final messages = await _coachService.getMessages(connectionId);
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
      setState(() {
        _errorMessage = 'Failed to load messages: ${e.toString()}';
      });
    }
  }

  Future<void> _sendTextMessage() async {
    final connectionId = _selectedConnectionId;
    if (connectionId == null || _textController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final message = await _coachService.sendTextMessage(
        connectionId,
        _textController.text.trim(),
      );
      setState(() {
        _messages = mergeCoachMessages(_messages, [message]);
        _textController.clear();
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send message: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
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

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _errorMessage = null;
      });

      _updateRecordingDuration();
    } catch (e) {
      setState(() {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('permission') || errorMsg.contains('denied')) {
          _errorMessage =
              'Microphone permission denied. Please enable microphone access in settings.';
        } else {
          _errorMessage = 'Failed to start recording: ${e.toString()}';
        }
        _isRecording = false;
      });
    }
  }

  Future<void> _updateRecordingDuration() async {
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isRecording) {
        setState(() {
          _recordingDuration = _recordingDuration + const Duration(seconds: 1);
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      if (path != null) {
        _sendAudioMessage(File(path));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to stop recording: ${e.toString()}';
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
      setState(() {
        _messages = mergeCoachMessages(_messages, [message]);
        _recordingDuration = Duration.zero;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send audio: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
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
    return DateFormat('h:mm a').format(date);
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
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.errorContainer,
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_selectedConnectionId == null)
            const Expanded(
              child: Center(child: Text('No connected coaches available')),
            )
          else
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Start a conversation with $coachName',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Align(
                          alignment: message.isFromCoach
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: message.isFromCoach
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.text != null)
                                  Text(
                                    message.text!,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                if (message.audioUrl != null)
                                  const Row(
                                    children: [
                                      Icon(Icons.mic, size: 20),
                                      SizedBox(width: 8),
                                      Text('Audio message'),
                                    ],
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(message.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
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
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.errorContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _stopRecording,
                    child: const Text('Stop & Send'),
                  ),
                ],
              ),
            ),
          if (_selectedConnectionId != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed:
                        _isSending || _isRecording ? null : _startRecording,
                    tooltip: 'Record audio',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isSending ? null : _sendTextMessage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
