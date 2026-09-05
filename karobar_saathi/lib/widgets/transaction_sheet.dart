/// Bottom sheet for adding transactions by voice or by typing.
///
/// The manual text field is visible by default (it is the reliable path), with
/// microphone recording offered alongside it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record_platform_interface/record_platform_interface.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/api_service.dart';
import '../services/recorder_service.dart';
import '../widgets/parsed_entry_card.dart';

/// Opens the add-transaction sheet. Resolves to true when entries were saved.
Future<bool> showTransactionSheet(BuildContext context) async {
  final bool? saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => const TransactionSheet(),
  );
  return saved ?? false;
}

enum _Stage { input, parsing, review, saving }

class TransactionSheet extends ConsumerStatefulWidget {
  const TransactionSheet({super.key});

  @override
  ConsumerState<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends ConsumerState<TransactionSheet> {
  final TextEditingController _textController = TextEditingController();

  _Stage _stage = _Stage.input;
  String? _error;

  bool _isRecording = false;
  String? _pendingAudioPath;
  Duration _recordDuration = Duration.zero;
  double _amplitude = 0;
  Timer? _durationTimer;
  StreamSubscription<Amplitude>? _amplitudeSub;

  List<ParsedEntry> _drafts = <ParsedEntry>[];
  String _rawTranscript = '';

  @override
  void dispose() {
    _durationTimer?.cancel();
    _amplitudeSub?.cancel();
    _textController.dispose();
    super.dispose();
  }

  RecorderService get _recorder => ref.read(recorderServiceProvider);
  ApiService get _api => ref.read(apiServiceProvider);
  String get _userId => ref.read(currentUserIdProvider);

  bool get _busy => _stage == _Stage.parsing || _stage == _Stage.saving;

  /// Maps a recorder failure to a localized, user-facing message.
  String _recorderMessage(RecorderException error) {
    final AppStrings s = context.l10n;
    switch (error.kind) {
      case RecorderErrorKind.permissionDenied:
        return s.micPermissionDenied;
      case RecorderErrorKind.permissionPermanentlyDenied:
        return s.micPermanentlyDenied;
      case RecorderErrorKind.startFailed:
        return s.recordStartFailed;
      case RecorderErrorKind.saveFailed:
        return s.recordSaveFailed;
    }
  }

  /// True while at least one draft is still ambiguous or amountless.
  bool get _hasUnclearDrafts => _drafts.any((ParsedEntry e) => e.isUnclear);

  // ------------------------------------------------------------- recording

  Future<void> _startRecording() async {
    setState(() => _error = null);
    try {
      await _recorder.start();
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (Timer _) {
        if (mounted) {
          setState(() => _recordDuration += const Duration(seconds: 1));
        }
      });
      _amplitudeSub?.cancel();
      _amplitudeSub = _recorder.amplitudeStream().listen((Amplitude amp) {
        if (!mounted) return;
        // Map roughly -45..0 dBFS onto 0..1.
        final double normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0);
        setState(() => _amplitude = normalized);
      });
      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });
      }
    } on RecorderException catch (error) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _error = _recorderMessage(error);
      });
      if (error.permanentlyDenied) {
        _promptOpenSettings();
      }
    }
  }

  Future<void> _stopRecordingAndSend() async {
    _durationTimer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    String? path;
    try {
      path = await _recorder.stop();
    } on RecorderException catch (error) {
      if (mounted) setState(() => _error = _recorderMessage(error));
    }

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _amplitude = 0;
      _pendingAudioPath = path;
    });

    if (path == null) {
      setState(() => _error = context.l10n.recordingTooShort);
      return;
    }
    await _submitAudio(path);
  }

  Future<void> _cancelRecording() async {
    _durationTimer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    await _recorder.cancel();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _amplitude = 0;
      _recordDuration = Duration.zero;
    });
  }

  void _promptOpenSettings() {
    final AppStrings s = context.l10n;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(s.micBlocked),
        action: SnackBarAction(
          label: s.settings,
          onPressed: () => _recorder.openSystemSettings(),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- parsing

  Future<void> _submitAudio(String path) async {
    setState(() {
      _stage = _Stage.parsing;
      _error = null;
    });
    try {
      final TranscriptResult result = await _api.transcribeAudio(
        userId: _userId,
        audioFilePath: path,
        // Any typed text acts as a transcription fallback.
        fallbackText: _textController.text,
      );
      await _recorder.discard(path);
      _pendingAudioPath = null;
      _applyResult(result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.input;
        _error = _apiErrorMessage(error);
      });
    }
  }

  Future<void> _submitText() async {
    final String text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = context.l10n.typeEntryEmpty);
      return;
    }
    setState(() {
      _stage = _Stage.parsing;
      _error = null;
    });
    try {
      final TranscriptResult result =
          await _api.parseText(userId: _userId, text: text);
      _applyResult(result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.input;
        _error = _apiErrorMessage(error);
      });
    }
  }

  /// Transport timeouts usually mean the hosted backend is cold-starting, so
  /// they get a dedicated "server is waking up" message instead of a raw
  /// network error.
  String _apiErrorMessage(ApiException error) =>
      error.isTimeout ? context.l10n.serverWaking : error.message;

  void _applyResult(TranscriptResult result) {
    if (!mounted) return;
    if (result.parsedEntries.isEmpty) {
      setState(() {
        _stage = _Stage.input;
        _error = context.l10n.noTransactionsFound(result.rawTranscript);
      });
      return;
    }
    setState(() {
      _drafts = List<ParsedEntry>.of(result.parsedEntries);
      _rawTranscript = result.rawTranscript;
      _stage = _Stage.review;
      _error = null;
    });
  }

  // ---------------------------------------------------------------- saving

  Future<void> _save() async {
    if (_hasUnclearDrafts || _drafts.isEmpty) return;
    setState(() {
      _stage = _Stage.saving;
      _error = null;
    });
    try {
      await _api.batchConfirm(
        userId: _userId,
        entries: _drafts,
        rawTranscript: _rawTranscript,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.review;
        _error = _apiErrorMessage(error);
      });
    }
  }

  /// Discards one draft, returning to the input stage if none remain.
  void _removeDraft(int index) {
    if (index < 0 || index >= _drafts.length) return;
    setState(() {
      _drafts.removeAt(index);
      _error = null;
      if (_drafts.isEmpty) {
        _stage = _Stage.input;
      }
    });
  }

  void _backToInput() {
    setState(() {
      _stage = _Stage.input;
      _drafts = <ParsedEntry>[];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double maxHeight = MediaQuery.of(context).size.height * 0.92;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _DragHandle(),
            _Header(
              stage: _stage,
              onBack: _stage == _Stage.review ? _backToInput : null,
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: _stage == _Stage.review || _stage == _Stage.saving
                    ? _buildReview(theme)
                    : _buildInput(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ input stage

  Widget _buildInput(ThemeData theme) {
    final ColorScheme scheme = theme.colorScheme;
    final AppStrings s = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.typeOrSpeak,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        // Manual text entry is always visible — the dependable path.
        TextField(
          controller: _textController,
          minLines: 3,
          maxLines: 6,
          enabled: !_busy && !_isRecording,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: s.whatHappenedLabel,
            hintText: s.whatHappenedHint,
            alignLabelWithHint: true,
            prefixIcon: const Icon(Icons.edit_note_rounded),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy || _isRecording ? null : _submitText,
          icon: _stage == _Stage.parsing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_rounded),
          label: Text(_stage == _Stage.parsing
              ? s.readingEntry
              : s.convertToEntries),
        ),
        if (_stage == _Stage.parsing) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            s.parsingSlowHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],

        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(s.orSpeak,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),

        _RecordControl(
          isRecording: _isRecording,
          amplitude: _amplitude,
          duration: _recordDuration,
          enabled: !_busy,
          onStart: _startRecording,
          onStop: _stopRecordingAndSend,
          onCancel: _cancelRecording,
        ),

        if (_pendingAudioPath != null && !_isRecording) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            s.recordingCaptured,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],

        if (_error != null) ...<Widget>[
          const SizedBox(height: 20),
          _ErrorBanner(message: _error!),
        ],
      ],
    );
  }

  // ----------------------------------------------------------- review stage

  Widget _buildReview(ThemeData theme) {
    final ColorScheme scheme = theme.colorScheme;
    final AppStrings s = context.l10n;
    final int unclearCount =
        _drafts.where((ParsedEntry e) => e.isUnclear).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_rawTranscript.isNotEmpty) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(s.weHeard,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                  '"$_rawTranscript"',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (unclearCount > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.info_outline_rounded,
                    color: scheme.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.needsAnswerBanner(unclearCount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        for (int i = 0; i < _drafts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ParsedEntryCard(
              // Index keys keep each card's State alive while editing; the card
              // resyncs its fields via didUpdateWidget if drafts shift.
              key: ValueKey<int>(i),
              index: i,
              entry: _drafts[i],
              onChanged: (ParsedEntry updated) =>
                  setState(() => _drafts[i] = updated),
              onRemove: () => _removeDraft(i),
            ),
          ),

        if (_error != null) ...<Widget>[
          _ErrorBanner(message: _error!),
          const SizedBox(height: 16),
        ],

        FilledButton.icon(
          // Blocked while any entry is unclear.
          onPressed: _hasUnclearDrafts || _drafts.isEmpty || _busy
              ? null
              : _save,
          icon: _stage == _Stage.saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(
            _stage == _Stage.saving
                ? s.saving
                : _hasUnclearDrafts
                    ? s.answerToSave
                    : s.saveNEntries(_drafts.length),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : _backToInput,
          child: Text(s.startOver),
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.stage, this.onBack});

  final _Stage stage;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.l10n;
    final bool reviewing = stage == _Stage.review || stage == _Stage.saving;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        children: <Widget>[
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: s.backToEntry,
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(
              reviewing ? s.checkBeforeSaving : s.addTransactionsTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(false),
            icon: const Icon(Icons.close_rounded),
            tooltip: s.close,
          ),
        ],
      ),
    );
  }
}

/// Microphone button with a live amplitude ring and elapsed timer.
class _RecordControl extends StatelessWidget {
  const _RecordControl({
    required this.isRecording,
    required this.amplitude,
    required this.duration,
    required this.enabled,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
  });

  final bool isRecording;
  final double amplitude;
  final Duration duration;
  final bool enabled;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  String get _timeLabel {
    final String minutes = duration.inMinutes.remainder(60).toString();
    final String seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppStrings s = context.l10n;
    final double ring = 96 + (isRecording ? amplitude * 28 : 0);

    return Column(
      children: <Widget>[
        Semantics(
          button: true,
          label: isRecording
              ? s.recordingElapsed(_timeLabel)
              : s.tapMicIdle,
          child: GestureDetector(
            onTap: enabled ? (isRecording ? onStop : onStart) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: ring,
              height: ring,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording
                    ? scheme.error.withOpacity(0.16)
                    : scheme.primary.withOpacity(0.12),
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: enabled
                        ? (isRecording ? scheme.error : scheme.primary)
                        : scheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 34,
                    color: enabled
                        ? (isRecording ? scheme.onError : scheme.onPrimary)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isRecording
              ? s.recordingElapsed(_timeLabel)
              : s.tapMicIdle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isRecording ? scheme.error : scheme.onSurfaceVariant,
            fontWeight: isRecording ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        if (isRecording) ...<Widget>[
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(s.discardRecording),
          ),
        ],
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded,
              color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
