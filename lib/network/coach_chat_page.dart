import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/services/coach_service.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/subscription/widgets/upgrade_prompt.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Chat page for communicating with coaches
class CoachChatPage extends StatefulWidget {
  final String? coachId;

  const CoachChatPage({super.key, this.coachId});

  @override
  State<CoachChatPage> createState() => _CoachChatPageState();
}

class _CoachChatPageState extends State<CoachChatPage> {
  final CoachService _coachService = sl<CoachService>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();

  List<Coach> _coaches = [];
  Coach? _selectedCoach;
  List<CoachMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isRecording = false;
  String? _errorMessage;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadCoaches();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadCoaches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If a specific coachId is provided, load that coach directly
      if (widget.coachId != null) {
        final coach = await _coachService.getCoachById(widget.coachId!);
        setState(() {
          _coaches = [coach];
          _selectedCoach = coach;
          _isLoading = false;
        });
        _loadMessages();
      } else {
        // Otherwise, load all coaches and select the first one
        final coaches = await _coachService.getCoaches();
        setState(() {
          _coaches = coaches;
          if (coaches.isNotEmpty && _selectedCoach == null) {
            _selectedCoach = coaches.first;
            _loadMessages();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load coaches: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_selectedCoach == null) return;

    try {
      final messages = await _coachService.getMessages(_selectedCoach!.id);
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: ${e.toString()}';
      });
    }
  }

  Future<void> _sendTextMessage() async {
    if (_selectedCoach == null || _textController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final message = await _coachService.sendTextMessage(
        _selectedCoach!.id,
        _textController.text.trim(),
      );
      setState(() {
        _messages.add(message);
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
      // Skip permission check - let start() handle it
      // This avoids crashes from hasPermission() method
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
    if (_selectedCoach == null) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final message = await _coachService.sendAudioMessage(
        _selectedCoach!.id,
        audioFile,
      );
      setState(() {
        _messages.add(message);
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

  Future<void> _pickAndSendFile() async {
    if (_selectedCoach == null) return;

    // Check subscription limits
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final storageLimitMB = subscriptionProvider.getFileStorageLimitMB();
    
    if (storageLimitMB != null) {
      try {
        await subscriptionProvider.refresh();
        final usage = subscriptionProvider.usage;
        if (usage == null) return;
        if (usage.fileStorage.megabytes >= storageLimitMB) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => UpgradePromptDialog(
                requiredTier: SubscriptionTier.pro,
                featureName: 'File storage',
              ),
            );
          }
          return;
        }
      } catch (e) {
        // If we can't check usage, proceed anyway (backend will enforce)
        debugPrint('Could not check usage: $e');
      }
    }

    try {
      final result = await FilePicker.pickFiles();
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Check if file would exceed storage limit
        if (storageLimitMB != null) {
          try {
            await subscriptionProvider.refresh();
            final usage = subscriptionProvider.usage;
            if (usage == null) {
              setState(() {
                _isSending = false;
              });
              return;
            }
            final fileSizeMB = file.lengthSync() / (1024 * 1024);
            
            if (usage.fileStorage.megabytes + fileSizeMB > storageLimitMB) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File would exceed storage limit. Please upgrade your plan.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                showDialog(
                  context: context,
                  builder: (context) => UpgradePromptDialog(
                    requiredTier: SubscriptionTier.pro,
                    featureName: 'File storage',
                  ),
                );
              }
              return;
            }
          } catch (e) {
            // If we can't check, proceed anyway (backend will enforce)
            debugPrint('Could not check storage: $e');
          }
        }
        
        setState(() {
          _isSending = true;
          _errorMessage = null;
        });

        try {
          final message =
              await _coachService.sendFile(_selectedCoach!.id, file);
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to send file: ${e.toString()}';
          });
        } finally {
          setState(() {
            _isSending = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: ${e.toString()}';
      });
    }
  }

  Future<void> _pickAndSendPhoto() async {
    if (_selectedCoach == null) return;

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final file = File(image.path);
        setState(() {
          _isSending = true;
          _errorMessage = null;
        });

        try {
          final message =
              await _coachService.sendPhoto(_selectedCoach!.id, file);
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to send photo: ${e.toString()}';
          });
        } finally {
          setState(() {
            _isSending = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick photo: ${e.toString()}';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCoach?.fullName ?? 'Select a Coach'),
        actions: [
          if (_coaches.length > 1)
            PopupMenuButton<Coach>(
              icon: const Icon(Icons.more_vert),
              onSelected: (coach) {
                setState(() {
                  _selectedCoach = coach;
                  _messages = [];
                });
                _loadMessages();
              },
              itemBuilder: (context) => _coaches.map((coach) {
                return PopupMenuItem<Coach>(
                  value: coach,
                  child: Text(coach.fullName),
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
          else if (_selectedCoach == null)
            const Expanded(
              child: Center(child: Text('No coaches available')),
            )
          else
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Start a conversation with ${_selectedCoach!.fullName}',
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
                                  Row(
                                    children: [
                                      Icon(Icons.mic, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Audio message'),
                                    ],
                                  ),
                                if (message.fileUrl != null)
                                  Row(
                                    children: [
                                      Icon(Icons.attach_file, size: 20),
                                      const SizedBox(width: 8),
                                      Text('File attachment'),
                                    ],
                                  ),
                                if (message.imageUrl != null)
                                  Image.network(
                                    message.imageUrl!,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
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
                  icon: const Icon(Icons.attach_file),
                  onPressed: _isSending ? null : _pickAndSendFile,
                  tooltip: 'Send file',
                ),
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _isSending ? null : _pickAndSendPhoto,
                  tooltip: 'Send photo',
                ),
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
