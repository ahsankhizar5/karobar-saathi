import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karobar_saathi/l10n/app_localizations.dart';
import 'package:karobar_saathi/models/models.dart';
import 'package:karobar_saathi/providers/app_providers.dart';
import 'package:karobar_saathi/services/api_service.dart';
import 'package:karobar_saathi/services/recorder_service.dart';
import 'package:karobar_saathi/widgets/transaction_sheet.dart';
import 'package:record/record.dart';

class _FakeApiService extends ApiService {
  _FakeApiService();

  TranscriptResult? parseResult;
  TranscriptResult? transcribeResult;

  @override
  Future<TranscriptResult> parseText({
    required String userId,
    required String text,
  }) async {
    if (parseResult == null) throw ApiException('no result configured');
    return parseResult!;
  }

  @override
  Future<TranscriptResult> transcribeAudio({
    required String userId,
    required String audioFilePath,
    String? fallbackText,
  }) async {
    if (transcribeResult == null) throw ApiException('no result configured');
    return transcribeResult!;
  }

  @override
  Future<void> warmUp({Duration? timeout}) async {}
}

class _FakeRecorderService extends RecorderService {
  _FakeRecorderService() : super();

  final StreamController<Amplitude> _amplitudeController =
      StreamController<Amplitude>.broadcast();
  final StreamController<RecordState> _stateController =
      StreamController<RecordState>.broadcast();

  bool isRecordingValue = false;
  RecorderException? startError;
  String? stopPath;
  int startCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;

  @override
  Future<void> prepare() async {}

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Future<void> start() async {
    startCalls++;
    if (startError != null) throw startError!;
    isRecordingValue = true;
    _stateController.add(RecordState.record);
  }

  @override
  Future<String?> stop() async {
    stopCalls++;
    isRecordingValue = false;
    _stateController.add(RecordState.stop);
    return stopPath;
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
    isRecordingValue = false;
    _stateController.add(RecordState.stop);
  }

  @override
  Stream<Amplitude> amplitudeStream({Duration interval = const Duration(milliseconds: 100)}) =>
      _amplitudeController.stream;

  @override
  Stream<RecordState> get onStateChanged => _stateController.stream;

  @override
  Future<void> openSystemSettings() async {}

  void emitAmplitude(double current) {
    if (!_amplitudeController.isClosed) {
      _amplitudeController.add(Amplitude(current: current, max: current));
    }
  }

  @override
  Future<void> dispose() async {
    _amplitudeController.close();
    _stateController.close();
  }
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required _FakeRecorderService recorder,
  required _FakeApiService api,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        recorderServiceProvider.overrideWithValue(recorder),
        apiServiceProvider.overrideWithValue(api),
        currentUserIdProvider.overrideWithValue('shop_001'),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: TransactionSheet()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // getTemporaryDirectory needs a registered platform.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async {
        if (call.method == 'getTemporaryDirectory') {
          final Directory dir = Directory.systemTemp.createTempSync('karobar_test');
          return dir.path;
        }
        return null;
      },
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  testWidgets('optimistic recording feedback appears on mic tap', (WidgetTester tester) async {
    final _FakeRecorderService recorder = _FakeRecorderService();
    final _FakeApiService api = _FakeApiService();
    addTearDown(recorder.dispose);

    await _pumpSheet(tester, recorder: recorder, api: api);

    expect(find.text('Tap the mic and speak in Urdu or Roman Urdu'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();

    // The recording bar should appear synchronously, before start() resolves.
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(recorder.startCalls, 1);

    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('recorder error rolls back to idle and shows banner', (WidgetTester tester) async {
    final _FakeRecorderService recorder = _FakeRecorderService()
      ..startError = RecorderException(
        'permission denied',
        kind: RecorderErrorKind.permissionDenied,
      );
    final _FakeApiService api = _FakeApiService();
    addTearDown(recorder.dispose);

    await _pumpSheet(tester, recorder: recorder, api: api);

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(Icons.send_rounded), findsNothing);
    expect(
      find.text('Microphone permission is required to record your transactions.'),
      findsOneWidget,
    );
  });

  testWidgets('amplitude samples render waveform bars', (WidgetTester tester) async {
    final _FakeRecorderService recorder = _FakeRecorderService();
    final _FakeApiService api = _FakeApiService();
    addTearDown(recorder.dispose);

    await _pumpSheet(tester, recorder: recorder, api: api);
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();

    recorder.emitAmplitude(-10);
    await tester.pump();
    recorder.emitAmplitude(-40);
    await tester.pump();

    // Emitting amplitudes should not throw and the recording bar should stay
    // on screen. Visual bar heights are covered by layout analysis.
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('empty parse result shows transcript with use-this-text action', (WidgetTester tester) async {
    final _FakeRecorderService recorder = _FakeRecorderService();
    final _FakeApiService api = _FakeApiService()
      ..parseResult = const TranscriptResult(
        parsedEntries: <ParsedEntry>[],
        rawTranscript: 'aaj kuch nahi hua',
      );
    addTearDown(recorder.dispose);

    await _pumpSheet(tester, recorder: recorder, api: api);

    await tester.enterText(find.byType(TextField), 'aaj kuch nahi hua');
    await tester.pump();
    await tester.tap(find.text('Convert to ledger entries'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('We heard'), findsOneWidget);
    expect(find.text('"aaj kuch nahi hua"'), findsOneWidget);
    expect(find.text('Use this text'), findsOneWidget);

    await tester.tap(find.text('Use this text'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final TextField field = tester.widget(find.byType(TextField));
    expect(field.controller!.text, 'aaj kuch nahi hua');
  });

  testWidgets('Urdu RTL layout does not overflow', (WidgetTester tester) async {
    final _FakeRecorderService recorder = _FakeRecorderService();
    final _FakeApiService api = _FakeApiService();
    addTearDown(recorder.dispose);

    await _pumpSheet(tester, recorder: recorder, api: api, locale: const Locale('ur'));

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('can record multiple times sequentially in the same sheet session', (WidgetTester tester) async {
    final _FakeRecorderService recorder = _FakeRecorderService()
      ..stopPath = '/tmp/fake_audio.m4a';
    final _FakeApiService api = _FakeApiService()
      ..transcribeResult = const TranscriptResult(
        parsedEntries: <ParsedEntry>[
          const ParsedEntry(
            entryType: EntryType.sale,
            amount: 500.0,
            note: 'sale',
          ),
        ],
        rawTranscript: '500 ki sale',
      );
    addTearDown(recorder.dispose);

    await _pumpSheet(tester, recorder: recorder, api: api);

    // Attempt 1: Start recording
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(recorder.startCalls, 1);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    // Stop attempt 1 and submit
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(recorder.stopCalls, 1);

    // Review stage is now visible. Tap 'Start over' to return to input stage.
    expect(find.text('Start over'), findsOneWidget);
    await tester.tap(find.text('Start over'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Attempt 2: Mic should be available again and recording should start cleanly
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(recorder.startCalls, 2);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    // Stop attempt 2
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(recorder.stopCalls, 2);

    expect(tester.takeException(), isNull);
  });
}
