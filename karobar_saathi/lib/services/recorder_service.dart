/// Microphone capture for voice transaction entry.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Why a recording operation failed, so the UI can show a localized message
/// (this service has no [BuildContext] to localize with itself).
enum RecorderErrorKind {
  /// Microphone permission was refused this time.
  permissionDenied,

  /// Microphone permission is permanently denied ("Don't ask again"); the
  /// caller should offer to open system settings.
  permissionPermanentlyDenied,

  /// The chosen audio encoder is not supported on this device.
  encoderUnsupported,

  /// The native recorder could not start capture.
  startFailed,

  /// The recording could not be finalized or saved.
  saveFailed,

  /// A start request arrived while already recording (defensive).
  alreadyRecording,
}

/// Raised when recording cannot start or stop cleanly.
///
/// [message] is an English fallback suitable for logs; the UI should prefer a
/// localized string chosen from [kind].
class RecorderException implements Exception {
  RecorderException(
    this.message, {
    required this.kind,
  });

  final String message;

  /// Machine-readable reason, used by the UI to pick a localized message.
  final RecorderErrorKind kind;

  /// True when the user selected "Don't ask again"; the caller should offer to
  /// open system settings.
  bool get permanentlyDenied =>
      kind == RecorderErrorKind.permissionPermanentlyDenied;

  @override
  String toString() => message;
}

/// Thin wrapper around the native recorder and file paths.
///
/// A fresh [AudioRecorder] is created for every recording session and disposed
/// immediately after [stop] or [cancel]. Reusing the same native recorder on
/// some Android devices causes the second [start] to fail, so this wrapper
/// treats the recorder as a per-session resource.
class RecorderService {
  RecorderService({AudioRecorder? recorder}) : _recorder = recorder;

  AudioRecorder? _recorder;
  bool _starting = false;
  String? _currentPath;

  /// Live input amplitude, used to animate the recording indicator.
  Stream<Amplitude> amplitudeStream({Duration interval = const Duration(milliseconds: 100)}) {
    final AudioRecorder? recorder = _recorder;
    if (recorder == null) {
      throw StateError('Recorder is not active.');
    }
    return recorder.onAmplitudeChanged(interval);
  }

  /// Native recorder state (recording / paused / stopped).
  Stream<RecordState> get onStateChanged {
    final AudioRecorder? recorder = _recorder;
    if (recorder == null) {
      throw StateError('Recorder is not active.');
    }
    return recorder.onStateChanged();
  }

  /// Creates the platform recorder ahead of time so the first [start] begins
  /// capture with no setup delay. Advisory: failures surface via [start].
  Future<void> prepare() async {
    _recorder ??= AudioRecorder();
    try {
      await _recorder!.hasPermission();
    } catch (_) {
      // Ignore — start() will raise any real error.
    }
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
      kind: status.isPermanentlyDenied
          ? RecorderErrorKind.permissionPermanentlyDenied
          : RecorderErrorKind.permissionDenied,
    );
  }

  /// Starts capturing to a file in the app's temporary directory.
  Future<void> start() async {
    if (_starting || await isRecording()) {
      throw RecorderException(
        'Already recording.',
        kind: RecorderErrorKind.alreadyRecording,
      );
    }
    _starting = true;

    try {
      await ensurePermission();

      // Use the prepared recorder or instantiate a fresh one for this session.
      _recorder ??= AudioRecorder();

      if (!await _recorder!.hasPermission()) {
        await _disposeRecorder();
        throw RecorderException(
          'Microphone permission is required.',
          kind: RecorderErrorKind.permissionDenied,
        );
      }

      final Directory dir = await getTemporaryDirectory();
      final String basePath =
          '${dir.path}/karobar_${DateTime.now().millisecondsSinceEpoch}';

      // Some OEM encoders fail silently with AAC; fall back to WAV when needed.
      final AudioEncoder encoder =
          await _recorder!.isEncoderSupported(AudioEncoder.aacLc)
              ? AudioEncoder.aacLc
              : AudioEncoder.wav;
      final String path = '$basePath.${encoder == AudioEncoder.wav ? 'wav' : 'm4a'}';
      _currentPath = path;

      await _recorder!.start(
        RecordConfig(
          encoder: encoder,
          sampleRate: 16000,
          numChannels: 1,
          androidConfig: const AndroidRecordConfig(
            audioSource: AndroidAudioSource.mic,
            manageBluetooth: false,
          ),
        ),
        path: path,
      );
    } on RecorderException {
      _currentPath = null;
      await _disposeRecorder();
      rethrow;
    } catch (error) {
      _currentPath = null;
      await _disposeRecorder();
      throw RecorderException(
        'Could not start recording: $error',
        kind: RecorderErrorKind.startFailed,
      );
    } finally {
      _starting = false;
    }
  }

  /// Stops capture and returns the recorded file path, or null if nothing was
  /// written.
  Future<String?> stop() async {
    try {
      final String? path = await _recorder?.stop();
      _currentPath = null;
      await _disposeRecorder();
      if (path == null) return null;

      final File file = File(path);
      if (!await file.exists()) return null;

      final int length = await file.length();
      if (length < 512) {
        await file.delete();
        return null;
      }
      return path;
    } on RecorderException {
      _currentPath = null;
      await _disposeRecorder();
      rethrow;
    } catch (error) {
      _currentPath = null;
      await _disposeRecorder();
      throw RecorderException(
        'Could not save the recording: $error',
        kind: RecorderErrorKind.saveFailed,
      );
    }
  }

  /// Aborts capture and deletes any partial file.
  Future<void> cancel() async {
    try {
      await _recorder?.cancel();
      final String? path = _currentPath;
      _currentPath = null;
      await _disposeRecorder();
      if (path != null) {
        final File file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {
      // Cancellation is best-effort.
    }
  }

  /// Disposes the active recorder and clears the reference so the next
  /// recording session starts with a fresh native instance.
  Future<void> _disposeRecorder() async {
    final AudioRecorder? recorder = _recorder;
    _recorder = null;
    if (recorder != null) {
      try {
        await recorder.dispose();
      } catch (_) {
        // Ignore disposal errors.
      }
    }
  }

  /// True when the native recorder is currently capturing audio.
  Future<bool> isRecording() async {
    final AudioRecorder? recorder = _recorder;
    if (recorder == null) return false;
    return recorder.isRecording();
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

  Future<void> dispose() async {
    await cancel();
  }
}

/// Normalizes an amplitude reading to a 0..1 visual level.
///
/// [current] is expected in dBFS (negative, with louder values closer to 0).
/// The result is curved so ordinary speech produces a visibly moving bar.
double normalizeAmplitude(double current, {double floor = -50}) {
  final double linear = ((current - floor) / -floor).clamp(0.0, 1.0);
  return pow(linear, 0.7).toDouble();
}
