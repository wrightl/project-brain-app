import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Prefixes of the audio files the app writes to the temporary directory
/// (recordings waiting to upload and downloaded voice notes).
const _audioFilePrefixes = ['voice_note_', 'coach_audio_'];

/// Delete a file the app wrote, ignoring a file that is already gone.
Future<void> deleteFileQuietly(File file) async {
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    logWarning('[TemporaryFiles] Could not delete ${file.path}', e);
  }
}

/// Remove recordings, downloaded voice notes and picked-file copies so the
/// next account on this device cannot find them.
Future<void> deleteUserTemporaryFiles() async {
  try {
    final directory = await getTemporaryDirectory();
    await for (final entity in directory.list()) {
      final name = entity.uri.pathSegments.last;
      if (entity is File &&
          _audioFilePrefixes.any((prefix) => name.startsWith(prefix))) {
        await deleteFileQuietly(entity);
      }
    }
  } catch (e) {
    logWarning('[TemporaryFiles] Could not clean temporary audio files', e);
  }

  try {
    await FilePicker.clearTemporaryFiles();
  } catch (e) {
    logWarning('[TemporaryFiles] Could not clear file picker cache', e);
  }
}
