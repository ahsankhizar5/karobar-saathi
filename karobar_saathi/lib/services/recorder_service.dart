/// Microphone capture for voice transaction entry.
library;

import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_platform_interface/record_platform_interface.dart';

/// Raised when recording cannot start or stop cleanly.
class RecorderException implements Exception {
  RecorderException(this.message, {this.permanentlyDenied = false});

  final String message;

  /// True when the user selected "Don't ask again"; the caller should offer to
  /// open system settings.
  final bool permanentlyDenied;

  @override
  String toString() => message;
}

/// Thin wrapper around the native Android recorder and file paths.
class RecorderService {
  RecorderService()
      : _recorderId =
            'karobar-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  final String _recorderId;
  bool _created = false;
  String? _currentPath;

  Future<void> _ensureCreated() async {
    if (_created) return;
    await RecordPlatform.instance.create(_recorderId);
    _created = true;
  }

  /// Requests the microphone permission, returning true when granted.
  Future<bool> ensurePermission() async {
    final PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted || status.isLimited) return true;
    throw RecorderException(
      status.isPermanentlyDenied
          ? 'Microphone access is blocked. Enable it in system settings to '
              'record your transactions.'
          : 'Microphone permission is required to record your transactions.',
      permanentlyDenied: status.isPermanentlyDenied,
    );
  }

  Future<bool> get isRecording async {
    await _ensureCreated();
    return RecordPlatform.instance.isRecording(_recorderId);
  }

  /// Live input amplitude, used to animate the recording indicator.
  Stream<Amplitude> amplitudeStream() =>
      Stream<Duration>.periodic(const Duration(milliseconds: 200)).asyncMap(
        (Duration _) async {
          await _ensureCreated();
          return RecordPlatform.instance.getAmplitude(_recorderId);
        },
      );

  /// Starts capturing to an m4a file in the app's temporary directory.
  Future<void> start() async {
    await ensurePermission();
    await _ensureCreated();

    if (!await RecordPlatform.instance.hasPermission(_recorderId)) {
      throw RecorderException('Microphone permission is required.');
    }

    final Directory dir = await getTemporaryDirectory();
    final String path =
        '${dir.path}/karobar_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentPath = path;

    try {
      await RecordPlatform.instance.start(
        _recorderId,
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
    } catch (error) {
      _currentPath = null;
      throw RecorderException('Could not start recording: $error');
    }
  }

  /// Stops capture and returns the recorded file path, or null if nothing was
  /// written.
  Future<String?> stop() async {
    try {
      await _ensureCreated();
      final String? path =
          await RecordPlatform.instance.stop(_recorderId) ?? _currentPath;
      _currentPath = null;
      if (path == null) return null;

      final File file = File(path);
      if (!await file.exists() || await file.length() < 512) {
        if (await file.exists()) {
          await file.delete();
        }
        return null;
      }
      return path;
    } catch (error) {
      _currentPath = null;
      throw RecorderException('Could not save the recording: $error');
    }
  }

  /// Aborts capture and deletes any partial file.
  Future<void> cancel() async {
    try {
      await _ensureCreated();
      final String? path =
          await RecordPlatform.instance.stop(_recorderId) ?? _currentPath;
      if (path != null) {
        final File file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {
      // Cancellation is best-effort.
    } finally {
      _currentPath = null;
    }
  }

  /// Removes a recording once it has been uploaded.
  Future<void> discard(String? path) async {
    if (path == null) return;
    try {
      final File file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> openSystemSettings() => openAppSettings();

  void dispose() {
    if (_created) {
      unawaited(RecordPlatform.instance.dispose(_recorderId));
    }
  }
}
