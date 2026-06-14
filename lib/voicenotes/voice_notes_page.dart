import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/voice_note.dart';
import 'package:projectbrain/services/voice_note_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Voice notes page for managing recorded voice notes
class VoiceNotesPage extends StatefulWidget {
  const VoiceNotesPage({super.key});

  @override
  State<VoiceNotesPage> createState() => _VoiceNotesPageState();
}

class _VoiceNotesPageState extends State<VoiceNotesPage> {
  final VoiceNoteService _voiceNoteService = sl<VoiceNoteService>();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<VoiceNote> _voiceNotes = [];
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  final TextEditingController _descriptionController = TextEditingController();

  // Playback state
  String? _currentlyPlayingId;
  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  File? _downloadedAudioFile; // Cache downloaded audio file
  String? _downloadingVoiceNoteId; // Track which voice note is being downloaded

  // Audio player stream subscriptions, cancelled in dispose to avoid leaks.
  final List<StreamSubscription<dynamic>> _audioSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _loadVoiceNotes();
  }

  Future<void> _cleanupDownloadedFile() async {
    if (_downloadedAudioFile != null) {
      try {
        if (await _downloadedAudioFile!.exists()) {
          await _downloadedAudioFile!.delete();
          logDebug('[VoiceNotesPage] Cleaned up downloaded audio file');
        }
      } catch (e) {
        logError('[VoiceNotesPage] Error cleaning up audio file: $e');
      }
      _downloadedAudioFile = null;
    }
  }

  @override
  void dispose() {
    for (final subscription in _audioSubscriptions) {
      subscription.cancel();
    }
    _audioSubscriptions.clear();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _descriptionController.dispose();
    _cleanupDownloadedFile();
    super.dispose();
  }

  Future<void> _setupAudioPlayer() async {
    try {
      // Configure audio session for playback
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));

      _audioSubscriptions.add(_audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _playbackPosition = position;
          });
        }
      }));
      _audioSubscriptions.add(_audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _playbackDuration = duration ?? Duration.zero;
          });
        }
      }));
      _audioSubscriptions.add(_audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _currentlyPlayingId = null;
              _playbackPosition = Duration.zero;
            }
          });
        }
      }));
    } catch (e) {
      logError('[VoiceNotesPage] Error setting up audio player: $e');
      // Audio player setup failed - this usually means the plugin isn't registered
      // User needs to do a full app rebuild
    }
  }

  Future<void> _playVoiceNote(VoiceNote voiceNote) async {
    try {
      // If already playing this note, pause it
      if (_currentlyPlayingId == voiceNote.id && _isPlaying) {
        await _audioPlayer.pause();
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      // If paused, resume playback
      if (_currentlyPlayingId == voiceNote.id && !_isPlaying) {
        await _audioPlayer.play();
        if (!mounted) return;
        setState(() {
          _isPlaying = true;
        });
        return;
      }

      // If playing a different note, stop it first and clean up old file
      if (_currentlyPlayingId != null && _currentlyPlayingId != voiceNote.id) {
        await _audioPlayer.stop();
        await _cleanupDownloadedFile();
        // Small delay to ensure player is ready for new source
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Download the audio file if we don't have it cached
      File? audioFile = _downloadedAudioFile;
      if (audioFile == null || !await audioFile.exists()) {
        if (!mounted) return;
        setState(() {
          _errorMessage = null; // Clear any previous errors
          _downloadingVoiceNoteId = voiceNote.id;
        });

        try {
          logDebug(
              '[VoiceNotesPage] Downloading voice note audio: ${voiceNote.id}');
          audioFile =
              await _voiceNoteService.downloadVoiceNoteAudio(voiceNote.id);
          _downloadedAudioFile = audioFile;
          logDebug('[VoiceNotesPage] Downloaded audio file: ${audioFile.path}');
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _downloadingVoiceNoteId = null;
            _errorMessage = 'Failed to download audio: ${e.toString()}';
          });
          logError('[VoiceNotesPage] Error downloading audio: $e');
          return;
        } finally {
          if (mounted) {
            setState(() {
              _downloadingVoiceNoteId = null;
            });
          }
        }
      }

      // Stop any current playback before setting new source
      await _audioPlayer.stop();
      if (!mounted) return;

      // Update UI first to show playback controls before audio starts
      setState(() {
        _currentlyPlayingId = voiceNote.id;
        _isPlaying = false; // Will be set to true when play() completes
      });

      // Use local file path for playback
      final audioSource = AudioSource.file(audioFile.path);
      await _audioPlayer.setAudioSource(audioSource);
      logDebug(
          '[VoiceNotesPage] Audio source set from local file: ${audioFile.path}');

      // Play the audio
      await _audioPlayer.play();
      logDebug('[VoiceNotesPage] Playing voice note: ${voiceNote.id}');
      if (!mounted) return;

      // Update playing state (the playerStateStream will also update this)
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to play voice note: ${e.toString()}';
        // Provide helpful messages for specific errors
        if (e.toString().contains('MissingPluginException')) {
          errorMsg =
              'Audio player not available. Please restart the app completely (not just hot reload).';
        } else if (e.toString().contains('-11850') ||
            e.toString().contains('Operation Stopped')) {
          errorMsg =
              'Audio playback failed. The audio file may be unavailable or in an unsupported format.';
        } else if (e.toString().contains('404') ||
            e.toString().contains('Not Found')) {
          errorMsg = 'Voice note audio file not found on server.';
        } else if (e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          errorMsg = 'Authentication failed. Please try logging in again.';
        }
        setState(() {
          _errorMessage = errorMsg;
        });
      }
      logError('[VoiceNotesPage] Error playing voice note: $e');
    }
  }

  Future<void> _playLocalRecording() async {
    if (_recordingPath == null) return;

    try {
      // If already playing, pause it
      if (_currentlyPlayingId == 'local' && _isPlaying) {
        await _audioPlayer.pause();
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      // If paused, resume playback
      if (_currentlyPlayingId == 'local' && !_isPlaying) {
        await _audioPlayer.play();
        if (!mounted) return;
        setState(() {
          _isPlaying = true;
        });
        return;
      }

      // If playing a different audio, stop it first
      if (_currentlyPlayingId != null && _currentlyPlayingId != 'local') {
        await _audioPlayer.stop();
      }
      if (!mounted) return;

      // Update UI first to show playback controls before audio starts
      setState(() {
        _currentlyPlayingId = 'local';
        _isPlaying = false; // Will be set to true when play() completes
      });

      // Set audio source from local file
      await _audioPlayer.setFilePath(_recordingPath!);
      await _audioPlayer.play();
      if (!mounted) return;

      // Update playing state (the playerStateStream will also update this)
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to play recording: ${e.toString()}';
        // Provide helpful message for MissingPluginException
        if (e.toString().contains('MissingPluginException')) {
          errorMsg =
              'Audio player not available. Please restart the app completely (not just hot reload).';
        }
        setState(() {
          _errorMessage = errorMsg;
        });
      }
      logError('[VoiceNotesPage] Error playing local recording: $e');
    }
  }

  Future<void> _loadVoiceNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final voiceNotes = await _voiceNoteService.getVoiceNotes();
      if (!mounted) return;
      setState(() {
        _voiceNotes = voiceNotes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load voice notes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      // Skip permission check - let start() handle it
      // This avoids crashes from hasPermission() method
      // Get temporary directory for recording
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/voice_note_$timestamp.m4a';

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
        _recordingPath = path;
        _recordingDuration = Duration.zero;
        _errorMessage = null;
        _descriptionController.clear();
      });

      // Update duration while recording
      _updateRecordingDuration();
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        if (path != null) {
          _recordingPath = path;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to stop recording: ${e.toString()}';
        _isRecording = false;
      });
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingDuration = Duration.zero;
        _descriptionController.clear();
      });
    } catch (e) {
      logError('[VoiceNotesPage] Error canceling recording: $e');
    }
  }

  Future<void> _uploadRecording() async {
    if (_recordingPath == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final file = File(_recordingPath!);
      if (!await file.exists()) {
        throw Exception('Recording file not found');
      }

      final description = _descriptionController.text.trim();
      await _voiceNoteService.uploadVoiceNote(
        file,
        description: description.isEmpty ? null : description,
      );
      if (!mounted) return;

      setState(() {
        _successMessage = 'Voice note uploaded successfully';
        _recordingPath = null;
        _recordingDuration = Duration.zero;
        _descriptionController.clear();
      });

      // Reload voice notes list
      await _loadVoiceNotes();

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to upload voice note: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteVoiceNote(String voiceNoteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice Note'),
        content: const Text('Are you sure you want to delete this voice note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _voiceNoteService.deleteVoiceNote(voiceNoteId);
        await _loadVoiceNotes();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Voice note deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e.toString()}')),
          );
        }
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return DateFormat('MMM d, y • h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Notes')),
      body: SafeArea(
        child: Column(
          children: [
            // Error/Success messages
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
            if (_successMessage != null)
              Container(
                width: double.infinity,
                padding: AppInsets.screen,
                color: theme.colorScheme.primaryContainer,
                child: Text(
                  _successMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),

            // Recording controls
            if (_isRecording || _recordingPath != null)
              Container(
                padding: AppInsets.screen,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                child: Column(
                  children: [
                    if (_isRecording)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, color: theme.colorScheme.error),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            _formatDuration(_recordingDuration),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    if (_recordingPath != null && !_isRecording) ...[
                      Text(
                        'Recording complete',
                        style: theme.textTheme.bodyLarge,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      // Description input
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (optional)',
                          hintText: 'Add a description for this voice note',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.circularSm,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        maxLines: 2,
                        maxLength: 200,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      // Playback controls for local recording
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _currentlyPlayingId == 'local' && _isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            onPressed: _playLocalRecording,
                            color: theme.colorScheme.primary,
                          ),
                          if (_currentlyPlayingId == 'local')
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 8,
                                    child: Slider(
                                      value: _playbackDuration.inMilliseconds >
                                              0
                                          ? _playbackPosition.inMilliseconds /
                                              _playbackDuration.inMilliseconds
                                          : 0.0,
                                      onChanged: (value) async {
                                        final position = Duration(
                                          milliseconds: (value *
                                                  _playbackDuration
                                                      .inMilliseconds)
                                              .round(),
                                        );
                                        await _audioPlayer.seek(position);
                                      },
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${_formatDuration(_playbackPosition)} / ${_formatDuration(_playbackDuration)}',
                                      style: theme.textTheme.bodySmall,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                    SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isRecording)
                          ElevatedButton.icon(
                            onPressed: _stopRecording,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                            ),
                          )
                        else if (_recordingPath != null) ...[
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _uploadRecording,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload),
                            label: Text(
                              _isUploading ? 'Uploading...' : 'Upload',
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: _cancelRecording,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

            // Voice notes list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _voiceNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mic_none,
                                size: 64,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              SizedBox(height: AppSpacing.lg),
                              Text(
                                'No voice notes yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                'Tap the record button to create your first voice note',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: AppInsets.screen,
                          itemCount: _voiceNotes.length,
                          itemBuilder: (context, index) {
                            final voiceNote = _voiceNotes[index];
                            final isCurrentlyPlaying =
                                _currentlyPlayingId == voiceNote.id;
                            final isDownloading =
                                _downloadingVoiceNoteId == voiceNote.id;
                            return Card(
                              margin: EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          theme.colorScheme.primaryContainer,
                                      child: Icon(
                                        Icons.mic,
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    title: Text(
                                      voiceNote.description?.isNotEmpty == true
                                          ? voiceNote.description!
                                          : 'Voice Note',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (voiceNote.description?.isNotEmpty ==
                                            true)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: AppSpacing.xs),
                                            child: Text(
                                              voiceNote.fileName,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ),
                                        Text(
                                          _formatDate(voiceNote.createdAt),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isDownloading)
                                          const Padding(
                                            padding: AppInsets.screen,
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        else
                                          IconButton(
                                            icon: Icon(
                                              isCurrentlyPlaying && _isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                            ),
                                            onPressed: () =>
                                                _playVoiceNote(voiceNote),
                                            color: theme.colorScheme.primary,
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: isDownloading
                                              ? null
                                              : () => _deleteVoiceNote(
                                                  voiceNote.id),
                                          color: theme.colorScheme.error,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCurrentlyPlaying)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                        vertical: AppSpacing.sm,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 8,
                                            child: Slider(
                                              value: _playbackDuration
                                                          .inMilliseconds >
                                                      0
                                                  ? _playbackPosition
                                                          .inMilliseconds /
                                                      _playbackDuration
                                                          .inMilliseconds
                                                  : 0.0,
                                              onChanged: (value) async {
                                                final position = Duration(
                                                  milliseconds: (value *
                                                          _playbackDuration
                                                              .inMilliseconds)
                                                      .round(),
                                                );
                                                await _audioPlayer
                                                    .seek(position);
                                              },
                                            ),
                                          ),
                                          SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '${_formatDuration(_playbackPosition)} / ${_formatDuration(_playbackDuration)}',
                                              style: theme.textTheme.bodySmall,
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isRecording
          ? null
          : FloatingActionButton.extended(
              onPressed: _isRecording ? null : _startRecording,
              icon: const Icon(Icons.mic),
              label: const Text('Record'),
            ),
    );
  }
}
